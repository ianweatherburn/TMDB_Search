//
//  SearchHeader.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/19.
//

import SwiftUI
import SFSymbol

// MARK: - Search Header
struct SearchHeader: View {
    @Environment(AppModel.self) private var appModel
    private var isSearchFieldFocused: FocusState<Bool>.Binding

    init(isSearchFieldFocused: FocusState<Bool>.Binding) {
        self.isSearchFieldFocused = isSearchFieldFocused
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Search field with integrated icon
            HStack(spacing: 8) {
                Image(symbol: SFSymbol6.Magnifyingglass.magnifyingglass)
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
                        } else if keyPress.key == .downArrow && !appModel.settingsManager.searchHistory.isEmpty {
                            appModel.showHistory = true
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
                
                // Clear button - only visible when there's text
                if !appModel.searchText.isEmpty {
                    Button(action: {
                        appModel.clearSearch()
                    }, label: {
                        Image(symbol: SFSymbol6.Xmark.xmarkCircle)
                            .foregroundStyle(.secondary)
                            .font(.system(size: 13))
                    })
                    .buttonStyle(.plain)
                    .help("Clear search (⌘⌫)")
                    .keyboardShortcut(.delete, modifiers: .command)
                }
                
                // History dropdown button
                if !appModel.settingsManager.searchHistory.isEmpty {
                    Button(action: {
                        appModel.showHistory.toggle()
                    }, label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 13))
                    })
                    .buttonStyle(.plain)
                    .popover(isPresented: Bindable(appModel).showHistory, arrowEdge: .bottom) {
                        SearchHistoryDropdown()
                    }
                    .help("Search History (⌘⇧H)")
                    .keyboardShortcut("h", modifiers: [.command, .shift])
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
            
            // Media type selector
            MediaTypeSegmentedPicker()
        }
    }
}

#Preview {
    @Previewable @FocusState var isSearchFieldFocused: Bool
    SearchHeader(isSearchFieldFocused: $isSearchFieldFocused)
        .environment(AppModel())
        .padding()
}
