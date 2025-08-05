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
                    }
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
                    }
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
                        VStack(spacing: 8) {
                            Image("tmdb")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 256, height: 256)
                                .opacity(0.6)
                            Group {
                                Text("Search The Movie Database (TMDB) for a show (by default) or a movie.")
                                Text("Left-Click on a search result to copy the Plex folder name with the TMDB-ID.")
                                Text("Right-click on a search result to just copy the TMDB-ID.")
                                Text("Click the media poster to display and download various posters.")
                                Text("Click the backdrop icon to display and download various backgrounds.")
                                Text("Start typing to search for TV shows or movies.")
                            }
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
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
