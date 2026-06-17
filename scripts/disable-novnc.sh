#!/usr/bin/env bash
# Version: 0.45.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/init-vars.sh"
NAME="${1:-}"
[[ -n "$NAME" ]] || { echo "Usage: disable-novnc.sh NAME" >&2; exit 1; }
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
  api="$(field 5)"
  target="$(field 6)"
  device_profile="$(field 8)"
  cpu_cores="$(field 9)"
  ram_mb="$(field 10)"
  vm_heap_mb="$(field 11)"
  partition_size="$(field 12)"
elif (( NFIELDS >= 8 )); then
  api="$(field 5)"
  target="$(field 6)"
  device_profile="$(field 8)"
  cpu_cores="2"; ram_mb="4096"; vm_heap_mb="512"; partition_size="4096"
elif (( NFIELDS >= 7 )); then
  api="$(field 5)"
  target="$(field 6)"
  device_profile="pixel"
else
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
if [[ "$mode" == "headless" ]]; then
  echo "[+] $NAME is already headless mode"
  exit 0
fi
target_image="localhost/android-emulator-headless:api${api}-${target}-x86_64"
podman image exists "$target_image" || { echo "Image missing before mode switch: $target_image" >&2; echo "Build it first: $LAB_HOME/androidlab.sh build-api $api $target x86_64" >&2; exit 1; }
echo "[+] Recreating $NAME as headless/scrcpy mode, keeping data"
"$LAB_HOME/androidlab.sh" delete "$NAME"
CPU_CORES="$cpu_cores" RAM_MB="$ram_mb" VM_HEAP_MB="$vm_heap_mb" PARTITION_SIZE="$partition_size" "$LAB_HOME/androidlab.sh" create "$NAME" "$adb" headless "$api" "$target" "$device_profile"
