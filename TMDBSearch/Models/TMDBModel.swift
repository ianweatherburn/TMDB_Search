//
//  TMDB_Model.swift
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
    var apiKey: String = ""
    var downloadPath: DownloadPath = DownloadPath(primary: "", backup: nil)
    var searchResults: [TMDBMediaItem] = []
    var isLoading: Bool = false
    var searchText: String = ""
    var selectedMediaType: MediaType = .tv
    var selectedLanguages: [String] = Constants.Services.TMDB.languages
    var gridSize: GridSize = Constants.Configure.Preferences.gridSize
    var errorMessage: String?
    var searchHistory: [SearchHistoryItem] = []
    var maxHistoryItems: Int = Constants.Configure.Preferences.History.size
    var showHistoryFromMenu = false
    
    struct DownloadPath {
        var primary: String = ""
        var backup: String?
    }

    private let tmdbService = TMDBService()

    init() {
        loadSettings()
    }

    // Settings management
    func loadSettings() {
        apiKey = UserDefaults.standard.string(forKey: "TMDBAPIKey") ?? ""
        downloadPath.primary = UserDefaults.standard.string(forKey: "DownloadPath") ?? NSHomeDirectory() +
                               "/Downloads/TMDB"
        downloadPath.backup = UserDefaults.standard.string(forKey: "DownloadPathBackup")

        if let gridSizeRaw = UserDefaults.standard.string(forKey: "GridSize"),
           let gridSize = GridSize(rawValue: gridSizeRaw) {
            self.gridSize = gridSize
        }

        maxHistoryItems = UserDefaults.standard.integer(forKey: "MaxHistoryItems")
        if maxHistoryItems == 0 { maxHistoryItems = 20 } // Default value
        loadSearchHistory()
    }

    func saveSettings() {
        UserDefaults.standard.set(apiKey, forKey: "TMDBAPIKey")
        UserDefaults.standard.set(downloadPath.primary, forKey: "DownloadPath")
        UserDefaults.standard.set(downloadPath.backup, forKey: "DownloadPathBackup")
        UserDefaults.standard.set(gridSize.rawValue, forKey: "GridSize")
        UserDefaults.standard.set(maxHistoryItems, forKey: "MaxHistoryItems")
        saveSearchHistory()
    }

    // Search history management
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "SearchHistory"),
           let history = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) {
            searchHistory = history
        }
    }

    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: "SearchHistory")
        }
    }

    func addToSearchHistory(searchText: String, mediaType: MediaType) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Remove any existing entry with the same search text and media type
        searchHistory.removeAll { $0.searchText.lowercased() == trimmedText.lowercased() && $0.mediaType == mediaType }

        // Add new item to the beginning
        let newItem = SearchHistoryItem(searchText: trimmedText, mediaType: mediaType)
        searchHistory.insert(newItem, at: 0)

        // Maintain maximum history size
        if searchHistory.count > maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(maxHistoryItems))
        }

        saveSearchHistory()
    }

    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }

    func removeFromHistory(_ item: SearchHistoryItem) {
        searchHistory.removeAll { $0.id == item.id }
        saveSearchHistory()
    }

    func selectHistoryItem(_ item: SearchHistoryItem) {
        searchText = item.searchText
        selectedMediaType = item.mediaType
    }

    // Search functionality
    @MainActor
    func performSearch() async {
        guard !apiKey.isEmpty, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = apiKey.isEmpty ? "Please set your TMDB API key in Settings" : "Please enter a search term"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            updateAppTitle(with: searchText, showing: selectedMediaType.displayInfo.title)

            let results = try await tmdbService.searchMedia(
                query: searchText,
                mediaType: selectedMediaType,
                apiKey: apiKey
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

    // Image loading and downloading
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
                apiKey: apiKey)
        } catch {
            print("Failed to load images: \(error)")
            return nil
        }
    }

    func downloadImage(sourcePath: String, destPath: String, filename: String, flip: Bool = false) async -> Bool {
        var path = ""

        // Append the Plex-style foldername to the destination path
        path = URL(fileURLWithPath: downloadPath.primary).appendingPathComponent(destPath).path
        guard await tmdbService.downloadImage(path: sourcePath, to: path, filename: filename, flip: flip)
            else { return false }

        // Check if there is a backup download required
        guard let backupPath = downloadPath.backup, !backupPath.isEmpty else { return true }
        path = URL(fileURLWithPath: backupPath).appendingPathComponent(destPath).path
        guard await tmdbService.downloadImage(
            path: sourcePath,
            to: path,
            filename: filename,
            flip: flip) else { return false }
//        guard await tmdbService.downloadImageWithShellHelper(
//            path: sourcePath,
//            to: path,
//            filename: filename,
//            flip: flip
//        ) else { return false }

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
    
    func toggleSearchHistoryFromMenu() {
        showHistoryFromMenu.toggle()
    }
}

/* // swiftlint:disable identifier_name */
enum MediaType: String, CaseIterable, Codable {
    case tv
    case movie
    case collection

    var displayInfo: (icon: String, title: String, default: Bool) {
        switch self {
        case .tv: return (SFSymbol6.Photo.photo.rawValue, "Shows", true)
        case .movie: return (SFSymbol6.Movieclapper.movieclapper.rawValue, "Movies", false)
        case .collection: return (SFSymbol6.Film.filmStack.rawValue, "Collections", false)
        }
    }

}
/* // swiftlint:enable identifier_name */

// MARK: - Grid Size Enum
enum GridSize: String, CaseIterable, Identifiable, Equatable {
    case tiny
    case small
    case medium
    case large

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiny:
            return "Tiny"
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        case .large:
            return "Large"
        }
    }

    var helpText: String {
        switch self {
        case .tiny:
            return "Show more items in a smaller grid layout"
        case .small:
            return "Show items in a medium-sized grid layout"
        case .medium:
            return "Show fewer items in a larger grid layout"
        case .large:
            return "Show items in the largest grid layou"
        }
    }

    var keyboardShortcut: String {
        switch self {
        case .tiny:
            return "1"
        case .small:
            return "2"
        case .medium:
            return "3"
        case .large:
            return "4"
        }
    }

    func columnCount(for imageType: ImageType) -> Int {
        switch imageType {
        case .poster:
            switch self {
            case .tiny:  return Constants.Image.Poster.Gallery.Count.small
            case .small: return Constants.Image.Poster.Gallery.Count.medium
            case .medium:  return Constants.Image.Poster.Gallery.Count.large
            case .large:   return Constants.Image.Poster.Gallery.Count.huge
            }
        case .backdrop:
            switch self {
            case .tiny:  return Constants.Image.Backdrop.Gallery.Count.small
            case .small: return Constants.Image.Backdrop.Gallery.Count.medium
            case .medium:  return Constants.Image.Backdrop.Gallery.Count.large
            case .large:   return Constants.Image.Backdrop.Gallery.Count.huge
            }
        }
    }

}

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
