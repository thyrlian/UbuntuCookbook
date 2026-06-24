#!/usr/bin/env bash
set -Eeuo pipefail

# Backup a CouchDB data directory used by Obsidian LiveSync.
#
# Preferred backup approaches for a larger or frequently written CouchDB instance:
#   1. CouchDB replication to another CouchDB instance.
#   2. Database-level export / dump / application-aware backup.
#   3. Stop the CouchDB container or use a filesystem snapshot before copying files.
#
# This script is a pragmatic file-level backup alternative for a small, low-write
# Obsidian LiveSync instance, especially when the service is idle.
#
# Important limitation:
#   The before/after manifest comparison is only a heuristic. It can tell whether
#   visible files changed during the backup window, but it does not make the
#   archive an atomic or crash-consistent CouchDB snapshot.
#
# Exit codes:
#   0 = backup completed and no file changes were detected
#   2 = backup completed, but tar warning or manifest drift was detected
#   3 = backup completed, but retention cleanup failed
#   other non-zero = actual script / tar / filesystem failure
#
# Common usage:
#   ./backup-data.sh
#
# Optional overrides:
#   BACKUP_DIR=/tmp ./backup-data.sh
#   RETENTION_DAYS=365 ./backup-data.sh
#   BACKUP_PREFIX=my-service-data ./backup-data.sh

APP_DIR="${APP_DIR:-/opt/apps/obsidian-livesync}"
DATA_RELATIVE_PATH="${DATA_RELATIVE_PATH:-data}"
DATA_DIR="${APP_DIR}/${DATA_RELATIVE_PATH}"

SERVICE_NAME="${SERVICE_NAME:-$(basename "$APP_DIR")}"
DATA_LABEL="${DATA_LABEL:-${DATA_RELATIVE_PATH//\//-}}"
BACKUP_PREFIX="${BACKUP_PREFIX:-${SERVICE_NAME}-${DATA_LABEL}}"

BACKUP_DIR="${BACKUP_DIR:-$HOME}"
RETENTION_DAYS="${RETENTION_DAYS:-}" # Empty or 0 means no retention cleanup.

TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
BACKUP_NAME="${BACKUP_PREFIX}-${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"
TMP_ARCHIVE="${BACKUP_PATH}.partial"
DIFF_FILE="${BACKUP_PATH}.diff"

TMP_DIR="$(mktemp -d)"
BEFORE_MANIFEST="${TMP_DIR}/before.txt"
AFTER_MANIFEST="${TMP_DIR}/after.txt"

TAR_WARNING=0
MANIFEST_DRIFT=0

if (( EUID == 0 )); then
  SUDO=()
else
  SUDO=(sudo)
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

cleanup() {
  rm -rf "$TMP_DIR"
  rm -f "$TMP_ARCHIVE"
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

  if [[ -n "$RETENTION_DAYS" && "$RETENTION_DAYS" != "0" ]]; then
    if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
      echo "ERROR: RETENTION_DAYS must be a positive integer, 0, or empty." >&2
      exit 1
    fi
  fi

  mkdir -p "$BACKUP_DIR"

  # Fail early if the current user cannot write to the backup location.
  : > "$TMP_ARCHIVE"
  rm -f "$TMP_ARCHIVE"
}

create_manifest() {
  local output_file="$1"

  # GNU find is assumed, which is standard on Ubuntu.
  #
  # Format:
  #   relative_path<TAB>file_size_bytes<TAB>mtime_epoch
  "${SUDO[@]}" find "$DATA_DIR" -type f -printf '%P\t%s\t%T@\n' | sort > "$output_file"
}

human_size() {
  local bytes="$1"

  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec-i --suffix=B "$bytes"
  else
    echo "${bytes} bytes"
  fi
}

print_manifest_summary() {
  local label="$1"
  local manifest_file="$2"

  local file_count
  local total_bytes
  local newest_epoch
  local newest_epoch_int
  local newest_time
  local manifest_hash
  local total_human

  file_count="$(wc -l < "$manifest_file" | tr -d ' ')"

  total_bytes="$(
    awk -F '\t' '
      { sum += $2 }
      END { printf "%.0f", sum + 0 }
    ' "$manifest_file"
  )"

  newest_epoch="$(
    awk -F '\t' '
      BEGIN { max = 0 }
      $3 > max { max = $3 }
      END { print max }
    ' "$manifest_file"
  )"

  if [[ "$newest_epoch" == "0" || -z "$newest_epoch" ]]; then
    newest_time="N/A"
  else
    newest_epoch_int="${newest_epoch%.*}"
    newest_time="$(date -d "@${newest_epoch_int}" '+%Y-%m-%d %H:%M:%S %Z')"
  fi

  manifest_hash="$(sha256sum "$manifest_file" | awk '{print $1}')"
  total_human="$(human_size "$total_bytes")"

  echo
  echo "${label} summary:"
  echo "  files:           ${file_count}"
  echo "  total size:      ${total_human} (${total_bytes} bytes)"
  echo "  newest mtime:    ${newest_time}"
  echo "  manifest sha256: ${manifest_hash}"
}

