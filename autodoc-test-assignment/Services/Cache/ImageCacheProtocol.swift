//
//  ImageCacheProtocol.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

import UIKit

protocol ImageCacheProtocol {
    func image(for key: String) -> UIImage?
    func save(image: UIImage, for key: String)
}
