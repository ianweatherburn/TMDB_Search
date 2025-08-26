//
//  TMDB_SearchApp.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.

import SwiftUI

@main
struct TMDBSearchApp: App {
    @State private var appModel = AppModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Main Window
        MainWindowScene(appModel: appModel)

        // Settings
        SettingsScene(appModel: appModel)
            .environmentObject(appDelegate.fileManager)
    }
}
