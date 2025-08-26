//
//  SearchHistory.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/25.
//

import Foundation

// MARK: - Search History Item
struct SearchHistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let searchText: String
    let mediaType: MediaType
    let timestamp: Date

    init(searchText: String, mediaType: MediaType) {
        self.id = UUID()
        self.searchText = searchText
        self.mediaType = mediaType
        self.timestamp = Date()
    }
}
