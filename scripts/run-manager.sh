#!/usr/bin/env bash
# Version: 0.45.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/init-vars.sh"
cd "$LAB_HOME"
if [[ -x scripts/ensure-manager-env.sh ]]; then
  scripts/ensure-manager-env.sh
fi
if [[ -f config/manager.env ]]; then
  set -a
  # shellcheck disable=SC1091
  . config/manager.env
  set +a
fi
if [[ ! -d .venv ]]; then
  python3 -m venv .venv
  .venv/bin/pip install --upgrade pip
  .venv/bin/pip install flask
fi
exec .venv/bin/python manager/app.py
