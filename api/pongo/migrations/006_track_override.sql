-- The YouTube video a user chose for a track when the matched one was the wrong
-- recording, such as a later re-recording with the same title and length. A
-- track downloaded again uses it instead of searching.
CREATE TABLE IF NOT EXISTS track_override (
    stid       text PRIMARY KEY,
    ytvid      varchar(15) NOT NULL,
    uid        text,
    chosen_at  timestamptz NOT NULL DEFAULT now()
);
