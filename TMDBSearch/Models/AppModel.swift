//
//  AppModel.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI
import SFSymbol

// MARK: - Models and Data Structures

// MARK: - App Model (Observable)
@Observable
final class AppModel {
    var searchResults: [TMDBMediaItem] = []
    var isLoading: Bool = false
    var searchText: String = ""
    var selectedMediaType: MediaType = Constants.App.defaultMediaType
    var selectedLanguages: [String] = Constants.Services.TMDB.languages
    var errorMessage: String?
    var showHistory = false
    var showHelp = false
    
    // Settings management through SettingsManager
    private(set) var settingsManager = SettingsManager()

    private let tmdbService = TMDBServices()

    // MARK: - Settings Management
    func saveSettings() {
        settingsManager.saveSettings()
    }

    // MARK: - Search History Management
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

    // MARK: - Search functionality
    @MainActor
    func performSearch() async {
        guard !settingsManager.apiKey.isEmpty,
               !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = 
                settingsManager.apiKey.isEmpty ?
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

    // MARK: - Image loading and downloading
    @MainActor
    func loadImage(for item: TMDBMediaItem, as type: ImageType) async -> NSImage? {
        let path: String?

        switch type {
        case .poster:
            path = item.posterPath
        case .backdrop:
            path = item.backdropPath
        }

        guard let path else { return nil }
        guard let data = await tmdbService.loadImage(path: path, size: .w342) else { return nil }
        return NSImage(data: data)
    }

    func loadImages(for itemId: Int, mediaType: MediaType) async -> TMDBImagesResponse? {
        do {
            return try await tmdbService.getImages(
                itemId: itemId,
                mediaType: mediaType,
                languages: selectedLanguages,
                apiKey: settingsManager.apiKey)
        } catch {
            print("Failed to load images: \(error)")
            return nil
        }
    }

    func downloadImage(sourcePath: String, destPath: String, filename: String, flip: Bool = false) async -> Bool {
        var path = ""

        // Append the Plex-style foldername to the destination path
        path = URL(fileURLWithPath: settingsManager.downloadPath).appendingPathComponent(destPath).path
        guard await tmdbService.downloadImage(path: sourcePath, to: path, filename: filename, flip: flip)
            else { return false }

        return true
    }

    func updateAppTitle(with searchText: String = "", showing type: String = "") {
        if let window = NSApplication.shared.windows.first {
            let windowTitle = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "TMDB Search"
            if searchText.isEmpty {
                window.title = windowTitle
            } else {
                window.title = "\(windowTitle) - '\(searchText.capitalized) (\(type))'"
            }
        }
    }

    func copyToClipboard(_ item: TMDBMediaItem, idOnly: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // Check for option key (⌥) modifier
        if idOnly {
            // Copy TMDB ID only
            pasteboard.setString(String(item.id), forType: .string)
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.idCopy))?.play()
        } else {
            // Copy Plex formatted name with title and tmdb-id
            pasteboard.setString("\(item.plexTitle.replacingColonsWithDashes)", forType: .string)
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.nameCopy))?.play()
        }
    }
    
    func clearSearchFromMenu() {
        searchText = ""
        searchResults = []
        errorMessage = nil
        updateAppTitle()
    }
}
