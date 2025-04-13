//
//  NewsDetailViewController.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

import UIKit

final class NewsDetailViewController: UIViewController {
    private let newsItem: NewsItem
    private let networkService: NetworkServiceProtocol
    private let imageCache: ImageCacheProtocol
    private var imageTask: Task<Void, Never>?
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
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
    
    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    init(newsItem: NewsItem,
         networkService: NetworkServiceProtocol,
         imageCache: ImageCacheProtocol) {
        self.newsItem = newsItem
        self.networkService = networkService
        self.imageCache = imageCache
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithNewsItem()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageTask?.cancel()
    }
    
    private func setupUI() {
        title = "News Detail"
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(newsImageView)
        contentView.addSubview(descriptionTextView)
        
        let contentGuide = contentView.layoutMarginsGuide
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            
            newsImageView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            newsImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            newsImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            newsImageView.heightAnchor.constraint(equalTo: newsImageView.widthAnchor, multiplier: 0.6),
            
            descriptionTextView.topAnchor.constraint(equalTo: newsImageView.bottomAnchor, constant: 16),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            descriptionTextView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func configureWithNewsItem() {
        titleLabel.text = newsItem.title
        
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")

        if let date = isoFormatter.date(from: newsItem.publishedDate) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            dateLabel.text = formatter.string(from: date)
        } else {
            dateLabel.text = newsItem.publishedDate
        }
        
        descriptionTextView.text = newsItem.description
        
        if let cachedImage = imageCache.image(for: newsItem.titleImageUrl) {
            self.newsImageView.image = cachedImage
        } else {
            imageTask = Task {
                do {
                    let image = try await networkService.fetchImage(from: newsItem.titleImageUrl)
                    
                    if !Task.isCancelled {
                        imageCache.save(image: image, for: newsItem.titleImageUrl)
                        
                        await MainActor.run {
                            self.newsImageView.image = image
                        }
                    }
                } catch {
                    print("Failed to load detail image: \(error)")
                }
            }
        }
    }
}
