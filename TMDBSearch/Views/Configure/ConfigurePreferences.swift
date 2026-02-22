//
//  ConfigurePreferences.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI

struct ConfigurePreferences: View {
    @Binding var gridSize: GridSize
    @Binding var historySize: Int
    @Binding var showTMDBID: Bool
    @Binding var plexDebugLogging: Bool

    var body: some View {
        Section {
            Picker("Grid Size", selection: $gridSize) {
                ForEach(GridSize.allCases) { size in
                    Text(size.displayName).tag(size)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Image Gallery")
        } footer: {
            Text("Default grid size for displaying images.")
        }
        
        Section {
            HStack {
                Text("History Size")
                Spacer()
                Text("\(historySize)")
                    .foregroundStyle(.secondary)
            }
            
            Slider(
                value: Binding(
                    get: { Double(historySize) },
                    set: { historySize = Int($0) }
                ),
                in: Constants.Configure.Preferences.History.minimum...Constants.Configure.Preferences.History.maximum,
                step: 1
            )
        } header: {
            Text("Search History")
        } footer: {
            Text("Number of recent searches to remember (\(Int(Constants.Configure.Preferences.History.minimum))-\(Int(Constants.Configure.Preferences.History.maximum))).")
        }
        
        Section {
            Toggle("Show TMDB ID", isOn: $showTMDBID)
            Toggle("Enable Plex Debug Logging", isOn: $plexDebugLogging)
        } header: {
            Text("Display Options")
        } footer: {
            Text("Display the TMDB ID alongside media information and optionally enable verbose Plex API logging.")
        }
    }
}
