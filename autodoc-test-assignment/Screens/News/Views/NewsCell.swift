//
//  NewsCell.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

import UIKit

final class NewsCell: UICollectionViewCell {
    static let reuseIdentifier = "NewsCell"
    
    // Dependencies
    private var networkService: NetworkServiceProtocol?
    private var imageCache: ImageCacheProtocol?
    
    // Image view correct loading
    private var imageHeightConstraint: NSLayoutConstraint!
    private var imageLoadingTask: Task<Void, Never>?
    
    // UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let newsImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageLoadingTask?.cancel()
        newsImageView.image = nil
        titleLabel.text = nil
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(newsImageView)
        contentView.addSubview(titleLabel)
        newsImageView.addSubview(loadingIndicator)
        
        let imageHeight: CGFloat = 200
        imageHeightConstraint = newsImageView.heightAnchor.constraint(equalToConstant: imageHeight)
        
        NSLayoutConstraint.activate([
            newsImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            newsImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            newsImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageHeightConstraint,
            
            titleLabel.topAnchor.constraint(equalTo: newsImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: newsImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: newsImageView.centerYAnchor)
        ])
    }
    
    func inject(networkService: NetworkServiceProtocol, imageCache: ImageCacheProtocol) {
        self.networkService = networkService
        self.imageCache = imageCache
    }
    
    func configure(with newsItem: NewsItem) {
        titleLabel.text = newsItem.title
        
        guard let networkService, let imageCache else {
            print("Error: Dependencies not injected into NewsCell")
            return
        }
        
        loadingIndicator.startAnimating()
        
        if let cachedImage = imageCache.image(for: newsItem.titleImageUrl) {
            self.newsImageView.image = cachedImage
            self.loadingIndicator.stopAnimating()
            return
        }
        
        imageLoadingTask?.cancel()
        
        imageLoadingTask = Task {
            do {
                let image = try await networkService.fetchImage(from: newsItem.titleImageUrl)
                
                if !Task.isCancelled {
                    imageCache.save(image: image, for: newsItem.titleImageUrl)
                    
                    await MainActor.run {
                        UIView.transition(with: self.newsImageView,
                                          duration: 0.3,
                                          options: .transitionCrossDissolve) {
                            self.newsImageView.image = image
                        }
                        self.loadingIndicator.stopAnimating()
                    }
                }
            } catch let error as NetworkService.NetworkError {
                if case .canceled = error {
                    
                }
            } catch {
                if !Task.isCancelled {
                    print("Failed to load image: \(error)")
                    await MainActor.run {
                        self.loadingIndicator.stopAnimating()
                    }
                }
            }
        }
    }
}
