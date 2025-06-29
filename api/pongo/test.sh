#!/bin/bash

# URL of the YouTube playlist page (replace with your playlist URL)
URL="https://www.youtube.com/watch?v=gqCBnW1KMdo&list=RD8p-Uyh0xG5U&index=1"

# Fetch the page content using curl
PAGE_CONTENT=$(curl -s "$URL")

# Use grep to filter video URLs inside the "items" div, ignoring extra parameters like list and index
VIDEO_URLS=$(echo "$PAGE_CONTENT" | grep -o 'https://www.youtube.com/watch?v=[^"]*' | sed 's/\/watch?v=//g' | uniq)

# Check if any video URLs were found
if [ -z "$VIDEO_URLS" ]; then
    echo "No video URLs found."
else
    echo "Extracted Video IDs:"
    for video_url in $VIDEO_URLS; do
        # Remove unwanted parts (like "list=", "index=") from the URLs
        if [[ ! "$video_url" =~ "list=" && ! "$video_url" =~ "index=" ]]; then
            echo "$video_url"
        fi
    done
fi

