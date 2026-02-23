//
//  AppModel.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI
import SFSymbol

// MARK: - App Model (Observable)
@Observable
final class AppModel {
    // MARK: - State Properties
    var errorMessage: String?
    var statusMessage: String?
    var isLoading: Bool = false
    var searchResults: [TMDBMediaItem] = []
    var searchText: String = ""
    var selectedLanguages: [String] = Constants.Services.TMDB.languages
    var selectedMediaType: MediaType = Constants.App.defaultMediaType
    var showHelp = false
    var showHistory = false
    
    // MARK: - Plex Asset Selection
    var showPlexAssetSelection = false
    var plexPendingTasks: [AssetUploadTask] = []
    var plexAssetSelections: [UUID: Bool] = [:]
    var plexSelectionItem: TMDBMediaItem?
    var plexSelectionType: MediaType = .movie
    var plexSelectionSectionId: String = ""
    var plexSelectionRatingKey: String = ""
    
    // MARK: - Plex Upload Progress
    var showPlexUploadProgress = false
    var plexUploadTasks: [AssetUploadTask] = []
    var plexCurrentTaskIndex = 0
    var plexUploadCancelled = false
    var plexUploadTask: Task<Void, Never>?
    var plexUploadTaskID: UUID?
    
    // MARK: - Managers and Services
    let tmdbService = TMDBServices()
    let plexService = PlexServices()
    private(set) var settingsManager = SettingsManager()
    let fileManager: UnifiedFileManager
    
    init(fileManager: UnifiedFileManager = AppDelegate.shared.fileManager) {
        self.fileManager = fileManager
    }
    
    // MARK: - Plex Library Fetching
    @MainActor
    func fetchPlexLibraries() async throws -> [PlexLibrary] {
        guard !settingsManager.plexServer.isEmpty else {
            throw URLError(.badURL)
        }
        
        guard !settingsManager.plexToken.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        
        return try await plexService.fetchLibraries(
            server: settingsManager.plexServer,
            token: settingsManager.plexToken
        )
    }
}
