#!/usr/bin/env bash
# Version: 0.42.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/init-vars.sh"

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

androidlab_init_manager_env_defaults
ENV_FILE="$LAB_HOME/config/manager.env"

if [[ "$FORCE" -ne 1 && -s "$ENV_FILE" ]]; then
  exit 0
fi

if [[ -z "$MANAGER_CSRF_TOKEN" && -n "$MANAGER_TOKEN" ]]; then
  MANAGER_CSRF_TOKEN="$(python3 - <<'PYSECRETS'
import secrets
print(secrets.token_urlsafe(32))
PYSECRETS
)"
fi

# Keep values simple; run-manager sources this file and systemd reads it as EnvironmentFile.
for val in "$LAB_HOME" "$LAB_DATA" "$MANAGER_HOST" "$MANAGER_PORT" "$MANAGER_TOKEN" "$PUBLIC_HOST" "$MANAGER_CSRF_TOKEN"; do
  if [[ "$val" == *$'\n'* || "$val" == *$'\r'* || "$val" =~ [[:space:]#] ]]; then
    echo "Invalid whitespace/comment character in manager environment value: $val" >&2
    exit 1
  fi
done

mkdir -p "$LAB_HOME/config"
tmp="$(mktemp "$LAB_HOME/config/manager.env.tmp.XXXXXX")"
cat > "$tmp" <<ENV
LAB_HOME=$LAB_HOME
LAB_DATA=$LAB_DATA
MANAGER_HOST=$MANAGER_HOST
MANAGER_PORT=$MANAGER_PORT
MANAGER_TOKEN=$MANAGER_TOKEN
PUBLIC_HOST=$PUBLIC_HOST
MANAGER_CSRF_TOKEN=$MANAGER_CSRF_TOKEN
ENV
chmod 600 "$tmp"
mv -f "$tmp" "$ENV_FILE"
echo "[+] Ensured manager environment file: $ENV_FILE" >&2
