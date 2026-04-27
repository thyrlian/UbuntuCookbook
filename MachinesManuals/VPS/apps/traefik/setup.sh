#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACME_FILE="$SCRIPT_DIR/data/acme.json"

mkdir -p "$(dirname "$ACME_FILE")"
touch "$ACME_FILE"
chmod 600 "$ACME_FILE"

docker network create proxy 2>/dev/null || echo "Network 'proxy' already exists, skipping."

echo "Traefik pre-flight done. Run: docker compose up -d"
