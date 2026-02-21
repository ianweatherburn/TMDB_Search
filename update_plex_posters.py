#!/usr/bin/env python3

import os
import sys
import argparse
import configparser
import textwrap
import re
import shlex
from plexapi.server import PlexServer

#------------------------------------------------------------------------------
class Constants:
    DEFAULTS = 'DEFAULTS'
    SERVERS = "servers"
    ALL_SERVERS = "all_servers"
    LIBRARIES = "libraries"
    LIBRARY_MAPPINGS = "library_mappings"
    METADATA_PATH_PREFIX = "metadata_path_prefix"
    METADATA_MAPPINGS = "metadata_mappings"

    RED = "\033[31m"
    RESET = "\033[0m"

#------------------------------------------------------------------------------
class NumberRange:
    def __init__(self, range_str):
        """
        Parse a range string in the format 'n' or 'n..m'
        Examples: '5' -> [5], '5..8' -> [5,6,7,8]
        """
        if range_str is None:
            self.numbers = None
            return
            
        if '..' in range_str:
            start, end = map(int, range_str.split('..'))
            self.numbers = list(range(start, end + 1))
        else:
            self.numbers = [int(range_str)]
    
    def contains(self, number):
        """Check if a number is in the range"""
        if self.numbers is None:
            return True
        return number in self.numbers
    
    def __bool__(self):
        """Return True if range is specified"""
        return self.numbers is not None

#------------------------------------------------------------------------------
class ServerDetails:
    def __init__(self, url, token):
        self.url = url
        self.token = token
    def __repr__(self):
        return f"ServerDetails(url={self.url}, token={self.token})"

#------------------------------------------------------------------------------
class AppConfig:
    def __init__(self, args):
        self.config, self.config_path = self._load_config()

        # The default servers to update, otherwise the server passed in the command-line
        self.servers = self._get_servers(args)
        # Get the Plex endpoints and API tokens required to make API calls for each of our Plex servers
        self.server_details = self._load_server_details(self.servers)
        # The default libraries to update, otherwise the library passed in the command-line
        self.libraries = self._get_libraries(args)
        # The mapping to the Plex library names to simplify the command-line, ie 'shows4k', instead of 'Shows 4K' being required
        self.library_mappings = dict(item.split(':') for item in self.config[Constants.DEFAULTS].get(Constants.LIBRARY_MAPPINGS).split(','))
        # The default path prefix to prefix the library and source folder, unless explicitly ignore with the command-line option
        self.metadata_path_prefix = self._get_metadata_path_prefix(args)
        # Map the library-name to a metadata path where the posters are found (ie shows4k and movies4k posters are found in the same folder as shows and movies)
        self.metadata_mappings = dict(item.split(':') for item in self.config[Constants.DEFAULTS].get(Constants.METADATA_MAPPINGS).split(','))
        # Do not try and match on {{tmdb-id}} in the filename, on Plex
        self.ignore_tmdb = args.ignore_tmdb
        # Override the Plex title to search for, instead of deriving it from the folder-name
        self.title_override = args.plex_title
        # Override the Plex year to search for, instead of deriving it from the folder-name
        self.year_override = args.plex_year
        # Season number range to filter by (if provided)
        self.season_range = NumberRange(args.season)
        # Episode number range to filter by (if provided)
        self.episode_range = NumberRange(args.episode)
        # Collection mode - update collections instead of media items
        self.collection_mode = args.collection

    def _load_config(self):
        script_path = os.path.abspath(__file__)
        script_dir, script_name = os.path.dirname(script_path), os.path.splitext(os.path.basename(script_path))[0]
        path = os.path.join(script_dir, f"{script_name}.conf")
        config = configparser.ConfigParser()
        config.read(path)
        return config, path

    def _get_servers(self, args):
        if args.servers:
            servers = [server.upper() for server in args.servers.split(",")]
        elif args.all_servers:
            servers = self.config[Constants.DEFAULTS].get(Constants.ALL_SERVERS, '').split(",")
        else:
            servers = self.config[Constants.DEFAULTS].get(Constants.SERVERS, '').split(",")
        return servers if isinstance(servers, list) else [servers]

    def _get_libraries(self, args):
        libraries = (
            [library.lower() for library in args.libraries.split(',')] if args.libraries
            else self.config[Constants.DEFAULTS].get(Constants.LIBRARIES).split(',')
        )
        return libraries

    def _get_metadata_path_prefix(self, args):
        path = (
            "" if args.ignore_path
            else self.config[Constants.DEFAULTS].get(Constants.METADATA_PATH_PREFIX)        
        )
        return path

    def _load_server_details(self, servers):
        server_details = {}
        for server in servers:
            # print(f"Getting server details for '{server}' in '{servers}'")
            url = self.config[server].get('url')
            token = self.config[server].get('token')
            server_details[server] = ServerDetails(url, token)
        return server_details

