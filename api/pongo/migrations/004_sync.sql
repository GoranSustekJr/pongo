-- Each user's library (favourites, playlists, history, alarms, ...), one row per item.
-- The latest change to an item wins; deleted items keep a row with data NULL so the
-- deletion reaches the user's other devices. seq orders changes for pulling.
CREATE SEQUENCE IF NOT EXISTS sync_seq;

CREATE TABLE IF NOT EXISTS sync_item (
    uid         text NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    kind        text NOT NULL,
    key         text NOT NULL,
    data        jsonb,
    changed_at  timestamptz NOT NULL,
    seq         bigint NOT NULL DEFAULT nextval('sync_seq'),
    PRIMARY KEY (uid, kind, key)
);

CREATE INDEX IF NOT EXISTS sync_item_uid_seq_idx ON sync_item (uid, seq);
