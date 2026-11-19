-- Emails allowed to sign in, besides ALLOWED_EMAILS; scripts/enable_user.sh adds to it.
-- Sign-ins from other emails are refused without storing anything.
CREATE TABLE IF NOT EXISTS allowed_emails (
    email  text PRIMARY KEY,
    added  timestamptz NOT NULL DEFAULT now()
);
INSERT INTO allowed_emails (email)
SELECT DISTINCT lower(email) FROM users WHERE NOT disabled AND email IS NOT NULL
ON CONFLICT DO NOTHING;

-- Refresh tokens carry the device's current version; renewing moves it on, so an
-- older token being used again means it was copied, and the device is signed out.
ALTER TABLE user_device
    ADD COLUMN IF NOT EXISTS refresh_version integer NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS refresh_rotated_at timestamptz;
