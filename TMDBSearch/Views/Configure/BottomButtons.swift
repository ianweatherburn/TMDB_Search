//
//  BottomButtons.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI

struct BottomButtons: View {
    let hasChanges: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(height: 1)

            HStack {
                Spacer()

                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                    .controlSize(.large)

                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .controlSize(.large)
                    .disabled(!hasChanges)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}
