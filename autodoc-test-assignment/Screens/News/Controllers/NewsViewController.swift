//
//  NewsViewController.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

import UIKit
import Combine

private extension NewsViewController {
    enum Section {
        case main
    }
}

final class NewsViewController: UIViewController {
    private let container: DependencyContainer
    private let viewModel: NewsViewModel
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, NewsItem>!
    private var cancellables = Set<AnyCancellable>()
    
    init(container: DependencyContainer = DependencyContainer()) {
        self.container = container
        self.viewModel = NewsViewModel(networkService: container.networkService)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupUI()
        setupDataSource()
        setupBindings()
        
        Task {
            await viewModel.loadInitialData()
        }
    }
    
    private func setupUI() {
        title = "Autodoc News"
        view.backgroundColor = .systemBackground
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    @objc private func refreshData() {
        Task {
            await viewModel.loadInitialData()
            DispatchQueue.main.async {
                self.collectionView.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        
        collectionView.register(NewsCell.self, forCellWithReuseIdentifier: NewsCell.reuseIdentifier)
        collectionView.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.reuseIdentifier
        )
        
        view.addSubview(collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad layout (2 columns)
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .estimated(300)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(300)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            
            // Footer with loading indicator
            let footerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(50)
            )
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )
            section.boundarySupplementaryItems = [footer]
            
            return UICollectionViewCompositionalLayout(section: section)
        } else {
            // iPhone layout (1 column)
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(300)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(300)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            
            // Footer with loading indicator
            let footerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(50)
            )
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: footerSize,
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )
            section.boundarySupplementaryItems = [footer]
            
            return UICollectionViewCompositionalLayout(section: section)
        }
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, NewsItem>(
            collectionView: collectionView
        ) { collectionView, indexPath, newsItem in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NewsCell.reuseIdentifier,
                for: indexPath
            ) as? NewsCell else {
                return UICollectionViewCell()
            }
            
            cell.inject(networkService: self.container.networkService,
                        imageCache: self.container.imageCache)
            
            cell.configure(with: newsItem)
            
            if self.viewModel.shouldLoadMoreData(currentItem: newsItem) {
                Task {
                    await self.viewModel.loadMoreData()
                }
            }
            
            return cell
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            if kind == UICollectionView.elementKindSectionFooter {
                guard let footerView = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: LoadingFooterView.reuseIdentifier,
                    for: indexPath
                ) as? LoadingFooterView else {
                    return UICollectionReusableView()
                }
                
                if self?.viewModel.isLoading == true {
                    footerView.startLoading()
                } else {
                    footerView.stopLoading()
                }
                
                return footerView
            }
            
            return UICollectionReusableView()
        }
    }
    
    private func setupBindings() {
        viewModel.$newsItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newsItems in
                self?.updateUI(with: newsItems)
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                let snapshot = self.dataSource.snapshot()
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &cancellables)
    }
    
    private func updateUI(with newsItems: [NewsItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, NewsItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(newsItems)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegate
extension NewsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let newsItem = dataSource.itemIdentifier(for: indexPath) else { return }
        
        let detailVC = NewsDetailViewController(
            newsItem: newsItem,
            networkService: container.networkService,
            imageCache: container.imageCache
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
