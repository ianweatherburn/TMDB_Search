//
//  AppModel+Settings.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/11/17.
//

import Foundation

// MARK: - Settings Management
extension AppModel {
    func saveSettings() {
        settingsManager.saveSettings()
    }

    // MARK: - Settings Search History Management
    func addToSearchHistory(searchText: String, mediaType: MediaType) {
        settingsManager.addToSearchHistory(searchText: searchText, mediaType: mediaType)
    }

    func clearSearchHistory() {
        settingsManager.clearSearchHistory()
    }

    func removeFromHistory(_ item: SearchHistoryItem) {
        settingsManager.removeFromHistory(item)
    }

    func selectHistoryItem(_ item: SearchHistoryItem) {
        searchText = item.searchText
        selectedMediaType = item.mediaType
    }
}
