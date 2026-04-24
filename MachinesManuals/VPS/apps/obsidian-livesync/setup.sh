#!/bin/bash
set -euo pipefail

DATA_DIR="./data"
LOCAL_INI="./local.ini"

mkdir -p "$DATA_DIR"
chown -R 5984:5984 "$DATA_DIR"
chown 5984:5984 "$LOCAL_INI"

echo "CouchDB pre-flight done. Run: docker compose up -d"
