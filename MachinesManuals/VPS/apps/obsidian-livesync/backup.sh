#!/usr/bin/env bash
set -Eeuo pipefail

# Backup Obsidian LiveSync CouchDB data directory.
#
# Preferred backup approaches for a larger or frequently written CouchDB instance:
#   1. CouchDB replication to another CouchDB instance.
#   2. Database-level export / dump / application-aware backup.
#   3. Stop the CouchDB container or use a filesystem snapshot before copying files.
#
# This script is a pragmatic file-level backup alternative for a small, low-write
# Obsidian LiveSync instance, especially when the service is idle.
#
# It creates a before/after manifest based on:
#   - relative file path
#   - file size
#   - last modified timestamp
#
# If the manifests differ, the backup archive is still created, but the script
# prints a warning because files changed during backup and the archive may not be
# perfectly consistent.

APP_DIR="/opt/apps/obsidian-livesync"
DATA_DIR="${APP_DIR}/data"

BACKUP_DIR="${BACKUP_DIR:-$HOME}"
BACKUP_NAME="obsidian-livesync-data-$(date +%Y-%m-%d_%H%M%S).tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

TMP_DIR="$(mktemp -d)"
BEFORE_MANIFEST="${TMP_DIR}/before.txt"
AFTER_MANIFEST="${TMP_DIR}/after.txt"
DIFF_FILE="${BACKUP_PATH}.diff"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

cleanup() {
  rm -rf "$TMP_DIR"
}

check_prerequisites() {
  if [[ ! -d "$APP_DIR" ]]; then
    echo "ERROR: app directory not found: $APP_DIR" >&2
    exit 1
  fi

  if [[ ! -d "$DATA_DIR" ]]; then
    echo "ERROR: data directory not found: $DATA_DIR" >&2
    exit 1
  fi

  mkdir -p "$BACKUP_DIR"
}

create_manifest() {
  local output_file="$1"

  # GNU find is assumed, which is standard on Ubuntu.
  sudo find "$DATA_DIR" -type f -printf '%P\t%s\t%T@\n' | sort > "$output_file"
}

create_backup_archive() {
  log "Creating backup archive:"
  log "  Source: $DATA_DIR"
  log "  Target: $BACKUP_PATH"

  # tar runs as root so it can read all CouchDB files.
  # The archive is written to stdout and redirected by the current user, so the
  # resulting file is owned by the current user instead of root.
  sudo tar --xattrs --acls --numeric-owner \
    -C "$APP_DIR" \
    -czf - \
    data > "$BACKUP_PATH"
}

compare_manifests() {
  if diff -u "$BEFORE_MANIFEST" "$AFTER_MANIFEST" > "$DIFF_FILE"; then
    rm -f "$DIFF_FILE"
    log "OK: no file changes detected during backup."
    return 0
  else
    log "WARNING: files changed during backup."
    log "The archive was created, but it may not be fully consistent."
    log "Diff saved to: $DIFF_FILE"
    echo
    cat "$DIFF_FILE"
    echo
    log "Recommendation: repeat the backup when idle, or stop the container temporarily."
    return 1
  fi
}

write_checksum() {
  sha256sum "$BACKUP_PATH" | tee "${BACKUP_PATH}.sha256" >/dev/null
  log "SHA256 written to: ${BACKUP_PATH}.sha256"
}

main() {
  trap cleanup EXIT

  check_prerequisites

  log "Creating before manifest..."
  create_manifest "$BEFORE_MANIFEST"

  create_backup_archive

  log "Creating after manifest..."
  create_manifest "$AFTER_MANIFEST"

  compare_manifests || true

  write_checksum

  log "Backup completed:"
  log "  $BACKUP_PATH"
}

main "$@"
