#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.env"

COUCHDB_URL="https://${LIVESYNC_DOMAIN}"

curl -X PUT "${COUCHDB_URL}/_users" -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}"
curl -X PUT "${COUCHDB_URL}/_replicator" -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}"

echo "CouchDB init done."
