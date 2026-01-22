//
//  AppModel+Clipboard.swift
//  TMDB Search
//
//  Created by Ian Weatherburn on 2025/11/17.
//

import AppKit // Required for NSPasteboard and NSSound

enum CopyParts {
    case folder
    case id
    case name
    case updatePoster
}

// MARK: - Clipboard Functionality
extension AppModel {
    func copyToClipboard(
      _ item: TMDBMediaItem,
      element: CopyParts = .folder,
      type: MediaType = .tv,
      uhd: Bool = false
    ) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch element {
        case .folder:
            pasteboard.setString("\(item.plexTitle.replacingColonsWithDashes)", forType: .string)
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.nameCopy))?.play()
        case .id:
            pasteboard.setString(String(item.id), forType: .string)
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.idCopy))?.play()
        case .name:
            pasteboard.setString(String(item.displayTitle), forType: .string)
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.nameCopy))?.play()
        case .updatePoster:
          pasteboard.setString(updatePoster(for: item, type: type, uhd: uhd), forType: .string)
            _ = NSSound(named: NSSound.Name(Constants.App.Sounds.idCopy))?.play()
        }
    }
    
    private func updatePoster(
      for item: TMDBMediaItem,
      type: MediaType,
      uhd: Bool
    ) -> String {
        var library = ""
        
        switch type {
        case .tv:
            library = Constants.Media.Types.shows
        case .movie:
            library = Constants.Media.Types.movies
        case .collection:
            library = Constants.Media.Types.movies
        }
        
        return """
        \(Constants.Media.UpdatePoster.script) "\(item.plexTitle.replacingColonsWithDashes)" \
        \(Constants.Media.UpdatePoster.library) \(library)\(uhd ? "4k" : "")\
        \(type == .collection ? " \(Constants.Media.UpdatePoster.collection)" : "")
        """
    }

}
