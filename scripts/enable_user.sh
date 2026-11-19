#!/bin/sh
# Allow an email to sign in, and enable its account if it already has one:
#   scripts/enable_user.sh someone@example.com
set -e
docker compose exec -T db psql -U pongo_user -d pongo_db -v ON_ERROR_STOP=1 -v email="$1" <<'SQL'
INSERT INTO allowed_emails (email) VALUES (lower(:'email')) ON CONFLICT DO NOTHING;
UPDATE users SET disabled = false WHERE lower(email) = lower(:'email') RETURNING uid, email, disabled;
SQL
