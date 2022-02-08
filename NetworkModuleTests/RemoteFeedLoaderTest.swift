//
//  RemoteFeedLoadterTest.swift
//  NetworkModuleTests
//
//  Created by klioop on 2022/02/08.
//

import Foundation
import XCTest
import NetworkModule

// url is the detail of the implementation of RemoteFeedLoader. It should not be in the public interface


class RemoteFeedLoaderTest: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_sut_load_requestsDataFromURL() {
        let url = URL(string: "https://thisisurl")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
 
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_twice_requestsDataFromURLTwice() {
        let url = URL(string: "https://thisisurl")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
 
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithError: .conectivity, when: {
            let clientError = NSError(domain: "Test", code: 0)
            // completion happens after the load was invoked - important!
            client.complete(with: clientError) // 2 load 의 completion 을 실행
        })
    }
    
    func test_load_deliversErrorOnNon200HttpResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { (index, code) in
            expect(sut, toCompleteWithError: .invalidData, when: {
                client.complete(withStatusCode: 400, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HttpResponseWithInvalidJson() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithError: .invalidData, when: {
            let jsonData = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: jsonData)
        })
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) }
        
        let emptyJSON = Data("{\"items\": []}".utf8)
        client.complete(withStatusCode: 200, data: emptyJSON)
        
        XCTAssertEqual(capturedResults, [.success([])])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        sut.load { capturedResults.append($0) } // 1
        
        action()
        
        XCTAssertEqual(capturedResults, [.failure(error)], file: file, line: line)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
         }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success(data, response))
        }
    }
}
