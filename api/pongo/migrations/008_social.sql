-- Friends: people follow each other and the playlists they choose to show.

-- Each user's public ID, shared as an invite code; uids stay private
ALTER TABLE users ADD COLUMN IF NOT EXISTS friend_code text UNIQUE;

CREATE TABLE IF NOT EXISTS follow (
    uid       text NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    followee  text NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    created   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (uid, followee)
);
CREATE INDEX IF NOT EXISTS follow_followee_idx ON follow (followee);

-- The online playlists (sync_item keys) their owners show on their profile
CREATE TABLE IF NOT EXISTS shared_playlist (
    uid        text NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    key        text NOT NULL,
    shared_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (uid, key)
);

-- Others' shared playlists a user added to their library
CREATE TABLE IF NOT EXISTS playlist_follow (
    uid      text NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    owner    text NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    key      text NOT NULL,
    created  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (uid, owner, key)
);
CREATE INDEX IF NOT EXISTS playlist_follow_owner_idx ON playlist_follow (owner, key);
