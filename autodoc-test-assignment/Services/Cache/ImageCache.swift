//
//  ImageCache.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

import UIKit

final class ImageCache: ImageCacheProtocol {
    private let cache = NSCache<NSString, UIImage>()
    
    init() {
        cache.countLimit = 100
    }
    
    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func save(image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
