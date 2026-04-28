#!/bin/bash
set -euo pipefail

# Before executing this script, make sure:
# - DNS records already point to your VPS:
#   - sync.yourdomain.com
#   - traefik.yourdomain.com
# - Real values have been added to all .env files.
# - TCP ports 80 and 443 are allowed by both the cloud firewall and UFW.
# - Docker and Docker Compose are installed and working.
# - The current user can run `docker compose`.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Traefik
TRAEFIK_DIR="$SCRIPT_DIR/traefik"
"$TRAEFIK_DIR/setup.sh"
docker compose --env-file "$TRAEFIK_DIR/.env" -f "$TRAEFIK_DIR/compose.yaml" up -d

# CouchDB
LIVESYNC_DIR="$SCRIPT_DIR/obsidian-livesync"
"$LIVESYNC_DIR/setup.sh"
docker compose --env-file "$LIVESYNC_DIR/.env" -f "$LIVESYNC_DIR/compose.yaml" up -d

# CouchDB one-time init
"$LIVESYNC_DIR/init.sh"
