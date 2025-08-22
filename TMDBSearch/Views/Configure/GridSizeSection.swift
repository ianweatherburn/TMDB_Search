//
//  GridSizeSection.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI

struct GridSizeSection: View {
    @Binding var gridSize: GridSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image Grid Size")
                .font(.headline)
                .fontWeight(.medium)

            GeometryReader { geometry in
                Picker("", selection: $gridSize) {
                    ForEach(GridSize.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.leading, -8)
                .frame(width: geometry.size.width * Constants.Configure.Window.multiplier)
            }
            .frame(height: 30)

            Text("Default grid size for the image gallery")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
