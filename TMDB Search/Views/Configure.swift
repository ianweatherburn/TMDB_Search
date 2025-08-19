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
    @State private var tempDefaultGridSize: GridSize = .medium
    @State private var tempHistorySize = 25
    
    enum SettingsSection: String, CaseIterable {
        case api = "API"
        case preferences = "Preferences"
        case download = "Download"
        
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
    
    var body: some View {
        GeometryReader { geometry in
            let maxHeight = geometry.size.height * 0.80
            
            HStack(spacing: 0) {
                // Sidebar
                VStack(alignment: .leading, spacing: 0) {
                    // Sidebar header
                    Text("TMDB Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    // Sidebar items
                    VStack(spacing: 2) {
                        ForEach(SettingsSection.allCases, id: \.self) { section in
                            Button(action: {
                                selectedSection = section
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: section.symbol)
                                        .foregroundColor(selectedSection == section ? .white : .secondary)
                                        .frame(width: 16, height: 16)
                                    
                                    Text(section.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(selectedSection == section ? .white : .primary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedSection == section ? Color.accentColor : Color.clear)
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 8)
                        }
                    }
                    
                    Spacer()
                }
                .frame(width: 200)
                .background(Color(NSColor.controlBackgroundColor))
                
                // Separator
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(width: 1)
                
                // Content area
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Section header
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: selectedSection.symbol)
                                        .foregroundColor(.accentColor)
                                        .font(.title2)
                                    Text(selectedSection.title)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                Text(selectedSection.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 32)
//                            .padding(.top, 0)
                            .padding(.bottom, 8)
                            
                            // Content based on selected section
                            Group {
                                switch selectedSection {
                                case .api:
                                    apiConfigurationView()
                                case .preferences:
                                    preferencesView()
                                case .download:
                                    downloadLocationsView()
                                }
                            }
                            .padding(.horizontal, 32)
                            .padding(.bottom, 16)
                        }
                    }
                    .frame(maxHeight: maxHeight) // Reserve space for buttons
                    
                    // Bottom buttons
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(NSColor.separatorColor))
                            .frame(height: 1)
                        
                        HStack {
                            Spacer()
                            Button("Cancel") {
                                resetToOriginalValues()
                                dismiss()
                            }
                            .keyboardShortcut(.cancelAction)
                            .controlSize(.large)
                            
                            Button("Save") {
                                saveSettings()
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)
                            .controlSize(.large)
                            .disabled(!hasChanges)
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 8)
                        .background(Color(NSColor.windowBackgroundColor))
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    @ViewBuilder
    private func apiConfigurationView() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.headline)
                    .fontWeight(.medium)
                
                SecureField("Enter your TMDB API key", text: $tempApiKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                
                Text("Get your API key from [themoviedb.org](https://www.themoviedb.org/settings/api)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func preferencesView() -> some View {
        VStack(alignment: .leading, spacing: 32) {
            // Grid Size
            VStack(alignment: .leading, spacing: 12) {
                Text("Image Grid Size")
                    .font(.headline)
                    .fontWeight(.medium)
                GeometryReader { geometry in
                    Picker("", selection: $tempDefaultGridSize) {
                        ForEach(GridSize.allCases) { gridSize in
                            Text(gridSize.displayName).tag(gridSize)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.leading, -8)
                    .frame(width: geometry.size.width * 0.75)
                }
                .frame(height: 30)
                
                Text("Default grid size for the image gallery")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // History Size
            VStack(alignment: .leading, spacing: 12) {
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("History items to keep:")
                            .font(.headline)
                            .fontWeight(.medium)
                        Text("\(tempHistorySize)")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    
                    GeometryReader { geometry in
                        VStack(alignment: .leading) {
                            Slider(
                                value: Binding(
                                    get: { Double(tempHistorySize) },
                                    set: { tempHistorySize = Int($0) }
                                ),
                                in: 5...50,
                                step: 1
                            )
                            
                            HStack {
                                Text("5")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("50")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: geometry.size.width * 0.75)
                    }
                    .frame(height: 30)

                }
                
                Text("Number of recent searches to remember")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func downloadLocationsView() -> some View {
        VStack(alignment: .leading, spacing: 32) {
            // Primary Download Path
            VStack(alignment: .leading, spacing: 12) {
                Text("Download Folder")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    TextField("Select download folder", text: $tempDownloadPath.primary)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Choose...") {
                        if let path = chooseDownloadPath() {
                            tempDownloadPath.primary = path
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                if !tempDownloadPath.primary.isEmpty {
                    Label(tempDownloadPath.primary, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Text("Primary location where downloaded images will be saved")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Backup Download Path
            VStack(alignment: .leading, spacing: 12) {
                Text("Backup Folder")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    TextField("Select backup folder (optional)", text: Binding(
                        get: { tempDownloadPath.backup ?? "" },
                        set: { tempDownloadPath.backup = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    Button("Choose...") {
                        tempDownloadPath.backup = chooseDownloadPath()
                    }
                    .buttonStyle(.bordered)
                }
                
                if let backup = tempDownloadPath.backup, !backup.isEmpty {
                    Label(backup, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Text("Optional backup location for downloaded images")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadCurrentSettings() {
        tempApiKey = appModel.apiKey
        tempDownloadPath = appModel.downloadPath
        tempDefaultGridSize = appModel.gridSize
        tempHistorySize = appModel.maxHistoryItems
    }

    private func resetToOriginalValues() {
        tempApiKey = appModel.apiKey
        tempDownloadPath.primary = appModel.downloadPath.primary
        tempDownloadPath.backup = appModel.downloadPath.backup
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

    private func chooseDownloadPath() -> String? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Folder"
        panel.title = "Select Download Folder"

        if panel.runModal() == .OK {
            guard let url = panel.url else { return nil }
            return url.path
        }

        return nil
    }
    
    // MARK: - Helper Properties

    private var hasChanges: Bool {
        tempApiKey != appModel.apiKey ||
        tempDownloadPath.primary != appModel.downloadPath.primary ||
        tempDownloadPath.backup != appModel.downloadPath.backup ||
        tempDefaultGridSize != appModel.gridSize ||
        tempHistorySize != appModel.maxHistoryItems
    }
}

#Preview {
    Configure()
        .environment(AppModel())
        .frame(width: 800, height: 600)
}
