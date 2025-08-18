//
//  TMDB_Model.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI

// MARK: - Models and Data Structures

// MARK: - App Model (Observable)
@Observable
final class AppModel {
    var appTitle: String = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "TMDB Search"
    var apiKey: String = ""
    var downloadPath: DownloadPath = DownloadPath(primary: "", backup: nil)
    var searchResults: [TMDBMediaItem] = []
    var isLoading: Bool = false
    var searchText: String = ""
    var selectedMediaType: MediaType = .tv
    var gridSize: GridSize = .medium
    var errorMessage: String?
    
    struct DownloadPath {
        var primary: String = ""
        var backup: String? = nil
    }
    
    private let tmdbService = TMDBService()
    
    init() {
        loadSettings()
    }
    
    // Settings management
    func loadSettings() {
        apiKey = UserDefaults.standard.string(forKey: "TMDBAPIKey") ?? ""
        downloadPath.primary = UserDefaults.standard.string(forKey: "DownloadPath") ?? NSHomeDirectory() + "/Downloads/TMDB"
        downloadPath.backup = UserDefaults.standard.string(forKey: "DownloadPathBackup")
        
        if let gridSizeRaw = UserDefaults.standard.string(forKey: "GridSize"), let gridSize = GridSize(rawValue: gridSizeRaw) {
            self.gridSize = gridSize
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(apiKey, forKey: "TMDBAPIKey")
        UserDefaults.standard.set(downloadPath.primary, forKey: "DownloadPath")
        UserDefaults.standard.set(downloadPath.backup, forKey: "DownloadPathBackup")
        UserDefaults.standard.set(gridSize.rawValue, forKey: "GridSize")
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
            let results = try await tmdbService.searchMedia(
                query: searchText,
                mediaType: selectedMediaType,
                apiKey: apiKey
            )
            searchResults = results
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            searchResults = []
        }
        
        isLoading = false
    }
    
    // Image loading and downloading
    @MainActor
    func loadPosterImage(for item: TMDBMediaItem) async -> NSImage? {
        guard let posterPath = item.posterPath else { return nil }
        guard let data = await tmdbService.loadImage(path: posterPath, size: .w342) else {return nil }
        return NSImage(data: data)
    }
    
    func loadImages(for itemId: Int, mediaType: MediaType) async -> TMDBImagesResponse? {
        do {
            return try await tmdbService.getImages(itemId: itemId, mediaType: mediaType, apiKey: apiKey)
        } catch {
            print("Failed to load images: \(error)")
            return nil
        }
    }
    
    func downloadImage(sourcePath: String, destPath: String, filename: String, flip: Bool = false) async -> Bool {
        var path = ""
        
        // Append the Plex-style foldername to the destination path
        path = URL(fileURLWithPath: downloadPath.primary).appendingPathComponent(destPath).path
        guard await tmdbService.downloadImage(path: sourcePath, to: path, filename: filename, flip: flip) else { return false }
        
        // Check if there is a backup download required
        guard let backupPath = downloadPath.backup, !backupPath.isEmpty else { return true }
        path = URL(fileURLWithPath: backupPath).appendingPathComponent(destPath).path
        guard await tmdbService.downloadImage(path: sourcePath, to: path, filename: filename, flip: flip) else { return false }
//        guard await tmdbService.downloadImageWithShellHelper(path: sourcePath, to: path, filename: filename, flip: flip) else { return false }

        return true
    }
}

enum MediaType: String, CaseIterable {
    case tv = "tv"
    case movie = "movie"
    case collection = "collection"
    
    var displayInfo: (icon: String, title: String, default: Bool) {
        switch self {
        case .tv: return ("photo.tv", "Shows", true)
        case .movie: return ("movieclapper", "Movies", false)
        case .collection: return ("film.stack", "Collections", false)
        }
    }
}

// MARK: - Grid Size Enum
enum GridSize: String, CaseIterable, Identifiable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case huge = "huge"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        case .large:
            return "Large"
        case .huge:
            return "Huge"
        }
    }
    
    var helpText: String {
        switch self {
        case .small:
            return "Show more items in a smaller grid layout"
        case .medium:
            return "Show items in a medium-sized grid layout"
        case .large:
            return "Show fewer items in a larger grid layout"
        case .huge:
            return "Show items in the largest grid layou"
        }
    }
    
    var keyboardShortcut: String {
        switch self {
        case .small:
            return "1"
        case .medium:
            return "2"
        case .large:
            return "3"
        case .huge:
            return "4"
        }
    }
    
    func columnCount(for imageType: ImageType) -> Int {
        switch self {
        case .small:
            return imageType == .poster ? 6 : 4
        case .medium:
            return imageType == .poster ? 5 : 3
        case .large:
            return imageType == .poster ? 4 : 2
        case .huge:
            return imageType == .poster ? 3 : 1
        }
    }
}
