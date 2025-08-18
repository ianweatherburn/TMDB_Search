////
////  TMDBSearchView.swift
////  TMDB Search
////
////  Created by Ian Weatherburn on 2025/08/05.
////

import SwiftUI

// MARK: - Main Content View
struct TMDBSearchView: View {
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
                    Color(NSColor.controlBackgroundColor)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Status messages (errors/loading)
                        if let errorMessage = appModel.errorMessage {
                            StatusMessageView(
                                icon: "exclamationmark.triangle.fill",
                                message: errorMessage,
                                style: .error
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        if appModel.isLoading {
                            StatusMessageView(
                                icon: "magnifyingglass",
                                message: "Searching TMDB...",
                                style: .loading
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Results content
                        if !appModel.searchResults.isEmpty {
                            ResultsView()
                        } else if !appModel.isLoading && appModel.errorMessage == nil {
                            WelcomeView()
                                .transition(.opacity)
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: appModel.isLoading)
            .animation(.easeInOut(duration: 0.25), value: appModel.errorMessage)
        }
        .frame(minWidth: 900, minHeight: 650)
        .onAppear {
            isSearchFieldFocused = true
            if let window = NSApplication.shared.windows.first {
                window.title = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "TMDB Search"
            }
        }
    }
}

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
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 15))
                
                TextField("Search TMDB for shows, movies, or collections", text: Bindable(appModel).searchText)
                    .textFieldStyle(.plain)
                    .focused(isSearchFieldFocused)
                    .font(.system(size: 13))
//                    .onSubmit {
//                        // Update title before performing search
//                        if let window = NSApplication.shared.windows.first {
//                            if appModel.searchText.isEmpty {
//                                window.title = appModel.appTitle
//                            }
//                            else {
//                                let searchText = appModel.searchText.capitalized
//                                window.title = "\(appModel.appTitle) - '\(searchText)'"
//                            }
//                        }
//                        
//                        Task {
//                            await appModel.performSearch()
//                        }
//                    }
                    .onKeyPress { keyPress in
                        if keyPress.key == .return {
                            if keyPress.modifiers.contains(.shift) {
                                Task {
                                    appModel.selectedMediaType = .movie
                                    UpdateAppTitle(title: appModel.appTitle, searchText: appModel.searchText, type: appModel.selectedMediaType)
                                    await appModel.performSearch()
                                }
                                return .handled
                            } else if keyPress.modifiers.contains(.option) {
                                Task {
                                    appModel.selectedMediaType = .collection
                                    UpdateAppTitle(title: appModel.appTitle, searchText: appModel.searchText, type: appModel.selectedMediaType)
                                    await appModel.performSearch()
                                }
                                return .handled
                            } else {
                                // Plain return - default to TV
                                Task {
                                    appModel.selectedMediaType = .tv
                                    UpdateAppTitle(title: appModel.appTitle, searchText: appModel.searchText, type: appModel.selectedMediaType)
                                    await appModel.performSearch()
                                }
                                return .handled
                            }
                        }
                        return .ignored
                    }
                    .onChange(of: appModel.searchText) {
                        if appModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            UpdateAppTitle(title: appModel.appTitle, searchText: appModel.searchText, type: appModel.selectedMediaType)
                            appModel.searchResults = []
                            appModel.errorMessage = nil
                        }
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
            .frame(minWidth: 300)
            
            // Media type selector
            MediaTypeSegmentedPicker()
        }
    }
}

private func UpdateAppTitle(title: String, searchText: String, type: MediaType) {
    // Update title before performing search
    if let window = NSApplication.shared.windows.first {
        if searchText.isEmpty {
            window.title = title
        }
        else {
            window.title =
                "\(title)" +
                "- " +
                "'\(searchText.capitalized) " +
                "(" +
            "\(type == .tv ? "Show" : type.rawValue.capitalized)" +
                ")'"
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
                    UpdateAppTitle(title: appModel.appTitle, searchText: appModel.searchText, type: appModel.selectedMediaType)

                    if !appModel.searchText.isEmpty {
                        Task { await appModel.performSearch() }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: type.displayInfo.icon)
                        Text(type.displayInfo.title)
                    }
                    .font(.system(size: 14))
                    .padding(.horizontal, 2)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
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

// MARK: - Status Message View
struct StatusMessageView: View {
    let icon: String
    let message: String
    let style: MessageStyle
    
    enum MessageStyle {
        case error, loading, info
        
        var color: Color {
            switch self {
            case .error: return .red
            case .loading: return .blue
            case .info: return .secondary
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if style == .loading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: icon)
                        .foregroundStyle(style.color)
                        .font(.system(size: 16))
                }
            }
            
            Text(message)
                .foregroundStyle(style.color)
                .font(.system(size: 13))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Results View
struct ResultsView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Results header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: appModel.selectedMediaType.displayInfo.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text(appModel.selectedMediaType.displayInfo.title)
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text("(\(appModel.searchResults.count) results)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Results list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(appModel.searchResults) { item in
                        VStack(spacing: 0) {
                            MediaItemRow(item: item)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(NSColor.controlBackgroundColor))
                                .contentShape(Rectangle())
                            
                            if item.id != appModel.searchResults.last?.id {
                                Divider()
                                    .padding(.leading, 20)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appModel.searchResults)
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                // TMDB Logo with overlay icon
                ZStack(alignment: .bottomTrailing) {
                    Image("tmdb")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 40))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                        .background(Circle().fill(.white))
                        .offset(x: 8, y: 8)
                }
                
                VStack(spacing: 8) {
                    Text("Search The Movie Database")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Text("Find shows, movies, or collections with detailed metadata & artwork")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Instructions - Two column layout
            HStack(alignment: .top, spacing: 32) {
                // Search Instructions (Left)
                VStack(alignment: .trailing, spacing: 12) {
                    Text("Search")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 4)
                    
                    InstructionRow(
                        symbol: "return",
                        title: "Shows",
                        description: "Press Return",
                        alignment: .trailing
                    )
                    
                    InstructionRow(
                        symbol: "shift",
                        title: "Movies",
                        description: "Shift + Return",
                        alignment: .trailing
                    )
                    
                    InstructionRow(
                        symbol: "option",
                        title: "Collections",
                        description: "Option + Return",
                        alignment: .trailing
                    )
                }
                .frame(maxWidth: 220, alignment: .trailing)
                
                // Vertical divider
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 1)
                    .frame(maxHeight: 180)
                
                // Action Instructions (Right)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Actions")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 4)
                    
                    InstructionRow(
                        symbol: "hand.tap",
                        title: "Copy Formatted Filename",
                        description: "Click result item"
                    )
                    
                    InstructionRow(
                        symbol: "option",
                        title: "Copy TMDB-ID Only",
                        description: "Option + Click"
                    )
                    
                    InstructionRow(
                        symbol: "photo",
                        title: "Browse Images",
                        description: "Click poster or artwork logo"
                    )
                }
                .frame(maxWidth: 220, alignment: .leading)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Instruction Row
struct InstructionRow: View {
    let symbol: String
    let title: String
    let description: String
    let alignment: HorizontalAlignment
    
    init(symbol: String, title: String, description: String, alignment: HorizontalAlignment = .leading) {
        self.symbol = symbol
        self.title = title
        self.description = description
        self.alignment = alignment
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if alignment == .trailing {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(width: 20, alignment: .center)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(width: 20, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    TMDBSearchView()
        .environment(AppModel())
}
