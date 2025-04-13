//
//  NewsViewModel.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

import UIKit

final class NewsViewModel {
    // Dependencies
    private let networkService: NetworkServiceProtocol
    
    // Published properties for UI binding
    @Published var newsItems = [NewsItem]()
    @Published var isLoading = false
    @Published var error: Error?
    @Published var hasMoreData = true
    
    // Pagination parameters
    private let pageSize = 10
    private var currentPage = 1
    private var totalItems = 0
    
    // Initialization
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // Fetch the initial page
    func loadInitialData() async {
        currentPage = 1
        await loadMoreData()
    }
    
    // Load more data for pagination
    func loadMoreData() async {
        guard !isLoading, hasMoreData else { return }
        
        do {
            await MainActor.run { self.isLoading = true }
            
            let response = try await networkService.fetchNews(page: currentPage, limit: pageSize)
            
            await MainActor.run {
                if self.currentPage == 1 {
                    self.newsItems = response.news
                } else {
                    self.newsItems.append(contentsOf: response.news)
                }
                
                self.totalItems = response.totalCount
                self.hasMoreData = self.newsItems.count < self.totalItems
                self.currentPage += 1
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    // Check if we need to load more data when scrolling
    func shouldLoadMoreData(currentItem: NewsItem) -> Bool {
        guard let lastItem = newsItems.last, hasMoreData else { return false }
        return currentItem.id == lastItem.id
    }
}
