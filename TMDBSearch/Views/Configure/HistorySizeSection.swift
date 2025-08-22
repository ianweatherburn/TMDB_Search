//
//  HistorySizeSection.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI

struct HistorySizeSection: View {
    @Binding var historySize: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History items to keep:")
                    .font(.headline)
                    .fontWeight(.medium)
                Text("\(historySize)")
                    .font(.headline)
                    .fontWeight(.medium)
            }

            GeometryReader { geometry in
                VStack(alignment: .leading) {
                    Slider(
                        value: Binding(
                            get: { Double(historySize) },
                            set: { historySize = Int($0) }
                        ),
                        in: Constants.Configure.Preferences.History.minimum
                            ...
                            Constants.Configure.Preferences.History.maximum,
                        step: 1
                    )

                    HStack {
                        Text("\(Int(Constants.Configure.Preferences.History.minimum))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(Constants.Configure.Preferences.History.maximum))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: geometry.size.width * Constants.Configure.Window.multiplier)
            }
            .frame(height: 30)

            Text("Number of recent searches to remember")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
