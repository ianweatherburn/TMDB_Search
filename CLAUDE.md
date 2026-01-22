# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TMDB Search is a macOS application that enables users to search and browse The Movie Database (TMDB) for movies, TV shows, and collections. The app helps users discover detailed metadata and high-quality artwork, saving them for use in media libraries such as Plex or Kometa.

**Platform:** macOS 10.12+
**Language:** Swift 6.0
**Framework:** SwiftUI
**Required Packages:**
- SwiftLint Plugins 0.59.1+
- SFSymbol 3.0.0+

## Building and Running

```bash
# Open the project in Xcode
open "TMDB Search.xcodeproj"

# Build from command line
cd "/Users/ian/Developer/TMDB_Search"
xcodebuild -project "TMDB Search.xcodeproj" -scheme "TMDB Search" build

# Run SwiftLint
swiftlint lint --config .swiftlint.yml
```

## Architecture

### Core Components

**AppModel (`TMDBSearch/Models/AppModel/`)**: Central observable state manager split across extensions:
- `AppModel.swift`: Core state properties, TMDB service, and settings manager
- `AppModel+Search.swift`: Search functionality and window title management
- `AppModel+Image.swift`: Image loading and downloading operations
- `AppModel+Settings.swift`: Settings-related operations
- `AppModel+Clipboard.swift`: Clipboard operations for copying media information

**TMDBServices (`TMDBSearch/Services/TMDBServices.swift`)**: All TMDB API interactions
- Media search (movies/TV/collections)
- Image retrieval with language filtering
- Image downloading with optional horizontal flip
- Image size options: w92, w154, w185, w342, w500, w780, original

**SettingsManager (`TMDBSearch/Models/SettingsManager.swift`)**: Persists user preferences
- API keys stored securely in Keychain (TMDB API key, Plex token)
- User settings in UserDefaults (download path, grid size, search history)
- Manages search history with configurable maximum items

**UnifiedFileManager (`TMDBSearch/Services/UnifiedFileManager.swift`)**: Handles file system operations with security-scoped bookmarks for persistent access to user-selected directories (including network volumes)

### Constants Structure

All constants are organized in `TMDBSearch/Constants/` with namespaced enums:
- `Constants+App.swift`: App-level configuration (window sizes, menu items)
- `Constants+Services.swift`: API URLs and service configuration
- `Constants+Image.swift`: Image-related constants
- `Constants+Media.swift`: Media type constants
- `Constants+Configure.swift`: Configuration UI defaults

### View Architecture

**Main Scenes:**
- `TMDB_SearchApp.swift`: App entry point with MainWindowScene and SettingsScene
- `MainWindowScene.swift`: Primary search window
- `SettingsScene.swift`: Settings window

**View Organization:**
- `Views/Search/`: Search interface, results, media type selection, history
- `Views/Image/`: Image grid, gallery, and async image loading
- `Views/Configure/`: Settings UI components
- `Views/Helpers/`: Reusable UI helpers (loading states, empty states, status messages)

### Data Models

**TMDB Models (`TMDBSearch/Models/TMDB/`):**
- `TMDBMedia.swift`: Core media item model with MediaType enum (tv/movie/collection)
- `TMDBImage.swift`: Image metadata from TMDB API
- `TMDBSearchResponse.swift`: API response wrapper

**MediaType Enum:**
- `tv`: TV shows (uses `name` and `first_air_date`)
- `movie`: Movies (uses `title` and `release_date`)
- `collection`: Movie collections

**TMDBMediaItem Properties:**
- `displayTitle`: Unified title (handles both `title` and `name`)
- `displayYear`: Extracted year from release/air date
- `formattedTitle`: "Title (Year)" format
- `plexTitle`: "Title (Year) {tmdb-ID}" format for Plex integration

### Keyboard Shortcuts

**Search:**
- Return: Search for Shows
- Shift+Return: Search for Movies
- Option+Return: Search for Collections
- Cmd+Shift+H: Show Search History
- Cmd+Backspace: Clear Search
- Cmd+/: Show Help

**Search Results (row clicks):**
- Click: Copy "Title (Year)"
- Cmd+Click: Copy title only
- Option+Click: Copy TMDB ID
- Control+Click: Copy update-poster script command

**Image Grid:**
- Click: Save image to file system
- Option+Click: Flip image horizontally before saving

## Key Features

**Image Processing:**
- Images are downloaded from TMDB and can be optionally flipped horizontally
- Flipping preserves original format (JPEG/PNG) with lossless quality for PNG
- Files auto-increment if duplicates exist (e.g., poster.jpg, poster_1.jpg)

**Search History:**
- Automatically tracks searches by media type
- Removes duplicate entries (case-insensitive)
- Maintains configurable maximum history size
- Persisted in UserDefaults as JSON

**Security-Scoped Resources:**
- Uses bookmarks for persistent access to user-selected directories
- Supports both local and network volumes
- Automatically restores access on app launch

## Development Guidelines

**Code Organization:**
- Use extensions to split large models by functionality
- Group constants in namespaced enums
- Leverage SwiftUI's `@Observable` macro for state management
- Use `@MainActor` for UI-related async operations

**API Integration:**
- All TMDB API calls go through `TMDBServices`
- API key retrieved from Keychain via `SettingsManager.apiKey`
- Images sorted by area (width × height) in descending order
- Language filtering supports multiple languages + null

**SwiftLint Configuration:**
- Disabled: trailing_whitespace, todo, force_cast, force_try, large_tuple
- Enabled opt-in rules: file_name_no_space, multiline_literal_brackets, number_separator, operator_usage_whitespace, prefer_self_in_static_references, toggle_bool, unused_parameter
- Analyzer rules: explicit_self, unused_declaration, unused_import
- Minimum identifier length: 2 characters
