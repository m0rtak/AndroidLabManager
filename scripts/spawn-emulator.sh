#!/usr/bin/env bash
# Version: 0.45.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/init-vars.sh"
NAME="${1:-}"
MODE="${2:-headless}"
API="${3:-$ANDROIDLAB_DEFAULT_API}"
TARGET="${4:-$ANDROIDLAB_DEFAULT_TARGET}"
DEVICE_PROFILE="${5:-$ANDROIDLAB_DEFAULT_DEVICE_PROFILE}"
[[ -n "$NAME" ]] || { echo "Usage: spawn-emulator.sh NAME [headless|novnc] [API] [TARGET] [DEVICE_PROFILE]" >&2; exit 1; }
[[ "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid name" >&2; exit 1; }
[[ "$MODE" == "headless" || "$MODE" == "novnc" ]] || { echo "mode must be headless or novnc" >&2; exit 1; }
RECORDS="$LAB_HOME/config/instances.tsv"
mkdir -p "$LAB_HOME/config"
touch "$RECORDS"
port_used() {
  local p="$1"
  awk -F'\t' -v p="$p" '($3==p || $4==p){found=1} END{exit found?0:1}' "$RECORDS" && return 0
  ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE ":${p}$" && return 0
  return 1
}
next_port() {
  local p="$1"
  local end=$((p+ANDROIDLAB_PORT_SCAN_LIMIT))
  while [[ "$p" -lt "$end" ]]; do
    if ! port_used "$p"; then echo "$p"; return 0; fi
    p=$((p+1))
  done
  echo "No free port found from $1" >&2
  exit 1
}
ADB_PORT="$(next_port "$ANDROIDLAB_ADB_PORT_BASE")"
if [[ "$MODE" == "novnc" ]]; then
  NOVNC_PORT="$(next_port "$ANDROIDLAB_NOVNC_PORT_BASE")"
  exec "$LAB_HOME/androidlab.sh" create "$NAME" "$ADB_PORT" novnc "$API" "$TARGET" "$NOVNC_PORT" "$DEVICE_PROFILE"
else
  exec "$LAB_HOME/androidlab.sh" create "$NAME" "$ADB_PORT" headless "$API" "$TARGET" "$DEVICE_PROFILE"
fi
