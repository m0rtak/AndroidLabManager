#!/usr/bin/env bash
# Version: 0.45.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/init-vars.sh"
cd "$LAB_HOME"
find . -path '*/__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true
# Remove obsolete helper scripts from older noVNC/scrcpy bundles. They are not used by the web manager.
rm -f \
  scripts/00-clean.sh \
  scripts/01-build.sh \
  scripts/02-up.sh \
  scripts/03-status.sh \
  scripts/04-adb-check.sh \
  scripts/05-client-commands.sh \
  scripts/05-firewall-example.sh \
  scripts/run-all.sh
# Report any remaining unsupported scrcpy flag references.
badflag='--video'"-bit-rate"
if grep -RIn -- "$badflag" .; then
  echo '[-] Unsupported scrcpy flag still present in files above.' >&2
  exit 1
fi
echo '[+] Stale files cleaned.'
