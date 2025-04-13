//
//  DependencyContainer.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

final class DependencyContainer {
    let networkService: NetworkServiceProtocol
    let imageCache: ImageCacheProtocol
    
    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        imageCache: ImageCacheProtocol = ImageCache()
    ) {
        self.networkService = networkService
        self.imageCache = imageCache
    }
}
