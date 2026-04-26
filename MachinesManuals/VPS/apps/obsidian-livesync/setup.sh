#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
LOCAL_INI="$SCRIPT_DIR/local.ini"

mkdir -p "$DATA_DIR"
chown -R 5984:5984 "$DATA_DIR"
chown 5984:5984 "$LOCAL_INI"

echo "CouchDB pre-flight done. Run: docker compose up -d"
