#!/bin/sh
set -e

# YouTube changes often and old yt-dlp versions stop working, so stay current
if [ "${YTDLP_AUTO_UPDATE:-true}" = "true" ]; then
    pip install --quiet --no-cache-dir --user --upgrade 'yt-dlp[default]' \
        || echo "yt-dlp update failed, continuing with the installed version"
fi

# One worker: in-progress downloads are tracked in memory
exec uvicorn main:app --host 0.0.0.0 --port 8081 --proxy-headers
