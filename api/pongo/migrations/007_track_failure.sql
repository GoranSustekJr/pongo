-- Why the server couldn't download a track the last time it tried, so apps can show it.
CREATE TABLE IF NOT EXISTS track_failure (
    stid      text PRIMARY KEY,
    reason    text NOT NULL,  -- no_match, catalog or download
    failed_at timestamptz NOT NULL DEFAULT now()
);
