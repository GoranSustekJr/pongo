#!/bin/sh
set -e

# yt-dlp is pinned in requirements.txt and updated by rebuilding with a newer pin.
# Opting in installs the newest release at every start instead, which only works
# without the read-only filesystem in docker-compose.yml.
if [ "${YTDLP_AUTO_UPDATE:-false}" = "true" ]; then
    pip install --quiet --no-cache-dir --user --upgrade 'yt-dlp[default]' \
        || echo "yt-dlp update failed, continuing with the installed version"
fi

# One worker: in-progress downloads are tracked in memory
exec uvicorn main:app --host 0.0.0.0 --port 8081 --proxy-headers
