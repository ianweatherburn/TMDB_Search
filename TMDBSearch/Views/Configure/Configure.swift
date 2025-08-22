////
////  Configure.swift
////  TMDB Search
////
////  Created by Ian Weatherburn on 2025/08/05.
////

import SwiftUI

struct Configure: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: SettingsSection = .api
    @State private var tempApiKey = ""
    @State private var tempDownloadPath = AppModel.DownloadPath(primary: "", backup: nil)
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
        tempApiKey != appModel.apiKey ||
        tempDownloadPath.primary != appModel.downloadPath.primary ||
        tempDownloadPath.backup != appModel.downloadPath.backup ||
        tempDefaultGridSize != appModel.gridSize ||
        tempHistorySize != appModel.maxHistoryItems
    }

    private func loadCurrentSettings() {
        tempApiKey = appModel.apiKey
        tempDownloadPath = appModel.downloadPath
        tempDefaultGridSize = appModel.gridSize
        tempHistorySize = appModel.maxHistoryItems
    }

    private func resetToOriginalValues() {
        tempApiKey = appModel.apiKey
        tempDownloadPath = appModel.downloadPath
        tempDefaultGridSize = appModel.gridSize
        tempHistorySize = appModel.maxHistoryItems
    }

    private func saveSettings() {
        appModel.apiKey = tempApiKey
        appModel.downloadPath = tempDownloadPath
        appModel.gridSize = tempDefaultGridSize
        appModel.maxHistoryItems = tempHistorySize
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
            case .api: return "key.fill"
            case .preferences: return "gearshape.fill"
            case .download: return "folder.fill"
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
