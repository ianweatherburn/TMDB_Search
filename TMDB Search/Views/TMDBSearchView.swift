//
//  TMDBSearchView.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/05.
//

import SwiftUI

// MARK: - Main Content View
struct TMDBSearchView: View {
    @Environment(AppModel.self) private var appModel
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Search Header
                HStack {
                    TextField("Search for TV shows or movies...", text: Bindable(appModel).searchText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            Task {
                                await appModel.performSearch()
                            }
                        }
                        .onKeyPress { keyPress in
                            // Check for Enter key with modifiers
                            if keyPress.key == .return {
                                if keyPress.modifiers.contains(.option) {
                                    // Option+Enter searches for movies
                                    Task {
                                        appModel.selectedMediaType = .movie
                                        await appModel.performSearch()
                                    }
                                    return .handled
                                } else if keyPress.modifiers.contains(.shift) {
                                    // Shift+Enter searches for collections
                                    Task {
                                        appModel.selectedMediaType = .collection
                                        await appModel.performSearch()
                                    }
                                    return .handled
                                }
                            }
                            appModel.selectedMediaType = .tv // Revert the default search-type
                            return .ignored
                        }
                        .onChange(of: appModel.searchText) {
                            if appModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                appModel.searchResults = []
                                appModel.errorMessage = nil
                            }
                        }
                    
                    Button(action: {
                        appModel.selectedMediaType = .tv
                        Task {
                            await appModel.performSearch()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.tv")
                            Text("Shows")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(width: 120)
                    .buttonStyle(.borderedProminent) // Consistent style
                    .controlSize(.large)
                    
                    Button(action: {
                        appModel.selectedMediaType = .movie
                        Task {
                            await appModel.performSearch()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "movieclapper")
                            Text("Movies")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(width: 120)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: {
                        appModel.selectedMediaType = .collection
                        Task {
                            await appModel.performSearch()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "film.stack")
                            Text("Collections")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(width: 120)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                }
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = appModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Loading Indicator
                if appModel.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Searching...")
                    }
                    .padding(.horizontal)
                }
                
                ZStack {
                    // Results List
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(appModel.searchResults) { item in
                                MediaItemRow(item: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if appModel.searchResults.isEmpty && !appModel.isLoading && appModel.errorMessage == nil {
                        VStack(spacing: 18) {
                            ZStack(alignment: .bottom) {
                                Image("tmdb")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .scaledToFit()
                                    .frame(width: 256, height: 256)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                //                                .opacity(0.6)
                                    .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "photo.badge.magnifyingglass")
                                    .font(.system(size: 50))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.green.opacity(0.4), .mint.opacity(0.8))
                                    .shadow(radius: 4)
                                    .padding(-2)
                            }
                            VStack {
                                Group {
                                    Text("Start typing to search TMDB for TV shows, movies or collections.")
                                    Text("**↵** to search for **shows**, **⌥↵** for **movies**, or **⇧↵** for **collections**.")
                                    Text("**Left-Click** a result to copy the Plex folder name with the TMDB ID (*\"Movie Name (Year) {tmdb-ID}*\".")
                                    Text("**Right-click** a result to copy the TMDB *ID* only.")
                                    Text("Click the **thumnail** to download **posters** or the **artwork** for **backdrops**.")
                                }
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.top, 1)
                            }
                            .padding(.top, 20)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 16)
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            isSearchFieldFocused = true
        }
        .animation(.easeInOut(duration: 0.75), value: appModel.searchResults)
    }
}

#Preview {
    TMDBSearchView()
        .environment(AppModel())
}
