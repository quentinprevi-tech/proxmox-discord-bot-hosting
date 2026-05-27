#!/usr/bin/env bash

# Example script for portfolio documentation.
# This is a sanitized version of the Prometheus file_sd generation script.
# It generates a bots.json target file for Prometheus based on running bot containers.
# It does not contain production paths, secrets, tokens or internal IP addresses.

set -euo pipefail

OUTPUT_FILE="${OUTPUT_FILE:-./examples/bots.json.example}"
BOT_METADATA_DIR="${BOT_METADATA_DIR:-./examples/bot-instances}"

mkdir -p "$(dirname "$OUTPUT_FILE")"
mkdir -p "$BOT_METADATA_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [generate-bots-sd] $*"
}

escape_json() {
  python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"
}

log "Generating Prometheus file_sd targets"

tmp_file="$(mktemp)"

echo "[" > "$tmp_file"

first=1

shopt -s nullglob
for meta in "$BOT_METADATA_DIR"/*.env; do
  # shellcheck disable=SC1090
  source "$meta"

  # Expected metadata fields:
  # BOT_NAME
  # CTID
  # BOT_IP

  if [[ -z "${BOT_NAME:-}" || -z "${CTID:-}" || -z "${BOT_IP:-}" ]]; then
    log "Skipping invalid metadata file: $meta"
    continue
  fi

  if [[ "$first" -eq 0 ]]; then
    echo "," >> "$tmp_file"
  fi

  first=0

  bot_name_json="$(escape_json "$BOT_NAME")"
  ctid_json="$(escape_json "$CTID")"
  target_json="$(escape_json "$BOT_IP:9100")"

  cat >> "$tmp_file" <<JSON
  {
    "targets": [$target_json],
    "labels": {
      "type": "bot",
      "client": $bot_name_json,
      "hostname": $bot_name_json,
      "ctid": $ctid_json
    }
  }
JSON

done
shopt -u nullglob

echo "]" >> "$tmp_file"

mv "$tmp_file" "$OUTPUT_FILE"

log "Prometheus file_sd written to: $OUTPUT_FILE"