#------------------------------------------------------------------------------
def parse_folder_name(folder):
    # Regular expressions to find the parts
    title_pattern = r"^(.*?)(?=\(\d{4}\))"
    year_pattern = r"\((\d{4})\)"
    tmdb_pattern = r"\{tmdb-(\d+)\}"
    
    # Extract title, year, and tmdb-id
    title_match = re.search(title_pattern, folder)
    year_match = re.search(year_pattern, folder)
    tmdb_match = re.search(tmdb_pattern, folder)
    
    title = title_match.group(0).strip() if title_match else None
    year = year_match.group(1) if year_match else None
    tmdb_id = tmdb_match.group(1) if tmdb_match else None
    
    # Matching titles in Plex usually means that the title has a colon where a hyphen is in the file-name
    # Replace only the first occurrence of ' - ' or '- ' with a ": "
    # This can still be over-ridden with the --plex-title command-line argument
    if title:
        title = re.sub(r'^(.*?)( - |- )', r'\1: ', title, count=1)
    
    return {
        "title": title,
        "year": year,
        "tmdb_id": tmdb_id
    }

#------------------------------------------------------------------------------
def parse_arguments():
    # print(f"parse_arguments()")
    parser = argparse.ArgumentParser(
        description="Update Plex media with image asset metadata",
        epilog=textwrap.dedent("""\
            Example Usage:
            update_plex_posters.py 'shows/Special Ops - Lioness (2023) {tmdb-113962}' -l shows -a -pt 'Special Ops: Lioness'
            update_plex_posters.py 'movies/2 Fast 2 Furious (2003) {tmdb-584} -l movies -a
            update_plex_posters.py 'shows/2 Broke Girls (2011) {tmdb-39340} -l shows -s ISENGARD
            update_plex_posters.py '/home/iwadmin/downloads/posters/Test' -l movies -ir -pt 'Test: Movie' -py 2024 -a
            update_plex_posters.py 'Yellowstone (2018) {tmdb-73586}'' -l shows4k -pt 'Yellowstone' -py 2018 -n 01..05
            update_plex_posters.py 'Marvel Collection' -l movies --collection -pt 'Marvel Cinematic Universe'
        """),
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("folders", nargs="+", help="One or more folder names containing posters")
    parser.add_argument("--config", default="", help="Configuration file name")
    parser.add_argument("-s", "--servers", help="Plex server name(s), comma-separated")
    parser.add_argument("-l", "--libraries", help="Library name(s) to update, comma-separated")
    parser.add_argument("-n", "--season", help="Season number (e.g., '5' or '5..8' for range)")
    parser.add_argument("-e", "--episode", help="Episode number (e.g., '3' or '1..10' for range)")
    parser.add_argument("-a", "--all_servers", action="store_true", help="Update all servers defined in the config")
    parser.add_argument("-ip", "--ignore_path", action="store_true", help="Do not add the prefix the folder with a default metadata path")
    parser.add_argument("-it", "--ignore_tmdb", action="store_true", help="Do not try and match on {{tmdb-id}} in the filename, on Plex")
    parser.add_argument("-pt", "--plex_title", help="Override the Plex title to search for, instead of deriving it from the folder-name")
    parser.add_argument("-py", "--plex_year", help="Override the Plex year to search for, instead of deriving it from the folder-name")
    parser.add_argument("-c",  "--collection", action="store_true", help="Update collections instead of media items")
    return parser.parse_args()

#------------------------------------------------------------------------------
def connect_to_server(url, token):
    # print(f"connect_so_server('{url}','{token}')")
    return PlexServer(url, token)

#------------------------------------------------------------------------------
def update_poster(item, path, background=False, squareArt=False, clearLogo=False):
    match True:
        case _ if background:
            item.uploadArt(filepath=path)
        case _ if squareArt:
            # item.uploadSquareArt(filepath=path)
            print(f"squareArt not implemented yet for {path}")
        case _ if clearLogo:
            item.uploadLogo(filepath=path)
        case _:
            item.uploadPoster(filepath=path)

#------------------------------------------------------------------------------
def show_progress(server_name, library_name, title, path):
    print(f"Updated asset for 'Plex ({server_name})/{library_name}/{title}' to '{path}'")    

#------------------------------------------------------------------------------
def asset_path(folder, library, config):
    # print(f"asset_path('{folder}', '{library}', '{config.metadata_mappings.get(library)}'")
    return os.path.abspath(os.path.join(config.metadata_path_prefix, config.metadata_mappings.get(library), folder))

#------------------------------------------------------------------------------
def image_path(path, file):
    return os.path.abspath(os.path.join(path, file))

#------------------------------------------------------------------------------
def update_collection_assets(server_name, library_name, library, folder, config):
    """Update collection poster and background assets"""
    
    def update_collection_poster_assets(collection):
        image = next((f for f in os.listdir(_asset_path) if f.startswith("poster.")), None)
        if image:
            path = image_path(_asset_path, image)
            show_progress(server_name, library_name, f"Collection: {title}", path)
            update_poster(collection, path)

    def update_collection_background_assets(collection):
        image = next((f for f in os.listdir(_asset_path) if f.startswith(("fanart.", "background.", "backdrop."))), None)
        if image:
            path = image_path(_asset_path, image)
            show_progress(server_name, library_name, f"Collection: {title}/background", path)
            update_poster(collection, path, background=True)

    _asset_path = asset_path(folder, library_name, config)
    
    # Parse the folder name to get the collection title
    folder_details = parse_folder_name(folder)
    title = config.title_override or folder_details["title"] or os.path.basename(folder)
    
    # Search for the collection
    collection = plex_collection_search(server_name, library_name, library, title)
    
    if collection:
        update_collection_poster_assets(collection)
        update_collection_background_assets(collection)
    else:
        print(f"{Constants.RED}Plex ({server_name}) could NOT find collection '{title}' in library '{library_name}'{Constants.RESET}", file=sys.stderr)

#------------------------------------------------------------------------------
def update_assets(server_name, library_name, library, folder, config):

    #------------------------------------------------------------------------------
    def update_poster_assets(plex_item):
        image = next((f for f in os.listdir(_asset_path) if f.startswith("poster.")), None)
        if image:
            path = image_path(_asset_path, image)
            show_progress(server_name, library_name, title, path)
            update_poster(plex_item, path)

    #------------------------------------------------------------------------------
    def update_background_assets(plex_item):
        image = next((f for f in os.listdir(_asset_path) if f.startswith(("fanart.", "background.", "backdrop."))), None)
        if image:
            path = image_path(_asset_path, image)
            show_progress(server_name, library_name, f"{title}/background", path)
            update_poster(plex_item, path, background=True)

    #------------------------------------------------------------------------------
    def update_squareart_assets(plex_item):
        image = next((f for f in os.listdir(_asset_path) if f.startswith(("square.", "squareArt."))), None)
        if image:
            path = image_path(_asset_path, image)
            show_progress(server_name, library_name, f"{title}/squareart", path)
            update_poster(plex_item, path, squareArt=True)  

    #------------------------------------------------------------------------------
    def update_clearlogo_assets(plex_item):
        image = next((f for f in os.listdir(_asset_path) if f.startswith(("clearlogo.", "logo."))), None)
        if image:
            path = image_path(_asset_path, image)
            show_progress(server_name, library_name, f"{title}/clearlogo", path)
            update_poster(plex_item, path, clearLogo=True)            

    #------------------------------------------------------------------------------
    def update_season_posters(plex_item):
        def season_filter(f):
            # Base conditions for season posters
            is_season_file = f.startswith("Season") and f.endswith((".jpg", ".jpeg", ".png"))
            
            if not is_season_file:
                return False
                
            # If season range is specified, check if the file matches
            season_num = int(f[6:8])  # Extract season number from filename
            return not config.season_range or config.season_range.contains(season_num)

        for image in filter(season_filter, os.listdir(_asset_path)):
            season_num = int(image[6:8])
            season = next((s for s in plex_item.seasons() if s.index == season_num), None)
            if season:
                path = image_path(_asset_path, image)
                show_progress(server_name, library_name, f"{title}/Season {season_num:02}", path)
                update_poster(season, path)

    #------------------------------------------------------------------------------
    def update_episode_posters(plex_item):
        def episode_filter(f):
            # Base conditions for episode files
            is_episode_file = f.startswith("S") and "E" in f and f.endswith((".jpg", ".jpeg", ".png"))
            
            if not is_episode_file:
                return False
                
            season_num = int(f[1:3])
            episode_num = int(f[4:6])
            
            # Check if season number matches (if specified)
            if config.season_range and not config.season_range.contains(season_num):
                return False
                
            # Check if episode number matches (if specified)
            if config.episode_range and not config.episode_range.contains(episode_num):
                return False
                
            return True

        for image in filter(episode_filter, os.listdir(_asset_path)):
            season_num = int(image[1:3])
            episode_num = int(image[4:6])
            episode = next((e for e in plex_item.episodes() if e.seasonNumber == season_num and e.index == episode_num), None)
            if episode:
                path = image_path(_asset_path, image)
                show_progress(server_name, library_name, f"{title}/Season {season_num:02}/S{season_num:02}E{episode_num:02}", path)
                update_poster(episode, path)

    # print(f"update_assets('{server_name}', '{library_name}', '{library}', '{folder}')")
    _asset_path = asset_path(folder, library_name, config)

    # title, year, tmdb_id = parse_folder_name(folder)
    folder_details = parse_folder_name(folder)

    # Parse the file details and over-write depending on the command-line options
    title = config.title_override or folder_details["title"]
    year = config.year_override or folder_details["year"]
    tmdb_id = None if config.ignore_tmdb else folder_details["tmdb_id"]

    plex_item = plex_search(server_name, library_name, library, title, year, tmdb_id)

    if plex_item:
        if not config.season_range and not config.episode_range:
            # Don't update the show poster and background if a season or episode update has been requested
            update_poster_assets(plex_item)
            update_squareart_assets(plex_item)
            update_clearlogo_assets(plex_item)
            update_background_assets(plex_item)
        if plex_item.type == 'show':
            # Don't update the show poster if an episode update has been requested
            update_season_posters(plex_item)
            update_episode_posters(plex_item)
    else:
        print(f"{Constants.RED}Plex ({server_name}) search could NOT find matching item for '{title} ({year}){f' {{tmdb-{tmdb_id}}}' if tmdb_id else ''}' in library '{library_name}'{Constants.RESET}", file=sys.stderr)

#------------------------------------------------------------------------------
def plex_collection_search(server_name, library_name, library, title):
    """Search for collections in the specified library"""
    print(f"plex_collection_search('Plex ({server_name})/{library_name}','{title}')")
    
    try:
        # Get all collections from the library
        collections = library.collections()
        
        # Search for collection by title (case-insensitive)
        for collection in collections:
            if collection.title.lower() == title.lower():
                return collection
        
        # If exact match not found, try partial match
        for collection in collections:
            if title.lower() in collection.title.lower():
                return collection
                
    except Exception as e:
        print(f"Error searching collections: {str(e)}", file=sys.stderr)
    
    return None

#------------------------------------------------------------------------------
def plex_search(server_name, library_name, library, title, year, tmdb_id):
    print(f"plex_search('Plex ({server_name})/{library_name}','{title}', '{year}', '{tmdb_id}')")

    items = library.search(title=title, year=year)
    
    for item in items:
        if item.type == 'movie':
            media_items = item.media
        elif item.type == 'show':
            media_items = []
            for episode in item.episodes():
                media_items.extend(episode.media)
        else:
            print(f"Unsupported item type: {item.type}", file=sys.stderr)
            continue
        
        if tmdb_id:
            for media in media_items:
                for part in media.parts:
                    file_path = part.file
                    if tmdb_id and f"{{tmdb-{tmdb_id}}}" in file_path:
                        # print(f"Item to return: '{item}'")
                        return item
        else:
            return item

    return None

#------------------------------------------------------------------------------
def main():
    args = parse_arguments()
    config = AppConfig(args)

    # print(f"Config: '{config.config_path}'")
    # print(f"Servers: '{config.servers}'")
    # print(f"Libraries: '{config.libraries}'")
    # print(f"Library Mappings: '{config.library_mappings}'")
    # print(f"Metadata Path-Prefix: '{config.metadata_path_prefix}'")
    # print(f"Metadata Mappings: '{config.metadata_mappings}'")
    # print(f"Ignore TMDB-Id: '{config.ignore_tmdb}'")
    # print(f"Plex Title Override: '{config.title_override}'")
    # print(f"Plex Year Override: '{config.year_override}'")
    # print(f"Collection Mode: '{config.collection_mode}'")
    # print(f"Server details: {config.server_details}")

    for server_name, server in config.server_details.items():
        try:
            # print(f"Connecting to 'Plex ({server_name})'")
            plex = connect_to_server(server.url, server.token)

            for library_name in config.libraries:
                # print(f"Library mapping lookup for '{library_name}' -> {config.library_mappings.get(library_name)}")
                library = plex.library.section(config.library_mappings.get(library_name))
                # print(f"Process 'Plex({server_name})/{library_name}' for Library '{library}'")

                for folder in args.folders:
                    # print(f"Processing Asset Folder: '{asset_path(folder, library_name, config)}'")
                    if config.collection_mode:
                        update_collection_assets(server_name, library_name, library, folder, config)
                    else:
                        update_assets(server_name, library_name, library, folder, config)

        except Exception as e:
            print(f"{Constants.RED}Error connecting to Plex ({server_name}): {str(e)}{Constants.RESET}", file=sys.stderr)

#------------------------------------------------------------------------------
if __name__ == "__main__":
    main()