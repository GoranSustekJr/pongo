-- Deezer's similar artists of each artist, kept so grouping a library's artists
-- into scenes doesn't ask Deezer again for every one.
CREATE TABLE IF NOT EXISTS artist_related (
    artist_id  text PRIMARY KEY,
    related    text[] NOT NULL,
    fetched_at timestamptz NOT NULL DEFAULT now()
);
