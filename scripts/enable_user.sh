#!/bin/sh
# Allow an email to sign in, and enable its account if it already has one:
#   scripts/enable_user.sh someone@example.com
set -e
cd "$(dirname "$0")/.."
# Postgres listens on 5432, or on DB_PORT with docker-compose.host.yml; its socket says which
port=$(docker compose exec -T db sh -c 'ls -a /var/run/postgresql' | sed -n 's/^\.s\.PGSQL\.\([0-9]*\)$/\1/p' | head -n 1)
docker compose exec -T db psql -U pongo_user -d pongo_db -p "${port:-5432}" -v ON_ERROR_STOP=1 -v email="$1" <<'SQL'
INSERT INTO allowed_emails (email) VALUES (lower(:'email')) ON CONFLICT DO NOTHING;
UPDATE users SET disabled = false WHERE lower(email) = lower(:'email') RETURNING uid, email, disabled;
SQL
