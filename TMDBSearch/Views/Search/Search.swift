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
        .sheet(isPresented: Binding(appModel, keyPath: \.showHelp)) {
            ShowHelp()
                .padding()
                .frame(minWidth: Constants.App.Window.Help.width, minHeight: Constants.App.Window.Help.height)
        }
    }
}

#Preview {
    Search()
        .environment(AppModel())
}
