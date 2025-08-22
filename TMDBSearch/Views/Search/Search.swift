////
////  TMDBSearchView.swift
////  TMDB Search
////
////  Created by Ian Weatherburn on 2025/08/05.
////

import SwiftUI
import SFSymbol

// MARK: - Main Content View
struct Search: View {
    @Environment(AppModel.self) private var appModel
    @FocusState private var isSearchFieldFocused: Bool
    @Binding var showHelp: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toolbar-style header
                VStack(spacing: 0) {
                    SearchHeader(isSearchFieldFocused: $isSearchFieldFocused)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    
                    Divider()
                }
                .background(.regularMaterial)
                
                // Main content area
                ZStack {
                    Color(NSColor.windowBackgroundColor)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Status messages (errors/loading)
                        if let errorMessage = appModel.errorMessage {
                            StatusMessage(
                                icon: SFSymbol6.Exclamationmark.exclamationmarkTriangleFill.rawValue,
                                message: errorMessage,
                                style: .error
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        if appModel.isLoading {
                            StatusMessage(
                                icon: SFSymbol6.Magnifyingglass.magnifyingglass.rawValue,
                                message: "Searching TMDB...",
                                style: .loading
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Results content
                        if !appModel.searchResults.isEmpty {
                            Results()
                        } else if !appModel.isLoading && appModel.errorMessage == nil {
                            ShowHelp()
                                .transition(.opacity)
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: appModel.isLoading)
            .animation(.easeInOut(duration: 0.25), value: appModel.errorMessage)
        }
        .frame(minWidth: Constants.App.Window.Main.width, minHeight: Constants.App.Window.Main.height)
        .onAppear {
            isSearchFieldFocused = true
            appModel.updateAppTitle(with: "")
        }
        .sheet(isPresented: $showHelp) {
            ShowHelp()
                .padding()
                .frame(minWidth: Constants.App.Window.Help.width, minHeight: Constants.App.Window.Help.height)
        }
    }
}

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
                    ForEach(appModel.searchHistory) { item in
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

#Preview {
    Search(showHelp: .constant(false))
        .environment(AppModel())
}
