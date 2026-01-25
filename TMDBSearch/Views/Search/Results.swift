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
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            ResultsHeader(
                mediaType: appModel.selectedMediaType,
                count: appModel.searchResults.count
            )
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : -20)
            
            Divider()
                .opacity(isAnimating ? 1 : 0)
            
            ResultsList(
                items: appModel.searchResults,
                mediaType: appModel.selectedMediaType
            )
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 10)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                isAnimating = true
            }
        }
        .onChange(of: appModel.searchResults) { oldValue, newValue in
            // Reset and re-animate when results change
            isAnimating = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05)) {
                isAnimating = true
            }
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
                
                Text(count.pluralize("result"))
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
    @State private var animatedIndices: Set<Int> = []
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    AnimatedResultRow(
                        item: item,
                        index: index,
                        mediaType: mediaType,
                        isLastItem: item.id == items.last?.id,
                        isAnimated: animatedIndices.contains(index),
                        onAppear: { animateRow(at: index) }
                    )
                }
            }
        }
        .onChange(of: items) { oldValue, newValue in
            animatedIndices.removeAll()
        }
    }
    
    private func animateRow(at index: Int) {
        _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05)) {
            animatedIndices.insert(index)
        }
    }
}
// MARK: - Animated Result Row
struct AnimatedResultRow: View {
    let item: TMDBMediaItem
    let index: Int
    let mediaType: MediaType
    let isLastItem: Bool
    let isAnimated: Bool
    let onAppear: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ResultRowContent(
                item: item,
                index: index,
                mediaType: mediaType
            )
            
            if !isLastItem {
                ResultRowDivider()
            }
        }
        .opacity(isAnimated ? 1 : 0)
        .offset(x: isAnimated ? 0 : -20)
        .transition(rowTransition)
        .onAppear(perform: onAppear)
    }
    
    private var rowTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .leading)),
            removal: .opacity.combined(with: .scale(scale: 0.95))
        )
    }
}

// MARK: - Result Row Content
struct ResultRowContent: View {
    let item: TMDBMediaItem
    let index: Int
    let mediaType: MediaType
    
    var body: some View {
        MediaItemRow(item: item, type: mediaType)
            .background(rowBackgroundColor)
            .contentShape(Rectangle())
    }
    
    private var rowBackgroundColor: Color {
        Color(index.isMultiple(of: 2)
              ? NSColor.windowBackgroundColor
              : NSColor.controlBackgroundColor)
    }
}

// MARK: - Result Row Divider
struct ResultRowDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 20)
    }
}

