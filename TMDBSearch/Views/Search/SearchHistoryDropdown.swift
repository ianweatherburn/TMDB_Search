//
//  SearchHistory.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/26.
//

import SwiftUI

// MARK: - Search History Dropdown
struct SearchHistoryDropdown: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Search History")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                
                Spacer()
                
                Button("Clear", action: {
                    appModel.clearSearchHistory()
                    dismiss()
                })
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // History items
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(appModel.settingsManager.searchHistory) { item in
                        SearchHistoryRow(item: item) {
                            appModel.selectHistoryItem(item)
                            dismiss()
                            Task {
                                await appModel.performSearch()
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 300)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Search History Row
struct SearchHistoryRow: View {
    let item: SearchHistoryItem
    let onSelect: () -> Void
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        HStack(spacing: 8) {
            // Media type icon
            Image(systemName: item.mediaType.displayInfo.icon)
                .foregroundStyle(.secondary)
                .font(.system(size: 12))
                .frame(width: 16)
            
            // Search text
            Text(item.searchText)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            // Remove button
            Button(action: {
                appModel.removeFromHistory(item)
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
            })
            .buttonStyle(.plain)
            .opacity(0.6)
            .help("Remove from history")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .background(
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        )
    }
}
