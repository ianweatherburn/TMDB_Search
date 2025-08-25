//
//  ConfigureDownload.swift
//  TMDBSearch
//
//  Created by Ian Weatherburn on 2025/08/22.
//

import SwiftUI

struct ConfigureDownload: View {
    @Binding var downloadPath: SettingsManager.DownloadPath

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            DownloadPathSection(
                title: "Download Folder",
                path: $downloadPath.primary,
                description: "Primary location where downloaded images will be saved"
            )
            DownloadPathSection(
                title: "Backup Folder",
                path: Binding(
                    get: { downloadPath.backup ?? "" },
                    set: { downloadPath.backup = $0.isEmpty ? nil : $0 }
                ),
                description: "Optional backup location for downloaded images"
            )
        }
    }
}
