#!/usr/bin/env bash
# Version: 0.45.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/init-vars.sh"
NAME="${1:-}"
[[ -n "$NAME" ]] || { echo "Usage: apply-hw.sh NAME" >&2; exit 1; }
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
  novnc="$(field 4)"; api="$(field 5)"; target="$(field 6)"; device_profile="$(field 8)"
  old_cpu="$(field 9)"; old_ram="$(field 10)"; old_heap="$(field 11)"; old_part="$(field 12)"
elif (( NFIELDS >= 8 )); then
  novnc="$(field 4)"; api="$(field 5)"; target="$(field 6)"; device_profile="$(field 8)"
  old_cpu=2; old_ram=4096; old_heap=512; old_part=4096
elif (( NFIELDS >= 7 )); then
  novnc="$(field 4)"; api="$(field 5)"; target="$(field 6)"; device_profile="pixel"
  old_cpu=2; old_ram=4096; old_heap=512; old_part=4096
else
  novnc=""; api="$(field 4)"; target="$(field 5)"; device_profile="pixel"
  old_cpu=2; old_ram=4096; old_heap=512; old_part=4096
fi
api="${api:-33}"; target="${target:-google_apis}"; device_profile="${device_profile:-pixel}"
if [[ "$mode" != "novnc" ]]; then novnc=""; fi
CPU_CORES="${CPU_CORES:-$old_cpu}"
RAM_MB="${RAM_MB:-$old_ram}"
VM_HEAP_MB="${VM_HEAP_MB:-$old_heap}"
PARTITION_SIZE="${PARTITION_SIZE:-$old_part}"
[[ "$adb" =~ ^[0-9]+$ ]] || { echo "Invalid ADB port in records for $NAME: $adb" >&2; exit 1; }
[[ "$api" =~ ^[0-9]{2,3}$ ]] || { echo "Invalid API in record: $api" >&2; exit 1; }
[[ "$target" == "google_apis" || "$target" == "google_apis_playstore" ]] || { echo "Invalid target in record: $target" >&2; exit 1; }
[[ "$device_profile" =~ ^[a-zA-Z0-9_.-]+$ && ${#device_profile} -le 64 ]] || { echo "Invalid device profile in record: $device_profile" >&2; exit 1; }
[[ "$CPU_CORES" =~ ^[0-9]+$ && "$RAM_MB" =~ ^[0-9]+$ && "$VM_HEAP_MB" =~ ^[0-9]+$ && "$PARTITION_SIZE" =~ ^[0-9]+$ ]] || { echo "Invalid HW profile" >&2; exit 1; }
(( CPU_CORES >= 1 && CPU_CORES <= 16 )) || { echo "CPU cores out of range: $CPU_CORES" >&2; exit 1; }
(( RAM_MB >= 512 && RAM_MB <= 65536 )) || { echo "RAM MB out of range: $RAM_MB" >&2; exit 1; }
(( VM_HEAP_MB >= 64 && VM_HEAP_MB <= 8192 )) || { echo "VM heap MB out of range: $VM_HEAP_MB" >&2; exit 1; }
(( PARTITION_SIZE >= 1024 && PARTITION_SIZE <= 131072 )) || { echo "Partition MB out of range: $PARTITION_SIZE" >&2; exit 1; }
image="localhost/android-emulator-headless:api${api}-${target}-x86_64"
[[ "$mode" == "novnc" ]] && image="localhost/android-emulator-novnc:api${api}-${target}-x86_64"
podman image exists "$image" || { echo "Image missing before HW apply: $image" >&2; echo "Build it first: $LAB_HOME/androidlab.sh build-api $api $target x86_64" >&2; exit 1; }
echo "[+] Applying HW to $NAME: cpu=${CPU_CORES} ram=${RAM_MB} heap=${VM_HEAP_MB} partition=${PARTITION_SIZE}; restarting instance and keeping AVD data"
"$LAB_HOME/androidlab.sh" delete "$NAME"
if [[ "$mode" == "novnc" ]]; then
  [[ "$novnc" =~ ^[0-9]+$ ]] || { echo "Invalid noVNC port in records for $NAME: $novnc" >&2; exit 1; }
  CPU_CORES="$CPU_CORES" RAM_MB="$RAM_MB" VM_HEAP_MB="$VM_HEAP_MB" PARTITION_SIZE="$PARTITION_SIZE" "$LAB_HOME/androidlab.sh" create "$NAME" "$adb" novnc "$api" "$target" "$novnc" "$device_profile"
else
  CPU_CORES="$CPU_CORES" RAM_MB="$RAM_MB" VM_HEAP_MB="$VM_HEAP_MB" PARTITION_SIZE="$PARTITION_SIZE" "$LAB_HOME/androidlab.sh" create "$NAME" "$adb" headless "$api" "$target" "$device_profile"
fi
