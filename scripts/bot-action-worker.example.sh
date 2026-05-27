#!/usr/bin/env bash

# Example script for portfolio documentation.
# This is a sanitized version of the real bot action worker.
# It processes admin/container actions such as start, stop, restart and delete.
# It does not contain production paths, secrets, tokens or internal IP addresses.

set -euo pipefail

ACTION_QUEUE_DIR="${ACTION_QUEUE_DIR:-/var/lib/bot-actions/pending}"
ACTION_PROCESSING_DIR="${ACTION_PROCESSING_DIR:-/var/lib/bot-actions/processing}"
ACTION_DONE_DIR="${ACTION_DONE_DIR:-/var/lib/bot-actions/done}"
ACTION_FAILED_DIR="${ACTION_FAILED_DIR:-/var/lib/bot-actions/failed}"

mkdir -p "$ACTION_QUEUE_DIR" "$ACTION_PROCESSING_DIR" "$ACTION_DONE_DIR" "$ACTION_FAILED_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [bot-action-worker] $*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    log "Missing required command: $1"
    exit 1
  }
}

require_command jq
require_command pct

run_action() {
  local action="$1"
  local ctid="$2"

  case "$action" in
    start)
      log "Starting CT $ctid"
      pct start "$ctid"
      ;;

    stop)
      log "Stopping CT $ctid"
      pct stop "$ctid"
      ;;

    restart)
      log "Restarting CT $ctid"
      pct stop "$ctid" || true
      sleep 2
      pct start "$ctid"
      ;;

    delete)
      log "Deleting CT $ctid"
      pct stop "$ctid" || true
      pct destroy "$ctid"
      ;;

    *)
      log "Unknown action: $action"
      return 1
      ;;
  esac
}

process_action_file() {
  local action_file="$1"
  local filename
  filename="$(basename "$action_file")"

  log "Processing action file: $filename"

  local processing_file="$ACTION_PROCESSING_DIR/$filename"
  mv "$action_file" "$processing_file"

  local order_id ctid action

  order_id="$(jq -r '.order_id' "$processing_file")"
  ctid="$(jq -r '.ctid' "$processing_file")"
  action="$(jq -r '.action' "$processing_file")"

  if [[ -z "$ctid" || "$ctid" == "null" ]]; then
    log "Invalid action: missing ctid"
    mv "$processing_file" "$ACTION_FAILED_DIR/$filename"
    return 1
  fi

  if [[ -z "$action" || "$action" == "null" ]]; then
    log "Invalid action: missing action"
    mv "$processing_file" "$ACTION_FAILED_DIR/$filename"
    return 1
  fi

  log "Order ID: $order_id"
  log "CTID: $ctid"
  log "Action: $action"

  if run_action "$action" "$ctid"; then
    log "Action successful: $action on CT $ctid"
    mv "$processing_file" "$ACTION_DONE_DIR/$filename"
  else
    log "Action failed: $action on CT $ctid"
    mv "$processing_file" "$ACTION_FAILED_DIR/$filename"
    return 1
  fi
}

log "Starting bot action worker"
log "Action queue directory: $ACTION_QUEUE_DIR"

while true; do
  shopt -s nullglob
  for action_file in "$ACTION_QUEUE_DIR"/*.json; do
    process_action_file "$action_file" || true
  done
  shopt -u nullglob

  sleep 5
done
