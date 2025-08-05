//
//  Settings.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var tempApiKey: String = ""
    @State private var tempDownloadPath: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("TMDB API Settings")) {
                TextField("API Key", text: $tempApiKey)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    TextField("Download Path", text: $tempDownloadPath)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Choose...") {
                        chooseDownloadPath()
                    }
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    // Reset to original values
                    tempApiKey = appModel.apiKey
                    tempDownloadPath = appModel.downloadPath
                    closeSettingsWindow()
                }
                
                Button("Save") {
                    appModel.apiKey = tempApiKey
                    appModel.downloadPath = tempDownloadPath
                    appModel.saveSettings()
                    closeSettingsWindow()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500, height: 200)
        .onAppear {
            tempApiKey = appModel.apiKey
            tempDownloadPath = appModel.downloadPath
        }
    }
    
    private func chooseDownloadPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                tempDownloadPath = url.path
            }
        }
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
