#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ -f "$SCRIPT_DIR/.env" ] || { echo ".env not found"; exit 1; }
source "$SCRIPT_DIR/.env"

: "${COUCHDB_USER:?COUCHDB_USER is not set}"
: "${COUCHDB_PASSWORD:?COUCHDB_PASSWORD is not set}"
: "${LIVESYNC_DOMAIN:?LIVESYNC_DOMAIN is not set}"

COUCHDB_URL="https://${LIVESYNC_DOMAIN}"

MAX_RETRIES=24  # 2 minutes
RETRY=0

until curl -fsS -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}" "${COUCHDB_URL}/_up" >/dev/null 2>&1; do
  RETRY=$((RETRY + 1))
  if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
    echo "CouchDB did not become ready in time. Aborting."
    exit 1
  fi
  echo "Waiting for CouchDB via Traefik... (${RETRY}/${MAX_RETRIES})"
  sleep 5
done

ensure_db() {
  local db_name="$1"
  local status

  status=$(curl -sS -o /dev/null -w "%{http_code}" \
    -X PUT "${COUCHDB_URL}/${db_name}" \
    -u "${COUCHDB_USER}:${COUCHDB_PASSWORD}")

  case "$status" in
    201|202)
      echo "Database '${db_name}' created."
      ;;
    412)
      echo "Database '${db_name}' already exists."
      ;;
    *)
      echo "Failed to create database '${db_name}'. HTTP status: ${status}"
      exit 1
      ;;
  esac
}

ensure_db "_users"
ensure_db "_replicator"

echo "CouchDB init done."
