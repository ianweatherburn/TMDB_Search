//
//  TMDB_SearchApp.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.

import SwiftUI

@main
struct TMDBSearchApp: App {
    @State private var appModel = AppModel()
    @State private var showHelp = false
    
    var body: some Scene {
        WindowGroup {
            Search(showHelp: $showHelp)
                .environment(appModel)
        }
        .commands {
            // Add to Edit menu
            CommandGroup(after: .pasteboard) {
                Divider()
                
                Button("Clear Search") {
                    clearSearch()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(appModel.searchText.isEmpty)
                
                Button("Show Search History") {
                    appModel.showHistoryFromMenu = true
                    NotificationCenter.default.post(name: .showSearchHistory, object: nil)
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                .disabled(appModel.settingsManager.searchHistory.isEmpty)
            }
            CommandGroup(replacing: .help) {
                Button("TMDB Search Help") {
                    showHelp = true
                }
                .keyboardShortcut("?", modifiers: [.command])
            }
        }
        
        Settings {
            Configure()
                .environment(appModel)
        }
    }
    
    // MARK: - Menu Actions
    private func clearSearch() {
        appModel.searchText = ""
        appModel.searchResults = []
        appModel.errorMessage = nil
        appModel.updateAppTitle()
    }
    
    private func showSearchHistory() {
        // You'll need to communicate this to your SearchHeader
        // This could be done through the AppModel or NotificationCenter
        NotificationCenter.default.post(name: .showSearchHistory, object: nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let showSearchHistory = Notification.Name("showSearchHistory")
}
