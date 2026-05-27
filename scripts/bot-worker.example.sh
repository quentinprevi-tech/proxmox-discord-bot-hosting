#!/usr/bin/env bash

# Example script for portfolio documentation.
# This is a sanitized version of the real bot provisioning worker.
# It watches a queue directory, reads JSON jobs and provisions LXC containers.
# It does not contain production paths, secrets, tokens or internal IP addresses.

set -euo pipefail

QUEUE_DIR="${QUEUE_DIR:-/var/lib/bot-queue/pending}"
PROCESSING_DIR="${PROCESSING_DIR:-/var/lib/bot-queue/processing}"
DONE_DIR="${DONE_DIR:-/var/lib/bot-queue/done}"
FAILED_DIR="${FAILED_DIR:-/var/lib/bot-queue/failed}"

CREATE_SCRIPT="${CREATE_SCRIPT:-./scripts/create-bot.example.sh}"

mkdir -p "$QUEUE_DIR" "$PROCESSING_DIR" "$DONE_DIR" "$FAILED_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [bot-worker] $*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    log "Missing required command: $1"
    exit 1
  }
}

require_command jq
require_command pct

process_job() {
  local job_file="$1"
  local filename
  filename="$(basename "$job_file")"

  log "Processing job: $filename"

  local processing_file="$PROCESSING_DIR/$filename"
  mv "$job_file" "$processing_file"

  local order_id bot_name plan ctid

  order_id="$(jq -r '.order_id' "$processing_file")"
  bot_name="$(jq -r '.bot_name' "$processing_file")"
  plan="$(jq -r '.plan' "$processing_file")"
  ctid="$(jq -r '.ctid' "$processing_file")"

  if [[ -z "$order_id" || "$order_id" == "null" ]]; then
    log "Invalid job: missing order_id"
    mv "$processing_file" "$FAILED_DIR/$filename"
    return 1
  fi

  if [[ -z "$bot_name" || "$bot_name" == "null" ]]; then
    log "Invalid job: missing bot_name"
    mv "$processing_file" "$FAILED_DIR/$filename"
    return 1
  fi

  if [[ -z "$ctid" || "$ctid" == "null" ]]; then
    log "Invalid job: missing ctid"
    mv "$processing_file" "$FAILED_DIR/$filename"
    return 1
  fi

  log "Order ID: $order_id"
  log "Bot name: $bot_name"
  log "Plan: $plan"
  log "CTID: $ctid"

  if "$CREATE_SCRIPT" "$bot_name" "$plan" "$ctid"; then
    log "Provisioning successful for order $order_id"
    mv "$processing_file" "$DONE_DIR/$filename"
  else
    log "Provisioning failed for order $order_id"
    mv "$processing_file" "$FAILED_DIR/$filename"
    return 1
  fi
}

log "Starting bot worker"
log "Queue directory: $QUEUE_DIR"

while true; do
  shopt -s nullglob
  for job in "$QUEUE_DIR"/*.json; do
    process_job "$job" || true
  done
  shopt -u nullglob

  sleep 5
done
