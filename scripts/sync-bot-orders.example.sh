#!/usr/bin/env bash

# Example script for portfolio documentation.
# This is a sanitized version of the real order synchronization script.
# It compares the SQLite orders database with the current Proxmox LXC state.
# It does not contain production paths, secrets, tokens or internal IP addresses.

set -euo pipefail

DB_PATH="${DB_PATH:-./examples/orders.db}"
PROMETHEUS_GENERATOR="${PROMETHEUS_GENERATOR:-./scripts/generate-bots-sd.example.sh}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [sync-bot-orders] $*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    log "Missing required command: $1"
    exit 1
  }
}

require_command sqlite3
require_command pct

if [[ ! -f "$DB_PATH" ]]; then
  log "Database not found: $DB_PATH"
  log "This is an example script. Set DB_PATH to the real database location."
  exit 1
fi

log "Starting order synchronization"

# Example expected orders table fields:
# id, bot_name, status, ctid, ct_status, bot_ip

sqlite3 -csv "$DB_PATH" \
  "SELECT id, bot_name, status, ctid FROM orders WHERE ctid IS NOT NULL AND ctid != '';" |
while IFS=',' read -r order_id bot_name status ctid; do
  log "Checking order=$order_id bot=$bot_name ctid=$ctid"

  if pct status "$ctid" >/tmp/ct-status.example 2>/dev/null; then
    ct_status="$(awk '{print $2}' /tmp/ct-status.example)"

    if [[ "$ct_status" == "running" ]]; then
      bot_ip="$(pct exec "$ctid" -- hostname -I 2>/dev/null | awk '{print $1}' || true)"
    else
      bot_ip=""
    fi

    sqlite3 "$DB_PATH" \
      "UPDATE orders SET ct_status='$ct_status', bot_ip='$bot_ip' WHERE id=$order_id;"

    log "Updated order=$order_id ct_status=$ct_status bot_ip=$bot_ip"
  else
    sqlite3 "$DB_PATH" \
      "UPDATE orders SET ct_status='missing', bot_ip='' WHERE id=$order_id;"

    log "Container missing for order=$order_id ctid=$ctid"
  fi
done

rm -f /tmp/ct-status.example

# Regenerate Prometheus dynamic targets after synchronization.
if [[ -x "$PROMETHEUS_GENERATOR" ]]; then
  "$PROMETHEUS_GENERATOR"
else
  log "Prometheus generator not executable or not found: $PROMETHEUS_GENERATOR"
fi

log "Order synchronization finished"
