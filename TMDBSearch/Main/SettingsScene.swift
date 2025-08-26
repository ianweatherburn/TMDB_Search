//
//  SettingsScene.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/26.
//

import SwiftUI

struct SettingsScene: Scene {
    let appModel: AppModel

    var body: some Scene {
        Settings {
            Configure()
                .environment(appModel)
        }
    }
}
