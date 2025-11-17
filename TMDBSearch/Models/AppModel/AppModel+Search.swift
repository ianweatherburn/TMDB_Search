//
//  AppModel+Search.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/11/17.
//
import Foundation
import AppKit

// MARK: - Search Functionality
extension AppModel {
    @MainActor
    func performSearch() async {
        // Validation checks
        guard !settingsManager.apiKey.isEmpty,
              !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = settingsManager.apiKey.isEmpty ?
                "Please set your TMDB API key in Settings" : "Please enter a search term"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            updateAppTitle(with: searchText, showing: selectedMediaType.displayInfo.title)

            let results = try await tmdbService.searchMedia(
                query: searchText,
                mediaType: selectedMediaType,
                apiKey: settingsManager.apiKey
            )
            searchResults = results

            // Add to search history on successful search
            addToSearchHistory(searchText: searchText, mediaType: selectedMediaType)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            searchResults = []
        }

        isLoading = false
    }
    
    /// Clears the current search term, results, and error message.
    func clearSearch() {
        searchText = ""
        searchResults = []
        errorMessage = nil
        updateAppTitle()
    }
    
    /// Updates the main application window title.
    func updateAppTitle(with searchText: String = "", showing type: String = "") {
        if let window = NSApplication.shared.windows.first {
            let windowTitle = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Constants.App.name
            if searchText.isEmpty {
                window.title = windowTitle
            } else {
                window.title = "\(windowTitle) - '\(searchText.capitalized) (\(type))'"
            }
        }
    }

}
