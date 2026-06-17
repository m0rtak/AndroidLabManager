#!/usr/bin/env bash
# Version: 0.42.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/scripts/init-vars.sh"

androidlab_init_web_install_defaults

usage() {
  cat <<USAGE
Usage: ./web-install.sh [options]

Options:
  --api API             Android API to build initially, default: 33
  --target TARGET       SDK target, default: google_apis
  --host HOST           Manager bind host, default: 0.0.0.0
  --port PORT           Manager web port, default: 18080
  --token TOKEN         Optional Basic Auth password
  --public-host HOST    Host/IP used in generated scrcpy/noVNC commands
  --no-default          Do not create default emulator

Example:
  ./web-install.sh --api 33 --target google_apis --host 0.0.0.0 --port 18080 --token 'change-me'
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api) API="$2"; shift ;;
    --target) TARGET="$2"; shift ;;
    --host) HOST="$2"; shift ;;
    --port) PORT="$2"; shift ;;
    --token) TOKEN="$2"; shift ;;
    --public-host) PUBLIC_HOST="$2"; shift ;;
    --no-default) NO_DEFAULT=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

[[ "$PORT" =~ ^[0-9]+$ ]] || { echo "Invalid --port: $PORT" >&2; exit 1; }
(( PORT >= 1024 && PORT <= 65535 )) || { echo "Port out of range: $PORT" >&2; exit 1; }
cd "$SCRIPT_DIR"

if [[ -x "$SCRIPT_DIR/scripts/ensure-manager-env.sh" ]]; then
  LAB_HOME="$LAB_HOME" LAB_DATA="$LAB_DATA" MANAGER_HOST="$HOST" MANAGER_PORT="$PORT" MANAGER_TOKEN="$TOKEN" PUBLIC_HOST="$PUBLIC_HOST" "$SCRIPT_DIR/scripts/ensure-manager-env.sh" --force
fi

INSTALL_ARGS=(install --api "$API" --target "$TARGET")
[[ "$NO_DEFAULT" -eq 1 ]] && INSTALL_ARGS+=(--no-default)
./androidlab.sh "${INSTALL_ARGS[@]}"

if [[ -z "$TOKEN" ]]; then
  echo "[!] Manager token is empty. The web UI will be unauthenticated. Use --token for shared/internal networks." >&2
fi

LAB_HOME="${LAB_HOME:-$HOME/AndroidLab/android-podman-lab}"
cd "$LAB_HOME"
./androidlab.sh discover-running || true
MANAGER_HOST="$HOST" MANAGER_PORT="$PORT" MANAGER_TOKEN="$TOKEN" PUBLIC_HOST="$PUBLIC_HOST" scripts/install-manager-service.sh "$HOST" "$PORT" "$TOKEN" "$PUBLIC_HOST"

SERVER_IPS="$(hostname -I 2>/dev/null | xargs || true)"
cat <<MSG

[+] Web-first Android Lab install complete.

Detected server IPs:
  ${SERVER_IPS:-unknown}

Open:
  http://${PUBLIC_HOST:-SERVER_INTERNAL_IP}:${PORT}

If you set --token, use Basic Auth:
  username: anything
  password: your token

MSG
