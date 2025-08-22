//
//  TMDB_SearchApp.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.

import SwiftUI

@main
struct TMDB_SearchApp: App {
    @State private var appModel = AppModel()
    @State private var showHelp = false
    
    var body: some Scene {
        WindowGroup {
            Search(showHelp: $showHelp)
                .environment(appModel)
        }
        .commands {
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
}
