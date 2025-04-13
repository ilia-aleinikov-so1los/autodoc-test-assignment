//
//  NetworkServiceProtocol.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

import UIKit

protocol NetworkServiceProtocol {
    func fetchNews(page: Int, limit: Int) async throws -> NewsResponse
    func fetchImage(from urlString: String) async throws -> UIImage
}
