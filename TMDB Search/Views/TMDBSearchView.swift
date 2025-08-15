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
                SearchHeader(isSearchFieldFocused: $isSearchFieldFocused)
                
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
                    .transition(.opacity)
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
                                    .transition(.opacity.combined(with: .move(edge: .top))) // Fade + slide for rows
                            }
                        }
                        .padding(.horizontal)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appModel.searchResults)
                    
                    if appModel.searchResults.isEmpty && !appModel.isLoading && appModel.errorMessage == nil {
                        WelcomeView()
                            .transition(.opacity) 
                    }
                }
                
                Spacer()
            }
            .padding(.top, 16)
            .animation(.easeInOut(duration: 0.3), value: appModel.isLoading) // Animate loading state
            .animation(.easeInOut(duration: 0.3), value: appModel.errorMessage) // Animate error state
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            isSearchFieldFocused = true
        }
    }
}

struct SearchHeader: View {
    @Environment(AppModel.self) private var appModel
    private var isSearchFieldFocused: FocusState<Bool>.Binding

    init(isSearchFieldFocused: FocusState<Bool>.Binding) {
        self.isSearchFieldFocused = isSearchFieldFocused
    }
    
    var body: some View {
        // Search Header
        HStack {
            TextField("Search for TV shows, movies or collections from TMDB...", text: Bindable(appModel).searchText)
                .textFieldStyle(.roundedBorder)
                .focused(isSearchFieldFocused)
                .onSubmit {
                    Task {
                        await appModel.performSearch()
                    }
                }
                .onKeyPress { keyPress in
                    // Check for Enter key with modifiers
                    if keyPress.key == .return {
                        if keyPress.modifiers.contains(.shift) {
                            // Option+Enter searches for movies
                            Task {
                                appModel.selectedMediaType = .movie
                                await appModel.performSearch()
                            }
                            return .handled
                        } else if keyPress.modifiers.contains(.option) {
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

struct WelcomeView: View {
    var body: some View {
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
                    Text("**↵** to search for **shows**, **⇧↵** for **movies**, or **⌥↵** for **collections**.")
                    Text("**Tap** to copy the Plex folder name with the TMDB ID *\"Title (Year) {tmdb-ID}*\".")
                    Text("**⌥+Tap** to copy the TMDB *ID* only.")
                    Text("**Tap** the **image** to show a gallery of **posters**, or the **artwork** icon for **backdrops**.")
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

#Preview {
    TMDBSearchView()
        .environment(AppModel())
}
