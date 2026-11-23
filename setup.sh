#!/bin/sh
# Sets up and starts a Pongo server, then prints the address to type into the app:
#   ./setup.sh
# The first run writes .env with fresh secrets; later runs keep it and rebuild the
# server with the newest code, so run it again after `git pull` to update.
set -e
cd "$(dirname "$0")"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\n\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

command -v docker >/dev/null 2>&1 || fail "Docker isn't installed. Get Docker Desktop from https://www.docker.com/products/docker-desktop/ (or on a Mac: brew install colima docker docker-compose && colima start), then run ./setup.sh again."
docker compose version >/dev/null 2>&1 || fail "Docker Compose isn't installed. It comes with Docker Desktop; on Linux install the docker-compose-plugin package."
docker info >/dev/null 2>&1 || fail "Docker isn't running. Start Docker Desktop (or 'colima start'), then run ./setup.sh again."

secret() {
    openssl rand -hex 48 2>/dev/null || od -An -N48 -tx1 /dev/urandom | tr -d ' \n'
}

if [ -f .env ]; then
    say "Keeping the settings in .env"
else
    say "Writing .env with new secrets"
    sed -e "s/^DB_PASSWORD=.*/DB_PASSWORD=$(secret)/" -e "s/^JWT_SECRET=.*/JWT_SECRET=$(secret)/" \
        .env.example > .env
    chmod 600 .env
fi
mkdir -p secrets

say "Building and starting the server (the first time takes a few minutes)"
docker compose up -d --build

port=$(sed -n 's/^API_PORT=//p' .env | tail -n 1)
port=${port:-8081}
printf 'Waiting for the server to answer'
tries=0
until curl -fsS -m 3 "http://localhost:$port/health" >/dev/null 2>&1; do
    tries=$((tries + 1))
    [ "$tries" -gt 90 ] && fail "The server didn't start. See what went wrong with: docker compose logs api"
    printf '.'
    sleep 2
done
echo

# The address other devices on the network reach this machine at
ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
[ -n "$ip" ] || ip=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -n "$ip" ] || ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") print $(i + 1)}')

say "Pongo is running."
if [ -n "$ip" ]; then
    echo "In the app, connect to:   $ip:$port"
else
    echo "In the app, connect to this machine's IP address, port $port"
fi
if grep -q '^OPEN_SIGNUP=true' .env; then
    echo "Then tap 'Create an account'. Anyone who can reach this server can make one."
fi
echo "The phone or Mac has to be on the same network. For outside your home, see SELF_HOSTING.md."
