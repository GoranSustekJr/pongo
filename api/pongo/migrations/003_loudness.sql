-- Integrated loudness of each track's audio in LUFS, measured once with ffmpeg's
-- ebur128 filter; the app turns loud tracks down to match. NULL if it couldn't
-- be measured, and loudness_checked says whether it was tried.
ALTER TABLE audio
    ADD COLUMN IF NOT EXISTS loudness real,
    ADD COLUMN IF NOT EXISTS loudness_checked boolean NOT NULL DEFAULT false;
