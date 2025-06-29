from collections import deque
import itertools
from dotenv import load_dotenv
import os, json

# Load .env
load_dotenv()

# Get .env vars
raw_keys = os.getenv('SPOTIFY_API_KEYS', '[]')
api_keys = json.loads(raw_keys)

MAX_REQUESTS_PER_WINDOW = 75 

# Track API key usage
key_iterator = itertools.cycle(api_keys)


def get_api_key():
    """Get an API key with round-robin load balancing."""
    return next(key_iterator)
