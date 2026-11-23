-- Pongo's first tables. The API creates them on a new database; servers set up
-- before this was a migration got them from database/init, so nothing here may fail
-- when they exist.
-- Audio bytes live on the audio volume; the database only stores where they are.

CREATE TABLE IF NOT EXISTS users (
    uid          text PRIMARY KEY,
    email        text,
    created      timestamptz NOT NULL DEFAULT now(),
    name         text,
    picture      text,
    max_devices  integer NOT NULL DEFAULT 3,
    apple_auth   boolean NOT NULL DEFAULT false,
    hidden_auth  boolean NOT NULL DEFAULT false,
    disabled     boolean NOT NULL DEFAULT true  -- invite-only: see ALLOWED_EMAILS
);

CREATE TABLE IF NOT EXISTS user_device (
    uid        text NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    device_id  text NOT NULL,
    last_seen  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (uid, device_id)
);

CREATE TABLE IF NOT EXISTS audio (
    auid          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sha256        char(64) NOT NULL UNIQUE,
    path          text NOT NULL,
    size_bytes    bigint NOT NULL,
    created       timestamptz NOT NULL DEFAULT now()
);

-- stid is the metadata provider's track id (Deezer).
CREATE TABLE IF NOT EXISTS track (
    stid         text PRIMARY KEY,
    ytvid        varchar(15) NOT NULL,
    auid         bigint NOT NULL REFERENCES audio(auid),
    duration     double precision NOT NULL,
    title        text,
    artists      text,
    isrc         text,
    match_score  real,
    created      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS track_ytvid_idx ON track (ytvid);
CREATE INDEX IF NOT EXISTS track_auid_idx ON track (auid);
