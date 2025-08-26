//
//  SettingsScene.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/26.
//

import SwiftUI

struct SettingsScene: Scene {
    let appModel: AppModel
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            Configure()
                .environment(appModel)
                .environment(appDelegate.fileManager)
        }
    }
}
