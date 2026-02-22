////
////  Configure.swift
////  TMDB Search
////
////  Created by Ian Weatherburn on 2025/08/05.
////

import SwiftUI
import SFSymbol

struct Configure: View {
    @Environment(AppModel.self) private var appModel
    @Environment(UnifiedFileManager.self) var fileManager: UnifiedFileManager
    @State private var selectedTab: SettingsTab = .api
    @State private var tempApiKey = ""
    @State private var tempPlexServer = ""
    @State private var tempPlexToken = ""
    @State private var tempPlexServerAssetPath = ""
    @State private var tempDownloadPath = ""
    @State private var tempDefaultGridSize: GridSize = Constants.Configure.Preferences.gridSize
    @State private var tempHistorySize = Constants.Configure.Preferences.History.size
    @State private var tempshowTMDBID = false
    @State private var tempPlexDebugLogging = false
    
    // Plex Library Settings
    @State private var tempPlexShowsLibrary = ""
    @State private var tempPlexShowsLibraryId = ""
    @State private var tempPlexShows4KLibrary = ""
    @State private var tempPlexShows4KLibraryId = ""
    @State private var tempPlexMoviesLibrary = ""
    @State private var tempPlexMoviesLibraryId = ""
    @State private var tempPlexMovies4KLibrary = ""
    @State private var tempPlexMovies4KLibraryId = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("API", systemImage: SFSymbol6.Key.keyFill.rawValue, value: .api) {
                Form {
                    ConfigureAPI(
                        apiKey: $tempApiKey,
                        plexServer: $tempPlexServer,
                        plexToken: $tempPlexToken,
                        plexServerAssetPath: $tempPlexServerAssetPath
                    )
                    
                    makePlexLibraryView()
                }
                .formStyle(.grouped)
            }
            
            Tab("Preferences", systemImage: SFSymbol6.Gearshape.gearshapeFill.rawValue, value: .preferences) {
                Form {
                    ConfigurePreferences(
                        gridSize: $tempDefaultGridSize,
                        historySize: $tempHistorySize,
                        showTMDBID: $tempshowTMDBID,
                        plexDebugLogging: $tempPlexDebugLogging
                    )
                }
                .formStyle(.grouped)
            }
            
