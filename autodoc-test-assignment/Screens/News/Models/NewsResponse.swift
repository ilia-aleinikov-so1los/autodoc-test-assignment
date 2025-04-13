//
//  NewsResponse.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

struct NewsResponse: Decodable {
    let news: [NewsItem]
    let totalCount: Int
}
