#!/bin/bash
set -euo pipefail

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
