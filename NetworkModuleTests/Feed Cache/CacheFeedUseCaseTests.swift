//
//  LocalFeedLoaderTest.swift
//  NetworkModuleTests
//
//  Created by klioop on 2022/02/19.
//

import Foundation
import XCTest
import NetworkModule

class LocalFeedLoaderTest: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) =  makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) =  makeSUT()
        
        sut.save(uniqueImageFeed().models) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesNotRequestCahceInsertionOnDeletionError() {
        let (sut, store) =  makeSUT()
        let deletionError = anyNSError()
        
        sut.save(uniqueImageFeed().models) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCacheInsertionOnWithTimestampSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) =  makeSUT(currentDate: { timestamp })
        let feed = uniqueImageFeed()

        sut.save(feed.models) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(feed.local, timestamp)])
    }
    
    // test what does save do when deletion fails
    func test_save_failsOnDeletionError() {
        let (sut, store) =  makeSUT()
        let deletionError = anyNSError()
        
        expect(sut, toCompletedWith: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }
    
    func test_save_failsOnNewCacheInsertionError() {
        let (sut, store) =  makeSUT()
        let insertionError = anyNSError()
        
        expect(sut, toCompletedWith: insertionError, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        })
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) =  makeSUT()
        
        expect(sut, toCompletedWith: nil, when: {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        })
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = .init(store: store, currentDate: Date.init)
        
        var receivedResult = [LocalFeedLoader.SaveResult]()
        sut?.save([uniuqeImage()], completion: { receivedResult.append($0) })
        
        sut = nil
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResult.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = .init(store: store, currentDate: Date.init)
        
        var receivedResult = [LocalFeedLoader.SaveResult]()
        sut?.save([uniuqeImage()], completion: { receivedResult.append($0) })
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResult.isEmpty)
    }
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        trackMemoryLeak(store, file: file, line: line)
        
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompletedWith expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion")
        
        var receivedError: Error?
        sut.save(uniqueImageFeed().models) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, expectedError)
    }
    
    private func uniuqeImage() -> FeedImage {
        return FeedImage(id: .init(), description: "any", location: "any", url: anyURL())
    }
    
    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let models = [uniuqeImage(), uniuqeImage()]
        let localItems = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
        
        return (models, localItems)
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-given-url.com")!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
