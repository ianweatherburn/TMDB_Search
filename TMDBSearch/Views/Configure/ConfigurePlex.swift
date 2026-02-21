//
//  ConfigurePlex.swift
//  TMDB Search
//
//  Created by Claude Code on 2026/02/21.
//

import SwiftUI
import SFSymbol

struct ConfigurePlex: View {
    @Environment(AppModel.self) private var appModel
    
    @Binding var showsLibrary: String
    @Binding var showsLibraryId: String
    @Binding var shows4KLibrary: String
    @Binding var shows4KLibraryId: String
    @Binding var moviesLibrary: String
    @Binding var moviesLibraryId: String
    @Binding var movies4KLibrary: String
    @Binding var movies4KLibraryId: String
    
    @State private var availableLibraries: [PlexLibrary] = []
    @State private var isLoadingLibraries = false
    @State private var libraryFetchError: String?
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Plex Library Mappings")
                    .font(.headline)
                
                if appModel.settingsManager.plexServer.isEmpty || appModel.settingsManager.plexToken.isEmpty {
                    Text("Please configure Plex server address and token above before fetching libraries.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Button(action: {
                        Task {
                            await fetchLibraries()
                        }
                    }, label: {
                        HStack {
                            if isLoadingLibraries {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .padding(.trailing, 4)
                            }
                            Text(isLoadingLibraries ? "Fetching Libraries..." : "Fetch Libraries from Plex")
                        }
                    })
                    .disabled(isLoadingLibraries)
                    
                    if let error = libraryFetchError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if !availableLibraries.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                        
                        libraryPicker(
                            label: "Shows Library",
                            selectedTitle: $showsLibrary,
                            selectedId: $showsLibraryId
                        )
                        
                        libraryPicker(
                            label: "Shows 4K Library",
                            selectedTitle: $shows4KLibrary,
                            selectedId: $shows4KLibraryId
                        )
                        
                        libraryPicker(
                            label: "Movies Library",
                            selectedTitle: $moviesLibrary,
                            selectedId: $moviesLibraryId
                        )
                        
                        libraryPicker(
                            label: "Movies 4K Library",
                            selectedTitle: $movies4KLibrary,
                            selectedId: $movies4KLibraryId
                        )
                    }
                }
            }
        } header: {
            Label("Library Configuration", systemImage: SFSymbol6.Film.filmFill.rawValue)
        } footer: {
            Text("Map your local media types to Plex library names. Fetch libraries first, then select the appropriate library for each type.")
                .font(.caption)
        }
    }
    
    @ViewBuilder
    private func libraryPicker(
        label: String,
        selectedTitle: Binding<String>,
        selectedId: Binding<String>
    ) -> some View {
        HStack {
            Text(label)
                .frame(width: 150, alignment: .leading)
            
            Picker("", selection: selectedTitle) {
                Text("Not Selected").tag("")
                ForEach(availableLibraries) { library in
                    Text(library.title).tag(library.title)
                }
            }
            .onChange(of: selectedTitle.wrappedValue) { _, newValue in
                if let library = availableLibraries.first(where: { $0.title == newValue }) {
                    selectedId.wrappedValue = library.key
                } else {
                    selectedId.wrappedValue = ""
                }
            }
        }
    }
    
    private func fetchLibraries() async {
        isLoadingLibraries = true
        libraryFetchError = nil
        
        do {
            availableLibraries = try await appModel.fetchPlexLibraries()
        } catch {
            libraryFetchError = "Failed to fetch libraries: \(error.localizedDescription)"
            availableLibraries = []
        }
        
        isLoadingLibraries = false
    }
}
