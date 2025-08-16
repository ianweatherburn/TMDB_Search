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
    @State private var tempApiKey: String = ""
    @State private var tempDownloadPath: AppModel.DownloadPath = AppModel.DownloadPath(primary: "", backup: nil)

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
                    closeSettingsWindow()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    saveSettings()
                    closeSettingsWindow()
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
        tempDownloadPath.backup != appModel.downloadPath.backup
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentSettings() {
        tempApiKey = appModel.apiKey
        tempDownloadPath = appModel.downloadPath
    }
    
    private func resetToOriginalValues() {
        tempApiKey = appModel.apiKey
        tempDownloadPath.primary = appModel.downloadPath.primary
        tempDownloadPath.backup = appModel.downloadPath.backup
    }
    
    private func saveSettings() {
        appModel.apiKey = tempApiKey
        appModel.downloadPath = tempDownloadPath
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
    
    private func closeSettingsWindow() {
        // Find the Settings window and close it
        if let settingsWindow = NSApplication.shared.windows.first(where: { $0.title == "TMDB Search Settings" }) {
            settingsWindow.close()
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppModel())
}
