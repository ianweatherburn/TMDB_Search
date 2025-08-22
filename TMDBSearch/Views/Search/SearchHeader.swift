//
//  SearchHeader.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/19.
//

import SwiftUI

// MARK: - Search Header
struct SearchHeader: View {
    @Environment(AppModel.self) private var appModel
    private var isSearchFieldFocused: FocusState<Bool>.Binding
    @State private var showingHistory = false

    init(isSearchFieldFocused: FocusState<Bool>.Binding) {
        self.isSearchFieldFocused = isSearchFieldFocused
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Search field with integrated icon
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 15))
                
                TextField("Search TMDB for shows, movies, or collections", text: Bindable(appModel).searchText)
                    .textFieldStyle(.plain)
                    .focused(isSearchFieldFocused)
                    .font(.system(size: 13))
                    .onKeyPress { keyPress in
                        if keyPress.key == .return {
                            if keyPress.modifiers.contains(.shift) {
                                Task {
                                    appModel.selectedMediaType = .movie
                                    await appModel.performSearch()
                                }
                                return .handled
                            } else if keyPress.modifiers.contains(.option) {
                                Task {
                                    appModel.selectedMediaType = .collection
                                    await appModel.performSearch()
                                }
                                return .handled
                            } else {
                                // Plain return - default to TV
                                Task {
                                    appModel.selectedMediaType = .tv
                                    await appModel.performSearch()
                                }
                                return .handled
                            }
                        } else if keyPress.key == .downArrow && !appModel.searchHistory.isEmpty {
                            showingHistory = true
                            return .handled
                        }
                        return .ignored
                    }
                    .onChange(of: appModel.searchText) {
                        if appModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            appModel.searchResults = []
                            appModel.errorMessage = nil
                            appModel.updateAppTitle()
                        }
                    }
                
                // History dropdown button
                if !appModel.searchHistory.isEmpty {
                    Button(action: {
                        showingHistory.toggle()
                    }, label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 13))
                    })
                    .buttonStyle(.plain)
                    .help("Search History")
                }
                
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(minWidth: Constants.App.Window.Main.height)
            .popover(isPresented: $showingHistory, arrowEdge: .bottom) {
                SearchHistoryDropdown()
            }
            
            // Media type selector
            MediaTypeSegmentedPicker()
        }
    }
}

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

#Preview {
    @Previewable @FocusState var isSearchFieldFocused: Bool
    SearchHeader(isSearchFieldFocused: $isSearchFieldFocused)
        .environment(AppModel())   // inject a test AppModel
        .padding()
        .frame(width: Constants.App.Window.Main.width)
}
