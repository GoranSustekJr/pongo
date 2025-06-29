import jwt
import requests
import json
import time
from datetime import datetime, timedelta
from jwt.algorithms import RSAAlgorithm
from cryptography import x509
from cryptography.hazmat.primitives.serialization import pkcs7
import base64, re
from asn1crypto import cms
from iap_local_receipt import IAPReceiptVerifier
from dotenv import load_dotenv
import os

# Constants
APPLE_PUBLIC_KEY_URL = "https://appleid.apple.com/auth/keys"
APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token"
APPLE_PUBLIC_KEY = None
APPLE_KEY_CACHE_EXP = 60 * 60 * 24  # Cache Apple's public key for 24 hours
APPLE_LAST_KEY_FETCH = 0

# Load .env
load_dotenv()

# Apple Developer Info
KEY_ID = os.getenv("KEY_ID") 
TEAM_ID = os.getenv("TEAM_ID") # Team ID from Apple Developer account
CLIENT_ID = os.getenv("CLIENT_ID") # App's client ID
PRIVATE_KEY_PATH = os.getenv("PRIVATE_KEY_PATH")  # Path to .p8 file


# Fetch Apple's Public Key
def fetch_apple_public_key():
    global APPLE_LAST_KEY_FETCH, APPLE_PUBLIC_KEY

    if (APPLE_LAST_KEY_FETCH + APPLE_KEY_CACHE_EXP) < int(time.time()) or APPLE_PUBLIC_KEY is None:
        key_payload = requests.get(APPLE_PUBLIC_KEY_URL).json()
        APPLE_PUBLIC_KEY = RSAAlgorithm.from_jwk(json.dumps(key_payload["keys"][0]))
        APPLE_LAST_KEY_FETCH = int(time.time())

    return APPLE_PUBLIC_KEY


# Generate Client Secret
def generate_client_secret():
    with open(PRIVATE_KEY_PATH, "r") as f:
        private_key = f.read()

    headers = {
        "kid": KEY_ID,
        #"alg": "ES256",
    }
    payload = {
        "iss": TEAM_ID,
        "iat": datetime.now(),
        "exp": datetime.now() + timedelta(days=180),  
        "aud": "https://appleid.apple.com",
        "sub": CLIENT_ID,
    }

    client_secret = jwt.encode(payload, private_key, algorithm="ES256", headers=headers)
    return client_secret


# Exchange Authorization Code for Tokens
def exchange_code_for_token(authorization_code):
    client_secret = generate_client_secret()

    data = {
        "client_id": CLIENT_ID,
        "client_secret": client_secret,
        "code": authorization_code,
        "grant_type": "authorization_code",
        #"redirect_uri": REDIRECT_URI,
    }

    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    response = requests.post(APPLE_TOKEN_URL, data=data, headers=headers)


    if response.status_code != 200:
        raise Exception(f"Error exchanging token: {response.json()}")

    return response.json()


# Validate ID Token
def validate_id_token(id_token):

    try:
        decoded_token = jwt.decode(
            id_token,
            "",
            verify=False,
            options={"verify_signature": False},
            algorithms=["HS256"],
        )
        return decoded_token
    except jwt.ExpiredSignatureError:
        raise Exception("ID Token has expired.")
    except jwt.InvalidAudienceError:
        raise Exception("Invalid audience in ID Token.")
    except Exception as e:
        raise Exception(f"Error validating ID token: {e}")


# Full Flow: Retrieve User Info
def retrieve_user_info(authorization_code):
    # Exchange code for tokens
    token_response = exchange_code_for_token(authorization_code)

    # Extract ID Token
    id_token = token_response.get("id_token")

    if not id_token:
        raise Exception("No ID Token found in response.")

    # Validate ID Token
    user_info = validate_id_token(id_token)

    return user_info



