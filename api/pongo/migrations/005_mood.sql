-- How each track's audio sounds, measured once from the audio itself (see
-- library/track/mood.py): its tempo in BPM, and energy, positivity (valence) and
-- danceability from 0 to 1, which the mood is worked out from. NULL if it
-- couldn't be measured, and mood_checked says whether it was tried.
ALTER TABLE audio
    ADD COLUMN IF NOT EXISTS tempo real,
    ADD COLUMN IF NOT EXISTS energy real,
    ADD COLUMN IF NOT EXISTS valence real,
    ADD COLUMN IF NOT EXISTS danceability real,
    ADD COLUMN IF NOT EXISTS mood_checked boolean NOT NULL DEFAULT false;
