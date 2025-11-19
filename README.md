![TMDB Search App](https://github.com/ianweatherburn/TMDB_Search/blob/main/TMDBSearch/Resources/Screenshots/TMDB-Search-About.png)

![Release](https://img.shields.io/github/v/release/ianweatherburn/TMDB_Search.svg?label=Release)
![Swift](https://img.shields.io/badge/Swift-6.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2010.12%2B-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

# TMDB Search

## What is TMDB Search

TMDB Search is a macOS application that enables users to search and browse The Movie Database (TMDB) for movies, TV shows, and collections. The app is designed to help users discover detailed metadata and high-quality artwork, saving them for use in media libraries such as Plex or Kometa, and assisting with media organization workflows like Filebot renaming and import.

## Features

- 🔍 **Search TMDB**: Quickly search for movies, TV shows, or collections using TMDB's rich database.
- 📝 **Detailed Metadata**: View comprehensive details for each media item, including titles, overviews, release dates, genres, cast, and TMDB-compliant folder names.
- 🎨 **Artwork Browsing**: Browse a grid of posters and backdrops for any show, movie, or collection, preview with high-resolution images.
- 💾 **Artwork Download**: Save selected posters and backdrops to your asset metadata folder, ready for import into media managers such as Plex or Kometa.
- 🗂️ **TMDB Folder Name & ID**: Retrieve TMDB-compliant folder names and TMDB-IDs for each media item. Use these identifiers in workflows such as Filebot renaming.
- 📤 **Export for Media Libraries**: Prepare and organize artwork and metadata for seamless integration with Plex, Kometa, or other media asset tools.
- 🕑 **Search History**: Easily revisit previous searches and manage your search history.
- 🟦 **Customizable Grid**: Adjust the grid layout for artwork browsing to fit your preferences.

## Use Cases

- Locating and saving official TMDB artwork for your personal media collection.
- Organizing your Plex or Kometa asset folders with matching folder names and images.
- Exporting TMDB-IDs for use in batch renaming or automation tools like Filebot.
- Researching metadata details for movies, shows, or collections.

## Shortcuts

### Search Result Shortcuts
Keyboard shortcuts for each search result row-item, or use the control button. _Tap refers to a left-mouse click on the row_.

| Shortcut | Feature |
|----------|---------|
| Tap      | Copy the media name, followed by the year (ie, "The Matrix (1999)")) |
| ⌘+Tap    | Copy the media name only without the year (ie, "The Matrix") |
| ⌥+Tap    | Copy the media TMDB-ID (ie, 603) |
| ⌃+Tap    | Copy the update-poster script command (ie, upp "The Matrix (1999)" -l movies")

### Poster and Backdrop Shortcuts

| Shortcut | Feature |
|----------|---------|
| Tap      | Save the image to the file-system |
| ⌥+Tap    | Flip the image horizontally first, before saving to the file-system |
                
## Screenshots

### Searching
| Movies | TV Shows |
|--------|----------|
| <img src="https://github.com/ianweatherburn/TMDB_Search/blob/main/TMDBSearch/Resources/Screenshots/TMDB-Search-Movies.png" alt="Movies" width="320"/> | <img src="https://github.com/ianweatherburn/TMDB_Search/blob/main/TMDBSearch/Resources/Screenshots/TMDB-Search-Shows.png" alt="TV Shows" width="320"/>

### Assets
| Posters | Backdrops |
|---------|-----------|
| <img src="https://github.com/ianweatherburn/TMDB_Search/blob/main/TMDBSearch/Resources/Screenshots/TMDB-Search-Posters.png" alt="Posters" width="320"/> | <img src="https://github.com/ianweatherburn/TMDB_Search/blob/main/TMDBSearch/Resources/Screenshots/TMDB-Search-Backdrops.png" alt="Backdrops" width="320"/>

## Requirements
| Platform        | Minimum Swift Version | Xcode       | Required Packages                   |
|----------------|----------------------|-------------|-------------------------------------|
| macOS 10.12+   | 6.0                  | 16.0        | SwiftLint Plugins 0.59.1+, SFSymbol 3.0.0+ |

## Installation

1. Clone this repository to your local machine:
   ```sh
   git clone TMDB_Search

