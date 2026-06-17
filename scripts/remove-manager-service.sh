#!/usr/bin/env bash
set -euo pipefail
systemctl --user disable --now androidlab-manager.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/androidlab-manager.service"
systemctl --user daemon-reload 2>/dev/null || true
echo "[+] Android Lab Manager user service removed."
