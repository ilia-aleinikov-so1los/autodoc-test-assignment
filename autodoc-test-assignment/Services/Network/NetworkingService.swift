//
//  NetworkingService.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

import UIKit

extension NetworkService {
    enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case requestFailed(Error)
        case decodingFailed(Error)
        case canceled
    }
}

final class NetworkService: NetworkServiceProtocol {
    func fetchNews(page: Int, limit: Int) async throws -> NewsResponse {
        guard let url = URL(string: "https://webapi.autodoc.ru/api/news/\(page)/\(limit)") else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(NewsResponse.self, from: data)
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingFailed(decodingError)
        } catch let error {
            throw NetworkError.requestFailed(error)
        }
    }
    
    func fetchImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data) else {
                throw NetworkError.invalidResponse
            }
            
            return image
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                throw NetworkError.canceled
            }
            throw NetworkError.requestFailed(error)
        }
    }
}
