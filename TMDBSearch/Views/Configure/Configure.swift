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
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .api
    @State private var tempApiKey = ""
    @State private var tempDownloadPath = ""
    @State private var tempDefaultGridSize: GridSize = Constants.Configure.Preferences.gridSize
    @State private var tempHistorySize = Constants.Configure.Preferences.History.size

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ConfigureSidebar(selectedSection: $selectedSection)
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(width: 1)
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ConfigureSectionHeader(section: selectedSection)
                            Group {
                                switch selectedSection {
                                case .api:
                                    ConfigureAPI(apiKey: $tempApiKey)
                                case .preferences:
                                    ConfigurePreferences(
                                        gridSize: $tempDefaultGridSize,
                                        historySize: $tempHistorySize
                                    )
                                case .download:
                                    ConfigureDownload(downloadPath: $tempDownloadPath)
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 16)
                        }
                    }
                    .frame(maxHeight: geometry.size.height * Constants.Configure.Window.multiplier)
                    BottomButtons(
                        hasChanges: hasChanges,
                        onSave: saveSettings,
                        onCancel: { resetToOriginalValues(); dismiss() }
                    )
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { loadCurrentSettings() }
    }

    // MARK: - Helper Properties & Methods
    private var hasChanges: Bool {
        tempApiKey != appModel.settingsManager.apiKey ||
//        tempDownloadPath.primary != appModel.settingsManager.downloadPath.primary ||
//        tempDownloadPath.backup != appModel.settingsManager.downloadPath.backup ||
        tempDownloadPath != appModel.settingsManager.downloadPath ||
        tempDefaultGridSize != appModel.settingsManager.gridSize ||
        tempHistorySize != appModel.settingsManager.maxHistoryItems
    }

    private func loadCurrentSettings() {
        tempApiKey = appModel.settingsManager.apiKey
        tempDownloadPath = appModel.settingsManager.downloadPath
        tempDefaultGridSize = appModel.settingsManager.gridSize
        tempHistorySize = appModel.settingsManager.maxHistoryItems
    }

    private func resetToOriginalValues() {
        tempApiKey = appModel.settingsManager.apiKey
        tempDownloadPath = appModel.settingsManager.downloadPath
        tempDefaultGridSize = appModel.settingsManager.gridSize
        tempHistorySize = appModel.settingsManager.maxHistoryItems
    }

    private func saveSettings() {
        appModel.settingsManager.apiKey = tempApiKey
        appModel.settingsManager.downloadPath = tempDownloadPath
        appModel.settingsManager.gridSize = tempDefaultGridSize
        appModel.settingsManager.maxHistoryItems = tempHistorySize
        appModel.saveSettings()
    }

    enum SettingsSection: String, CaseIterable {
        case api = "API", preferences = "Preferences", download = "Download"

        var title: String {
            switch self {
            case .api: return "API Configuration"
            case .preferences: return "Preferences"
            case .download: return "Download Locations"
            }
        }

        var symbol: String {
            switch self {
            case .api: return SFSymbol6.Key.keyFill.rawValue
            case .preferences: return SFSymbol6.Gearshape.gearshapeFill.rawValue
            case .download: return SFSymbol6.Folder.folderFill.rawValue
            }
        }

        var description: String {
            switch self {
            case .api: return "Configure your TMDB API settings"
            case .preferences: return "Customize display and behavior settings"
            case .download: return "Set up download and backup locations"
            }
        }
    }
}

#Preview {
    Configure()
        .environment(AppModel())
        .frame(width: 800, height: 600)
}
