//
//  ConfigureSectionHeader.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI

struct ConfigureSectionHeader: View {
    let section: Configure.SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: section.symbol)
                    .foregroundColor(.accentColor)
                    .font(.title2)
                Text(section.title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            Text(section.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 8)
    }
}
