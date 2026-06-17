#!/usr/bin/env bash
# Version: 0.44.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=client-init-vars.sh
. "$SCRIPT_DIR/client-init-vars.sh"
androidlab_client_init_runtime_defaults
if [[ -z "$ADB_CONNECT" && -z "$SCRCPY_SERIAL" ]]; then
  echo "[-] Set ADB_CONNECT=SERVER_INTERNAL_IP:13555" >&2
  exit 1
fi
adb start-server >/dev/null
if [[ -n "$ADB_CONNECT" ]]; then
  echo "[+] adb connect $ADB_CONNECT"
  adb connect "$ADB_CONNECT" || true
fi
echo "[+] adb devices"
adb devices -l
echo "[+] starting scrcpy for serial: $SCRCPY_SERIAL"
exec scrcpy -s "$SCRCPY_SERIAL" "$@"
