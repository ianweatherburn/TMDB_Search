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

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            GridSizeSection(gridSize: $gridSize)
            HistorySizeSection(historySize: $historySize)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("TMDB-ID")
                    .font(.headline)
                    .fontWeight(.medium)

                Toggle("Show TMDB ID", isOn: $showTMDBID)
                    .toggleStyle(.switch) // or .button for a button-style toggle
            }
        }
        .padding()
    }
}
