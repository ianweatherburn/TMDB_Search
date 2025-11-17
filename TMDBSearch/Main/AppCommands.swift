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
        searchCommands // App-Specific Commands (Search and History)
        helpCommands // Help Commands (Replacing the default help menu)
    }

    // MARK: - Command Builder Methods
    @CommandsBuilder
    private var searchCommands: some Commands {
        CommandGroup(after: .pasteboard) {
            Divider()

            Button(Constants.App.Menu.clearSearch) {
                appModel.clearSearch()
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(appModel.searchText.isEmpty)

            Button(Constants.App.Menu.showSearchHistory) {
                appModel.showHistory.toggle()
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])
            .disabled(appModel.settingsManager.searchHistory.isEmpty)
        }
    }

    @CommandsBuilder
    private var helpCommands: some Commands {
        CommandGroup(replacing: .help) {
            Button(Constants.App.Menu.help) {
                appModel.showHelp = true
            }
            .keyboardShortcut("/", modifiers: [.command])
        }
    }
}
