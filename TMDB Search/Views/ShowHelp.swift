//
//  ShowHelp.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/08/19.
//
import SwiftUI

// MARK: - Show Help View
struct ShowHelp: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            AppInfo()
            AppInstructions()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - App Info
struct AppInfo: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 24) {
            // TMDB Logo with overlay icon
            ZStack(alignment: .bottomTrailing) {
                Image(Constants.App.image)
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
                
                Text(appModel.version)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - App Instructions
struct AppInstructions: View {
    var body: some View {
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
