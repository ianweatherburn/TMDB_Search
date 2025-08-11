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
                    
                    MediaTypeButtons()
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
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                ZStack {
                    // Results List
                    ScrollView {
                        // Heading
                        HStack(spacing: 4) {
                            Image(systemName: appModel.selectedMediaType.displayInfo.icon)
                            Text(appModel.selectedMediaType.displayInfo.title)
                                .fontWeight(.bold)
                        }
                        .font(.title)

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
                                    .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "photo.badge.magnifyingglass")
                                    .font(.system(size: 50))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.mint.opacity(0.9), .mint.opacity(0.5))
                                    .shadow(radius: 4)
                                    .padding(-2)
                            }
                            VStack {
                                Group {
                                    Text("Start typing to search TMDB for TV shows, movies or collections.")
                                    Text("**↵** to search for **shows**, **⌥↵** for **movies**, or **⇧↵** for **collections**.")
                                    Text("**Left-Click** a result to copy the Plex folder name with the TMDB ID (*\"Movie Name (Year) {tmdb-ID}*\".")
                                    Text("**Right-click** a result to copy the TMDB *ID* only.")
                                    Text("Tap the list **image** to show a gallery of **posters** or the **artwork** icon for **backdrops**.")
                                    Text("Save the image from the gallery by **tapping** the image, or **⌥+tap** to flip the image horizontally before saving.")
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

struct MediaTypeButtons: View {
    var body: some View {
        HStack(spacing: 12) {
            ForEach(MediaType.allCases, id: \.self) { type in
                MediaTypeButton(type: type)
            }
        }
    }
}

struct MediaTypeButton: View {
    let type: MediaType
    @Environment(AppModel.self) private var appModel

    var body: some View {
        let button = Button {
            appModel.selectedMediaType = type
            Task {
                await appModel.performSearch()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: type.displayInfo.icon)
                Text(type.displayInfo.title)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }

        if type.displayInfo.default {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }
}

#Preview {
    TMDBSearchView()
        .environment(AppModel())
}
