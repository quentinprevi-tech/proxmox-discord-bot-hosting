#!/usr/bin/env bash

# Example script for portfolio documentation.
# This is a sanitized version of the real provisioning logic.
# It does not contain production paths, secrets, tokens or internal IP addresses.

set -euo pipefail

BOT_NAME="${1:-}"
PLAN="${2:-basic}"
CTID="${3:-}"

TEMPLATE_ID="${TEMPLATE_ID:-200}"
STORAGE="${STORAGE:-local-lvm}"

if [[ -z "$BOT_NAME" || -z "$CTID" ]]; then
  echo "Usage: $0 <bot-name> <plan> <ctid>"
  exit 1
fi

sanitize_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g' | cut -c1-32
}

BOT_NAME_SAFE="$(sanitize_name "$BOT_NAME")"

case "$PLAN" in
  basic)
    CPU_CORES=1
    RAM_MB=512
    ;;
  plus)
    CPU_CORES=1
    RAM_MB=1024
    ;;
  pro)
    CPU_CORES=2
    RAM_MB=2048
    ;;
  *)
    echo "Unknown plan: $PLAN"
    exit 1
    ;;
esac

echo "[INFO] Creating bot container"
echo "Bot name: $BOT_NAME_SAFE"
echo "Plan: $PLAN"
echo "CTID: $CTID"
echo "CPU: $CPU_CORES"
echo "RAM: $RAM_MB MB"

# Clone the LXC template.
pct clone "$TEMPLATE_ID" "$CTID" \
  --hostname "$BOT_NAME_SAFE" \
  --storage "$STORAGE"

# Apply resource limits.
pct set "$CTID" \
  --cores "$CPU_CORES" \
  --memory "$RAM_MB" \
  --onboot 1

# Start the container.
pct start "$CTID"

# Wait a few seconds for network initialization.
sleep 5

# Example IP detection.
BOT_IP="$(pct exec "$CTID" -- hostname -I | awk '{print $1}')"

echo "[OK] Bot container created"
echo "CTID=$CTID"
echo "BOT_NAME=$BOT_NAME_SAFE"
echo "BOT_IP=$BOT_IP"

# In the real project, the worker would then:
# - update metadata
# - update the SQLite order
# - regenerate Prometheus file_sd targets
# - synchronize the admin dashboard state
