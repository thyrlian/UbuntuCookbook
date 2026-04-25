#!/bin/bash
set -euo pipefail

source .env

COUCHDB_URL="https://${LIVESYNC_DOMAIN}"

curl -X PUT "${COUCHDB_URL}/_users" -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}"
curl -X PUT "${COUCHDB_URL}/_replicator" -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}"

echo "CouchDB init done."
