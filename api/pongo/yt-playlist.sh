#!/bin/bash
# dependencies: curl, grep, jq, awk

function usage () {
  echo "usage: yt-playlist"
  echo "    -h        help"
  echo "    -S query  search for playlists"
  echo
  echo "example usage:"
  echo "yt-playlist -S 'your search query'"
  exit 0
}

# no args -> show usage
if [[ $# -eq 0 ]]; then
    usage
fi

# available flags
optstring=":S:h"
query=""

while getopts ${optstring} arg; do
    case "${arg}" in
        S) query="${OPTARG}" ;;
        h) usage ;;
        \?) echo "invalid option: -${OPTARG}"; echo; usage ;;
        :) echo "Option -${OPTARG} needs an argument"; echo; usage ;;
    esac
done

# if no query is provided, show usage and exit
if [ -z "$query" ]; then
    echo "Error: No search query provided. Use -S to specify a query."
    usage
fi

# clean query for URL
query=$(sed -e 's|+|%2B|g' -e 's|#|%23|g' -e 's|&|%26|g' -e 's|"|%22|g' -e 's| |+|g' <<< "$query")
#query=$(jq -rn --arg q "$query" '$q|@uri')

# get YouTube search results
response=$(curl -s "https://www.youtube.com/results?search_query=$query")

# if unable to fetch the YouTube results page, inform and exit
if ! grep -q "script" <<< "$response"; then echo "unable to fetch yt"; exit 1; fi

# regex to match playlist IDs (excluding 'WL')
pgrep='"playlistId":"(?!WL)([A-Za-z0-9_-]+)"'
#pgrep='"playlistId":"(?!WL)([A-Za-z0-9_-]+)".*?"title":"([^"]+)"'

# function to get playlist results
getresults() {
    grep -oP "$1" <<< "$response" | sed -E 's/"playlistId":"([^"]+)"/\1/'
}

# get the first valid playlist ID
first_playlist_id=$(getresults "$pgrep" | head -n 1)

# Print the playlist link
if [ -n "$first_playlist_id" ]; then
    echo "$first_playlist_id"
else
    echo "No playlists found."
fi


    #echo "https://www.youtube.com/playlist?list=$first_playlist_id"
