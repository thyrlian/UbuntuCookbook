#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.env"

COUCHDB_URL="https://${LIVESYNC_DOMAIN}"

until curl -fsS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" "${COUCHDB_URL}/_up" >/dev/null; do
  echo "Waiting for CouchDB via Traefik..."
  sleep 5
done

curl -fsS -X PUT "${COUCHDB_URL}/_users" -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" || true
curl -fsS -X PUT "${COUCHDB_URL}/_replicator" -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" || true

echo "CouchDB init done."
