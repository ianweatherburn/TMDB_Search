////
////  Settings.swift
////  TMDB Search
////
////  Created by Ian Weatherburn on 2025/08/05.
////

import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var tempApiKey: String = ""
    @State private var tempDownloadPath: AppModel.DownloadPath = AppModel.DownloadPath(primary: "", backup: nil)
    @State private var tempDefaultGridSize: GridSize = .medium

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("TMDB Search Settings")
                    .font(.title2)
                    .fontWeight(.medium)
                Text("Configure your TMDB API settings and download locations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // Settings Content
            VStack(alignment: .leading, spacing: 20) {
                // API Key Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Configuration")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("TMDB API Key:")
                                .frame(width: 140, alignment: .trailing)
                            SecureField("Enter your API key", text: $tempApiKey)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)
                        }
                        
                        HStack {
                            Spacer()
                                .frame(width: 140)
                            Text("Get your API key from themoviedb.org")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }
                
                // Display Preferences Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Preferences")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Default Grid Size:")
                            .frame(width: 140, alignment: .trailing)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("", selection: $tempDefaultGridSize) {
                                ForEach(GridSize.allCases) { gridSize in
                                    Text(gridSize.displayName)
                                        .tag(gridSize)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 400, alignment: .leading)
                            
                            Text("This will be the default grid size when opening image collections")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Download Paths Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Download Locations")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Primary Download Path
                        HStack {
                            Text("Download Path:")
                                .frame(width: 140, alignment: .trailing)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    TextField("Select download folder", text: $tempDownloadPath.primary)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(false)
                                    
                                    Button("Choose...") {
                                        if let path = chooseDownloadPath() {
                                            tempDownloadPath.primary = path
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                
                                if !tempDownloadPath.primary.isEmpty {
                                    Text(tempDownloadPath.primary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                        }
                        
                        // Backup Download Path
                        HStack {
                            Text("Backup Path:")
                                .frame(width: 140, alignment: .trailing)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    TextField("Select backup folder (optional)", text: Binding(
                                        get: { tempDownloadPath.backup ?? "" },
                                        set: { tempDownloadPath.backup = $0.isEmpty ? nil : $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(false)
                                    
                                    Button("Choose...") {
                                        tempDownloadPath.backup = chooseDownloadPath()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                
                                if let backup = tempDownloadPath.backup, !backup.isEmpty {
                                    Text(backup)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
            
            // Bottom Action Bar
            Divider()
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    resetToOriginalValues()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!hasChanges)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(width: 600, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - Helper Properties
    
    private var hasChanges: Bool {
        tempApiKey != appModel.apiKey ||
        tempDownloadPath.primary != appModel.downloadPath.primary ||
        tempDownloadPath.backup != appModel.downloadPath.backup ||
        tempDefaultGridSize != appModel.gridSize
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentSettings() {
        tempApiKey = appModel.apiKey
        tempDownloadPath = appModel.downloadPath
        tempDefaultGridSize = appModel.gridSize
    }
    
    private func resetToOriginalValues() {
        tempApiKey = appModel.apiKey
        tempDownloadPath.primary = appModel.downloadPath.primary
        tempDownloadPath.backup = appModel.downloadPath.backup
        tempDefaultGridSize = appModel.gridSize
    }
    
    private func saveSettings() {
        appModel.apiKey = tempApiKey
        appModel.downloadPath = tempDownloadPath
        appModel.gridSize = tempDefaultGridSize
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
}

#Preview {
    SettingsView()
        .environment(AppModel())
}
