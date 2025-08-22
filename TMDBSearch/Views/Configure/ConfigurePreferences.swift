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

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            GridSizeSection(gridSize: $gridSize)
            HistorySizeSection(historySize: $historySize)
        }
    }
}
