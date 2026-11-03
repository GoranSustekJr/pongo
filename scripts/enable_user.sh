#!/bin/sh
# Enable an account by email: scripts/enable_user.sh someone@example.com
set -e
docker compose exec -T db psql -U pongo_user -d pongo_db \
    -v email="$1" -c "UPDATE users SET disabled = false WHERE lower(email) = lower(:'email') RETURNING uid, email, disabled;"
