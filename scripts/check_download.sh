#!/bin/sh
# Downloads one song with the running server's yt-dlp to check YouTube still works,
# for example after updating yt-dlp: scripts/check_download.sh
set -e
docker compose exec -T api sh -c '
    cd /tmp && rm -rf check && mkdir check && cd check
    client=${YTDLP_PLAYER_CLIENTS:-visionos}
    yt-dlp --no-playlist --quiet --no-progress \
        --extractor-args "youtube:player_client=${client%%,*}" \
        -f "ba[ext=m4a]/ba" -o "audio.%(ext)s" "https://www.youtube.com/watch?v=J7p4bzqLvCw"
    size=$(stat -c %s audio.m4a)
    cd /tmp && rm -rf check
    echo "Download works with yt-dlp $(yt-dlp --version) ($size bytes)"
'
