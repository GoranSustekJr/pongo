#!/bin/bash
# this script is not based off of any other work by anyone else,
# nor is it made in association with anyone else, regardless of
# their claims.

# dependencies: mpv yt-dlp grep (GNU grep)

# NOTE:  if you dont have GNU grep you can replace grep with rg

# explain usage
function usage () {
  echo "usage: yt"
  echo "    -h        help"
  echo "    -s query  search"
  echo
  echo "example usage:"
  echo "yt -s 'your search query'"
  exit 0
}

# no args -> show usage
if [[ ${#} -eq 0 ]]; then
    usage
fi

# available flags
optstring=":s:h"

defaction="s"
query=""

# if not using defaults search for flags
while getopts ${optstring} arg; do
    case "${arg}" in
        s)
            # search in youtube for a query
            action="s"
            query="${OPTARG}" ;;
        h)
            # display help / usage
            usage ;;
        \?)
            # wrong args -> exit with explanation of usage
            echo "invalid option: -${OPTARG}"
            echo
            usage ;;
        :)
            # missing args -> exit with explanation of usage
            echo "Option -${OPTARG} needs an argument"
            echo
            usage ;;
    esac
done

# if no query is set with flags then ask for one
if [ -z "$query" ]; then
    # ask for a query
    echo -n "Search: "
    read -r query
fi

# program cancelled -> exit
if [ -z "$query" ]; then exit; fi

# clean query
query=$(sed \
  -e 's|+|%2B|g'\
  -e 's|#|%23|g'\
  -e 's|&|%26|g'\
  -e 's|"|%22|g'\
  -e 's| |+|g' <<< "$query")

# search and get video results
response=$(curl -s "https://www.youtube.com/results?search_query=$query" | sed 's|\\.||g')

# if unable to fetch the youtube results page, inform and exit
if ! grep -q "script" <<< "$response"; then echo "unable to fetch yt"; exit 1; fi

# regex expression to match video entries from yt result page
vgrep='"videoRenderer":{"videoId":"\K.{11}".+?"text":".+?[^\\](?=")'

# function to get results based on regex
getresults() {
    grep -oP "$1" <<< "$response" | awk -F\" '{ print $1 }'
}

# get the first video id
first_video_id=$(getresults "$vgrep" ) #| head -n 1)

# Print the ID of the first video
if [ -n "$first_video_id" ]; then
    echo "$first_video_id"
else
    echo "No videos found."
fi