create_backup_archive() {
  log "Creating backup archive:"
  log "  Source: $DATA_DIR"
  log "  Target: $BACKUP_PATH"

  rm -f "$TMP_ARCHIVE"

  local rc=0

  # GNU tar exit codes:
  #   0 = success
  #   1 = warning, e.g. file changed while being read
  #   2 = fatal error
  #
  # We intentionally do not let set -e abort on tar exit 1. In this backup
  # scenario, exit 1 means the archive was still produced, but should be treated
  # as potentially inconsistent and later mapped to script exit code 2.
  "${SUDO[@]}" tar --xattrs --acls --numeric-owner \
    -C "$APP_DIR" \
    -czf - \
    "$DATA_RELATIVE_PATH" > "$TMP_ARCHIVE" || rc=$?

  if (( rc >= 2 )); then
    echo "ERROR: tar failed with exit code $rc" >&2
    exit "$rc"
  fi

  if [[ ! -s "$TMP_ARCHIVE" ]]; then
    echo "ERROR: temporary archive was not created or is empty: $TMP_ARCHIVE" >&2
    exit 1
  fi

  mv "$TMP_ARCHIVE" "$BACKUP_PATH"

  if (( rc == 1 )); then
    TAR_WARNING=1
    log "NOTE: tar reported a warning, probably files changed during read."
    log "The archive was produced, but it should be treated as potentially inconsistent."
  fi
}

compare_manifests() {
  echo
  echo "Result:"

  if diff -u "$BEFORE_MANIFEST" "$AFTER_MANIFEST" > "$DIFF_FILE"; then
    rm -f "$DIFF_FILE"
    MANIFEST_DRIFT=0
    log "OK: no file changes detected by manifest comparison."
  else
    MANIFEST_DRIFT=1
    log "WARNING: files changed during backup according to manifest comparison."
    log "Diff saved to: $DIFF_FILE"
    echo
    echo "Manifest diff:"
    cat "$DIFF_FILE"
    echo
    log "Recommendation: repeat the backup when idle, or stop the container temporarily."
  fi
}

write_checksum() {
  (
    cd "$BACKUP_DIR"
    sha256sum "$BACKUP_NAME" > "${BACKUP_NAME}.sha256"
  )

  log "SHA256 written to: ${BACKUP_PATH}.sha256"
}

apply_retention() {
  if [[ -z "$RETENTION_DAYS" || "$RETENTION_DAYS" == "0" ]]; then
    log "Retention cleanup disabled."
    return 0
  fi

  log "Applying retention cleanup: deleting backups older than ${RETENTION_DAYS} days."

  find "$BACKUP_DIR" -maxdepth 1 -type f \
    \( \
      -name "${BACKUP_PREFIX}-*.tar.gz" -o \
      -name "${BACKUP_PREFIX}-*.tar.gz.sha256" -o \
      -name "${BACKUP_PREFIX}-*.tar.gz.diff" -o \
      -name "${BACKUP_PREFIX}-*.tar.gz.partial" \
    \) \
    -mtime +"$RETENTION_DAYS" \
    -print \
    -delete
}

main() {
  trap cleanup EXIT

  local drift=0
  local retention_failed=0

  check_prerequisites

  log "Creating before manifest..."
  create_manifest "$BEFORE_MANIFEST"

  create_backup_archive

  log "Creating after manifest..."
  create_manifest "$AFTER_MANIFEST"

  print_manifest_summary "Before" "$BEFORE_MANIFEST"
  print_manifest_summary "After" "$AFTER_MANIFEST"

  compare_manifests

  if (( TAR_WARNING || MANIFEST_DRIFT )); then
    drift=1
  fi

  write_checksum

  if ! apply_retention; then
    retention_failed=1
    log "WARNING: retention cleanup failed; backup itself is intact."
  fi

  echo
  log "Backup completed:"
  log "  $BACKUP_PATH"

  if (( drift )); then
    if (( retention_failed )); then
      log "Additional warning: retention cleanup also failed."
    fi
    log "Exit code: 2, backup created but possible file drift was detected."
    return 2
  fi

  if (( retention_failed )); then
    log "Exit code: 3, backup created but retention cleanup failed."
    return 3
  fi

  log "Exit code: 0, backup created and no drift was detected."
  return 0
}

main "$@"
