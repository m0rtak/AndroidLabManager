#!/usr/bin/env bash
# Version: 0.42.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/init-vars.sh"
NAME="${1:-}"
NOVNC_PORT="${2:-}"
[[ -n "$NAME" ]] || { echo "Usage: enable-novnc.sh NAME [NOVNC_PORT]" >&2; exit 1; }
[[ "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid name: $NAME" >&2; exit 1; }
RECORDS="$LAB_HOME/config/instances.tsv"
[[ -f "$RECORDS" ]] || { echo "No records file: $RECORDS" >&2; exit 1; }
LINE="$(awk -F'\t' -v n="$NAME" '$1==n {print; exit}' "$RECORDS")"
[[ -n "$LINE" ]] || { echo "Instance not found: $NAME" >&2; exit 1; }
field() { printf '%s\n' "$LINE" | awk -F'\t' -v n="$1" '{print $n}'; }
NFIELDS="$(printf '%s\n' "$LINE" | awk -F'\t' '{print NF}')"
mode="$(field 2)"; mode="${mode:-headless}"
adb="$(field 3)"
if (( NFIELDS >= 12 )); then
  old_novnc="$(field 4)"
  api="$(field 5)"
  target="$(field 6)"
  device_profile="$(field 8)"
  cpu_cores="$(field 9)"
  ram_mb="$(field 10)"
  vm_heap_mb="$(field 11)"
  partition_size="$(field 12)"
elif (( NFIELDS >= 8 )); then
  old_novnc="$(field 4)"
  api="$(field 5)"
  target="$(field 6)"
  device_profile="$(field 8)"
  cpu_cores="2"; ram_mb="4096"; vm_heap_mb="512"; partition_size="4096"
elif (( NFIELDS >= 7 )); then
  old_novnc="$(field 4)"
  api="$(field 5)"
  target="$(field 6)"
  device_profile="pixel"
else
  old_novnc=""
  api="$(field 4)"
  target="$(field 5)"
fi
api="${api:-33}"
target="${target:-google_apis}"
device_profile="${device_profile:-pixel}"
cpu_cores="${cpu_cores:-2}"; ram_mb="${ram_mb:-4096}"; vm_heap_mb="${vm_heap_mb:-512}"; partition_size="${partition_size:-4096}"
[[ "$adb" =~ ^[0-9]+$ ]] || { echo "Invalid ADB port in records for $NAME: $adb" >&2; exit 1; }
[[ "$api" =~ ^[0-9]{2,3}$ ]] || api=33
[[ "$target" == "google_apis" || "$target" == "google_apis_playstore" ]] || target=google_apis
[[ "$device_profile" =~ ^[a-zA-Z0-9_.-]+$ && ${#device_profile} -le 64 ]] || { echo "Invalid device profile in records: $device_profile" >&2; exit 1; }
[[ "$cpu_cores" =~ ^[0-9]+$ && "$ram_mb" =~ ^[0-9]+$ && "$vm_heap_mb" =~ ^[0-9]+$ && "$partition_size" =~ ^[0-9]+$ ]] || { echo "Invalid HW profile in records" >&2; exit 1; }
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
  echo "No free noVNC port found" >&2
  exit 1
}
if [[ -z "$NOVNC_PORT" ]]; then
  NOVNC_PORT="$(next_port "$ANDROIDLAB_NOVNC_PORT_BASE")"
else
  [[ "$NOVNC_PORT" =~ ^[0-9]+$ ]] || { echo "Invalid noVNC port: $NOVNC_PORT" >&2; exit 1; }
fi
if port_used "$NOVNC_PORT" && [[ "${old_novnc:-}" != "$NOVNC_PORT" ]]; then
  echo "noVNC port already allocated/listening before mode switch: $NOVNC_PORT" >&2
  exit 1
fi
if [[ "$mode" == "novnc" ]]; then
  echo "[+] $NAME is already noVNC mode on port ${old_novnc:-$NOVNC_PORT}"
  exit 0
fi
target_image="localhost/android-emulator-novnc:api${api}-${target}-x86_64"
podman image exists "$target_image" || { echo "Image missing before mode switch: $target_image" >&2; echo "Build it first: $LAB_HOME/androidlab.sh build-api $api $target x86_64" >&2; exit 1; }
echo "[+] Recreating $NAME as noVNC mode, keeping data"
"$LAB_HOME/androidlab.sh" delete "$NAME"
CPU_CORES="$cpu_cores" RAM_MB="$ram_mb" VM_HEAP_MB="$vm_heap_mb" PARTITION_SIZE="$partition_size" "$LAB_HOME/androidlab.sh" create "$NAME" "$adb" novnc "$api" "$target" "$NOVNC_PORT" "$device_profile"
echo "[+] noVNC URL: http://SERVER_INTERNAL_IP:${NOVNC_PORT}/vnc.html?autoconnect=true&resize=off&path=websockify"
