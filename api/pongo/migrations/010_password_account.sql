-- Accounts that sign in with a username and password instead of Google or Apple
CREATE TABLE IF NOT EXISTS password_account (
    uid       text PRIMARY KEY REFERENCES users(uid) ON DELETE CASCADE,
    username  text NOT NULL UNIQUE,  -- lower case
    hash      text NOT NULL,         -- scrypt$n$r$p$salt$key
    changed   timestamptz NOT NULL DEFAULT now()
);
