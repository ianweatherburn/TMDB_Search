//
//  MainWindowScene.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/26.
//
//

import SwiftUI

struct MainWindowScene: Scene {
    let appModel: AppModel

    var body: some Scene {
        Window(Constants.App.name, id: Constants.App.name) {
            Search()
                .environment(appModel)
        }
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .defaultSize(
            width: Constants.App.Window.Main.width,
            height: Constants.App.Window.Main.height
        )
        .commands {
            AppCommands(appModel: appModel)
        }
    }
}
