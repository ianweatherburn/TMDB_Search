//
//  SearchMediaType.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/26.
//

import SwiftUI

// MARK: - Media Type Picker
struct MediaTypeSegmentedPicker: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(MediaType.allCases.enumerated()), id: \.element) { index, type in
                Button {
                    appModel.selectedMediaType = type
                    if !appModel.searchText.isEmpty {
                        Task { await appModel.performSearch() }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: type.displayInfo.icon)
                        Text(type.displayInfo.title)
                    }
                    .font(.system(size: 14))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background(
                    Group {
                        if appModel.selectedMediaType == type {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.accentColor)
                                .padding(3)

                        } else {
                            Color(NSColor.controlColor)
                        }
                    }
                )
                .foregroundStyle(appModel.selectedMediaType == type ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: index == 0 ? 6 : 0,
                                            style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: index == MediaType.allCases.count - 1 ? 6 : 0,
                                            style: .continuous))
            }
        }
        .background(Color(NSColor.controlColor), in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.separator, lineWidth: 0.5))
    }
}