            Tab("Download", systemImage: SFSymbol6.Folder.folderFill.rawValue, value: .download) {
                Form {
                    ConfigureDownload(downloadPath: $tempDownloadPath)
                }
                .formStyle(.grouped)
            }
        }
        .tabViewStyle(.automatic)
        .formStyle(.grouped)
        .frame(width: 600, height: 500)
        .onAppear(perform: loadCurrentSettings)
        .onChange(of: tempApiKey, checkForChanges)
        .onChange(of: tempPlexServer, checkForChanges)
        .onChange(of: tempPlexToken, checkForChanges)
        .onChange(of: tempPlexServerAssetPath, checkForChanges)
        .onChange(of: tempDownloadPath, checkForChanges)
        .onChange(of: tempDefaultGridSize, checkForChanges)
        .onChange(of: tempHistorySize, checkForChanges)
        .onChange(of: tempshowTMDBID, checkForChanges)
        .onChange(of: tempPlexDebugLogging, checkForChanges)
        .onChange(of: tempPlexShowsLibrary, checkForChanges)
        .onChange(of: tempPlexShowsLibraryId, checkForChanges)
        .onChange(of: tempPlexShows4KLibrary, checkForChanges)
        .onChange(of: tempPlexShows4KLibraryId, checkForChanges)
        .onChange(of: tempPlexMoviesLibrary, checkForChanges)
        .onChange(of: tempPlexMoviesLibraryId, checkForChanges)
        .onChange(of: tempPlexMovies4KLibrary, checkForChanges)
        .onChange(of: tempPlexMovies4KLibraryId, checkForChanges)
    }
    
    // MARK: - View Components
    @ViewBuilder
    private func makePlexLibraryView() -> some View {
        ConfigurePlex(
            showsLibrary: $tempPlexShowsLibrary,
            showsLibraryId: $tempPlexShowsLibraryId,
            shows4KLibrary: $tempPlexShows4KLibrary,
            shows4KLibraryId: $tempPlexShows4KLibraryId,
            moviesLibrary: $tempPlexMoviesLibrary,
            moviesLibraryId: $tempPlexMoviesLibraryId,
            movies4KLibrary: $tempPlexMovies4KLibrary,
            movies4KLibraryId: $tempPlexMovies4KLibraryId
        )
    }

    // MARK: - Helper Methods
    private func loadCurrentSettings() {
        tempApiKey = appModel.settingsManager.apiKey
        tempPlexServer = appModel.settingsManager.plexServer
        tempPlexToken = appModel.settingsManager.plexToken
        tempPlexServerAssetPath = appModel.settingsManager.plexServerAssetPath
        tempDownloadPath = appModel.settingsManager.downloadPath
        tempDefaultGridSize = appModel.settingsManager.gridSize
        tempHistorySize = appModel.settingsManager.maxHistoryItems
        tempshowTMDBID = appModel.settingsManager.showTMDBID
        tempPlexDebugLogging = appModel.settingsManager.plexDebugLogging
        
        // Load Plex Library Settings
        tempPlexShowsLibrary = appModel.settingsManager.plexShowsLibrary
        tempPlexShowsLibraryId = appModel.settingsManager.plexShowsLibraryId
        tempPlexShows4KLibrary = appModel.settingsManager.plexShows4KLibrary
        tempPlexShows4KLibraryId = appModel.settingsManager.plexShows4KLibraryId
        tempPlexMoviesLibrary = appModel.settingsManager.plexMoviesLibrary
        tempPlexMoviesLibraryId = appModel.settingsManager.plexMoviesLibraryId
        tempPlexMovies4KLibrary = appModel.settingsManager.plexMovies4KLibrary
        tempPlexMovies4KLibraryId = appModel.settingsManager.plexMovies4KLibraryId
    }

    private func checkForChanges() {
        // Auto-save on change for macOS Settings pattern
        appModel.settingsManager.apiKey = tempApiKey
        appModel.settingsManager.plexServer = tempPlexServer
        appModel.settingsManager.plexToken = tempPlexToken
        appModel.settingsManager.plexServerAssetPath = tempPlexServerAssetPath
        appModel.settingsManager.downloadPath = tempDownloadPath
        appModel.settingsManager.gridSize = tempDefaultGridSize
        appModel.settingsManager.maxHistoryItems = tempHistorySize
        appModel.settingsManager.showTMDBID = tempshowTMDBID
        appModel.settingsManager.plexDebugLogging = tempPlexDebugLogging
        
        // Save Plex Library Settings
        appModel.settingsManager.plexShowsLibrary = tempPlexShowsLibrary
        appModel.settingsManager.plexShowsLibraryId = tempPlexShowsLibraryId
        appModel.settingsManager.plexShows4KLibrary = tempPlexShows4KLibrary
        appModel.settingsManager.plexShows4KLibraryId = tempPlexShows4KLibraryId
        appModel.settingsManager.plexMoviesLibrary = tempPlexMoviesLibrary
        appModel.settingsManager.plexMoviesLibraryId = tempPlexMoviesLibraryId
        appModel.settingsManager.plexMovies4KLibrary = tempPlexMovies4KLibrary
        appModel.settingsManager.plexMovies4KLibraryId = tempPlexMovies4KLibraryId
        
        appModel.saveSettings()
    }

    enum SettingsTab: Hashable {
        case api
        case preferences
        case download
    }
}

#Preview("Settings") {
    Configure()
        .environment(AppModel())
        .environment(AppDelegate.shared.fileManager)
}
