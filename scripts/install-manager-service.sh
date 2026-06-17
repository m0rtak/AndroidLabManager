#!/usr/bin/env bash
# Version: 0.44.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/init-vars.sh"
MANAGER_HOST="${1:-${MANAGER_HOST:-$ANDROIDLAB_MANAGER_HOST_DEFAULT}}"
MANAGER_PORT="${2:-${MANAGER_PORT:-$ANDROIDLAB_MANAGER_PORT_DEFAULT}}"
MANAGER_TOKEN="${3:-${MANAGER_TOKEN:-$ANDROIDLAB_MANAGER_TOKEN_DEFAULT}}"
PUBLIC_HOST="${4:-${PUBLIC_HOST:-$ANDROIDLAB_PUBLIC_HOST_DEFAULT}}"
MANAGER_CSRF_TOKEN="${MANAGER_CSRF_TOKEN:-}"
if [[ -z "$MANAGER_CSRF_TOKEN" && -n "$MANAGER_TOKEN" ]]; then
  MANAGER_CSRF_TOKEN="$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(32))
PY
)"
fi
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/androidlab-manager.service"
ENV_FILE="$LAB_HOME/config/manager.env"

mkdir -p "$SERVICE_DIR" "$LAB_HOME/config"
# Keep values simple for systemd EnvironmentFile.
# systemd EnvironmentFile parsing is not a full shell parser; reject whitespace and comments in these values.
for val in "$LAB_HOME" "$MANAGER_HOST" "$MANAGER_PORT" "$MANAGER_TOKEN" "$PUBLIC_HOST" "$MANAGER_CSRF_TOKEN"; do
  if [[ "$val" == *$'\n'* || "$val" == *$'\r'* || "$val" =~ [[:space:]#] ]]; then
    echo "Invalid whitespace/comment character in manager environment value: $val" >&2
    exit 1
  fi
done
LAB_DATA="$LAB_DATA" MANAGER_HOST="$MANAGER_HOST" MANAGER_PORT="$MANAGER_PORT" MANAGER_TOKEN="$MANAGER_TOKEN" PUBLIC_HOST="$PUBLIC_HOST" MANAGER_CSRF_TOKEN="$MANAGER_CSRF_TOKEN" "$SCRIPT_DIR/ensure-manager-env.sh" --force
[[ -s "$ENV_FILE" ]] || { echo "Failed to create manager environment file: $ENV_FILE" >&2; exit 1; }

cat > "$SERVICE_FILE" <<SERVICE
[Unit]
Description=Android Podman Lab Web Manager
After=network-online.target

[Service]
Type=simple
WorkingDirectory=$LAB_HOME
# Keep LAB_HOME/LAB_DATA available even if the optional EnvironmentFile is missing.
Environment=LAB_HOME=$LAB_HOME
Environment=LAB_DATA=$LAB_DATA
Environment=MANAGER_HOST=$MANAGER_HOST
Environment=MANAGER_PORT=$MANAGER_PORT
Environment=PUBLIC_HOST=$PUBLIC_HOST
# Leading '-' makes the service start instead of failing hard when manager.env was removed or not generated yet.
EnvironmentFile=-$ENV_FILE
ExecStartPre=$LAB_HOME/scripts/ensure-manager-env.sh
ExecStart=$LAB_HOME/scripts/run-manager.sh
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
SERVICE

systemctl --user daemon-reload
systemctl --user enable --now androidlab-manager.service

cat <<MSG

[+] Android Lab Manager user service installed.

Status:
  systemctl --user status androidlab-manager.service

Logs:
  journalctl --user -u androidlab-manager.service -f

Environment file:
  $ENV_FILE

URL:
  http://${PUBLIC_HOST:-SERVER_INTERNAL_IP}:${MANAGER_PORT}

Basic Auth:
  username: anything
  password: ${MANAGER_TOKEN:-disabled}

MSG
