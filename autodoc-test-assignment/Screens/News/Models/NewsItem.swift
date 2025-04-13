//
//  NewsItem.swift
//  autodoc-test-assignment
//
//  Created by evilGen on 12-04-2025.
//

struct NewsItem: Decodable, Hashable {
    let id: Int
    let title: String
    let description: String
    let publishedDate: String
    let url: String
    let fullUrl: String
    let titleImageUrl: String
}
