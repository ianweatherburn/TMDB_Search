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
    var isLoading: Bool = false
    var searchResults: [TMDBMediaItem] = []
    var searchText: String = ""
    var selectedLanguages: [String] = Constants.Services.TMDB.languages
    var selectedMediaType: MediaType = Constants.App.defaultMediaType
    var showHelp = false
    var showHistory = false
    
    // MARK: - Managers and Services
    let tmdbService = TMDBServices()
    private(set) var settingsManager = SettingsManager()
}
