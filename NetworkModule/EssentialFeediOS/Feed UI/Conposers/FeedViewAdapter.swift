//
//  FeedViewAdapter.swift
//  EssentialFeediOS
//
//  Created by klioop on 2022/03/23.
//

import UIKit

// [FeedImage] -> Adapt -> [FeedImageCellController]
final class FeedViewAdapter: FeedView {
    private weak var controller: FeedViewController?
    private let imageLoader: FeedImageDataLoader
    
    init(controller: FeedViewController, imageLoader: FeedImageDataLoader) {
        self.controller = controller
        self.imageLoader = imageLoader
    }
    
    func display(_ viewModel: FeedViewModel) {
        controller?.tableModel = viewModel.feed.map { model in
            let presentationAdapter = FeedImageLoaderPresentationAdapter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>(model: model, imageLoader: imageLoader)
            let view = FeedImageCellController(delegate: presentationAdapter)
            presentationAdapter.presenter = FeedImagePresenter(view: WeakRefVirtualProxy(view), imageTransformer: UIImage.init)
            return view
        }
    }
}
