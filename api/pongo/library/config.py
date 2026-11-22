import os
from pathlib import Path


def _csv(name: str) -> set[str]:
    return {v.strip().lower() for v in os.getenv(name, "").split(",") if v.strip()}


DATABASE_URL = os.environ["DATABASE_URL"]
JWT_SECRET = os.environ["JWT_SECRET"]
JWT_ISSUER = os.getenv("JWT_ISSUER", "pongo")

# Google sign in
IOS_CLIENT_ID = os.getenv("IOS_CLIENT_ID", "")
WEB_CLIENT_ID = os.getenv("WEB_CLIENT_ID", "")
DESKTOP_CLIENT_ID = os.getenv("DESKTOP_CLIENT_ID", "")

# Apple sign in
APPLE_KEY_ID = os.getenv("APPLE_KEY_ID", "")
APPLE_TEAM_ID = os.getenv("APPLE_TEAM_ID", "")
APPLE_CLIENT_ID = os.getenv("APPLE_CLIENT_ID", "")
APPLE_PRIVATE_KEY_PATH = os.getenv("APPLE_PRIVATE_KEY_PATH", "")

# Accounts with these emails are enabled on first sign in, all others start disabled
ALLOWED_EMAILS = _csv("ALLOWED_EMAILS")

DATA_DIR = Path(os.getenv("DATA_DIR", "/data"))
AUDIO_DIR = DATA_DIR / "audio"
TEMP_DIR = DATA_DIR / "tmp"

# Behind Caddy (docker-compose.public.yml), Caddy sends the audio files and the API
# only checks the request and names the file in the X-Pongo-Audio header
SERVE_AUDIO_VIA_PROXY = os.getenv("SERVE_AUDIO_VIA_PROXY", "false").lower() == "true"

MAX_CONCURRENT_DOWNLOADS = int(os.getenv("MAX_CONCURRENT_DOWNLOADS", "4"))
# YouTube clients yt-dlp tries in order, the last one also on failure; "default" lets yt-dlp choose
YTDLP_PLAYER_CLIENTS = [
    v.strip() for v in os.getenv("YTDLP_PLAYER_CLIENTS", "visionos,default").split(",") if v.strip()
]
YTDLP_COOKIES_FILE = os.getenv("YTDLP_COOKIES_FILE", "")

# Rate limits per client IP, and new downloads per user
SIGN_INS_PER_MINUTE = int(os.getenv("SIGN_INS_PER_MINUTE", "10"))
REQUESTS_PER_MINUTE = int(os.getenv("REQUESTS_PER_MINUTE", "600"))
SOCKETS_PER_MINUTE = int(os.getenv("SOCKETS_PER_MINUTE", "120"))
DOWNLOADS_PER_HOUR = int(os.getenv("DOWNLOADS_PER_HOUR", "200"))
# Playlist imports: shared links read, and songs matched to the catalog, per user
IMPORT_LINKS_PER_HOUR = int(os.getenv("IMPORT_LINKS_PER_HOUR", "120"))
IMPORT_SONGS_PER_HOUR = int(os.getenv("IMPORT_SONGS_PER_HOUR", "20000"))
# Most songs one match request may ask for
MAX_IMPORT_BATCH = 50
# Most tracks one queue request may ask for
MAX_BATCH_TRACKS = 500
