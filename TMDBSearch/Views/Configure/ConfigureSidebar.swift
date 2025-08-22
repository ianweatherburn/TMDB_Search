//
//  ConfigureSidebar.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI

struct ConfigureSidebar: View {
    @Binding var selectedSection: Configure.SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TMDB Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            ForEach(Configure.SettingsSection.allCases, id: \.self) { section in
                Button(action: { selectedSection = section },
                       label: {
                    HStack(spacing: 12) {
                        Image(systemName: section.symbol)
                            .foregroundColor(selectedSection == section ? .white : .secondary)
                            .frame(width: 16, height: 16)
                        Text(section.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selectedSection == section ? .white : .primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedSection == section ? Color.accentColor : Color.clear)
                    )
                    .contentShape(Rectangle())
                })
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 8)
            }

            Spacer()
        }
        .frame(width: 200)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
