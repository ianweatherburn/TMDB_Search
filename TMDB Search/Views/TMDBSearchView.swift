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
                
                // Results List
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(appModel.searchResults) { item in
                            MediaItemRow(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 16)
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            isSearchFieldFocused = true
        }
    }
}

#Preview {
    TMDBSearchView()
        .environment(AppModel())
}
