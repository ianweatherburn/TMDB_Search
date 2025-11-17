//
//  AppModel+Clipboard.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/11/17.
//

import AppKit // Required for NSPasteboard and NSSound

// MARK: - Clipboard Functionality
extension AppModel {
    func copyToClipboard(_ item: TMDBMediaItem, idOnly: Bool = false, nameOnly: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if idOnly {
            // Copy TMDB ID only
            pasteboard.setString(String(item.id), forType: .string)
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.idCopy))?.play()
        } else if nameOnly {
            // Copy Name only
            pasteboard.setString(String(item.formattedTitle), forType: .string)
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.nameCopy))?.play()
        } else {
            // Copy Plex formatted name with title and tmdb-id
            pasteboard.setString("\(item.plexTitle.replacingColonsWithDashes)", forType: .string)
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.nameCopy))?.play()
        }
    }
}
