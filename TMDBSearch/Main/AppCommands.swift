//
//  AppCommands.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/26.
//

import SwiftUI

struct AppCommands: Commands {
    var appModel: AppModel

    var body: some Commands {
        CommandGroup(after: .pasteboard) {
            Divider()

            Button(Constants.App.Menu.clearSearch) {
                clearSearch()
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(appModel.searchText.isEmpty)

            Button(Constants.App.Menu.showSearchHistory) {
                appModel.showHistory.toggle()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            .disabled(appModel.settingsManager.searchHistory.isEmpty)
        }

        CommandGroup(replacing: .help) {
            Button(Constants.App.Menu.help) {
                appModel.showHelp = true
            }
            .keyboardShortcut("?", modifiers: [.command])
        }
    }

    private func clearSearch() {
        appModel.searchText = ""
        appModel.searchResults = []
        appModel.errorMessage = nil
        appModel.updateAppTitle()
    }
}
