//
//  ListViewController.swift
//  EssentialFeediOS
//
//  Created by klioop on 2022/03/12.
//

import UIKit
import NetworkModule

public final class ListViewController: UITableViewController, UITableViewDataSourcePrefetching {
    @IBOutlet public var refreshController: FeedRefreshViewController?
    private(set) public var errorView = ErrorView()
    
    private enum Section: Int {
        case main
    }
    
    private lazy var dataSource: UITableViewDiffableDataSource<Section, CellController> = {
        .init(tableView: tableView) { tableView, index, controller in
            controller.dataSource.tableView(tableView, cellForRowAt: index)
        }
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource.defaultRowAnimation = .fade
        tableView.dataSource = dataSource
        configureErrorView()
        refreshController?.refresh()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeTableHeaderToFit()
    }
    
    public override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        if previous?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            tableView.reloadData()
        }
    }
    
    private func configureErrorView() {
        tableView.tableHeaderView = errorView
        
        errorView.onHide = { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.sizeTableHeaderToFit()
            self?.tableView.endUpdates()
        }
    }
    
    public func display(_ controllers: [CellController]) {
        var snapShot = NSDiffableDataSourceSnapshot<Section, CellController>()
        snapShot.appendSections([.main])
        snapShot.appendItems(controllers, toSection: .main)
        dataSource.apply(snapShot)
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dl = cellController(at: indexPath)?.delegate
        dl?.tableView?(tableView, didSelectRowAt: indexPath)
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let dl = cellController(at: indexPath)?.delegate
        dl?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let dsp = cellController(at: indexPath)?.dataSourcePrefetching
            dsp?.tableView(tableView, prefetchRowsAt: [indexPath])
        }
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let dsp = cellController(at: indexPath)?.dataSourcePrefetching
            dsp?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
        }
    }
    
    private func cellController(at indexPath: IndexPath) -> CellController? {
        dataSource.itemIdentifier(for: indexPath)
    }
}

extension ListViewController: ResourceErrorView {
    public func display(_ viewModel: ResourceErrorViewModel) {
        errorView.message = viewModel.message
    }
}
