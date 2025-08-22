//
//  Results.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/19.
//
import SwiftUI
import SFSymbol

//// MARK: - Results View
struct Results: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        VStack(spacing: 0) {
            ResultsHeader(
                mediaType: appModel.selectedMediaType,
                count: appModel.searchResults.count
            )
            
            Divider()
            
            ResultsList(
                items: appModel.searchResults,
                mediaType: appModel.selectedMediaType
            )
        }
    }
}

// MARK: - Results Header
struct ResultsHeader: View {
    let mediaType: MediaType
    let count: Int
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: mediaType.displayInfo.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(mediaType.displayInfo.title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text("(\(count) results)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Results List
struct ResultsList: View {
    let items: [TMDBMediaItem]
    let mediaType: MediaType
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 0) {
                        MediaItemRow(item: item, type: mediaType)
                            .background(
                                Color(index.isMultiple(of: 2)
                                      ? NSColor.windowBackgroundColor
                                      : NSColor.controlBackgroundColor)
                            )
                            .contentShape(Rectangle())
                        
                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: items)
    }
}
