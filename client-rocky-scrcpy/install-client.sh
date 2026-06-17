#!/usr/bin/env bash
# Version: 0.44.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail
ORIG_ARGS=("$@")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=client-init-vars.sh
. "$SCRIPT_DIR/client-init-vars.sh"
IMAGE="$ANDROIDLAB_SCRCPY_IMAGE"
SCRCPY_WRAPPER="$BIN_DIR/androidlab-scrcpy"
ADB_WRAPPER="$BIN_DIR/androidlab-adb"
SETTINGS_WRAPPER="$BIN_DIR/androidlab-settings"
QUICK_SETTINGS_WRAPPER="$BIN_DIR/androidlab-quicksettings"
NOTIFICATIONS_WRAPPER="$BIN_DIR/androidlab-notifications"
if [[ "$SCRIPT_DIR" != "$CLIENT_HOME" && "${ANDROID_LAB_CLIENT_CANONICAL:-0}" != "1" ]]; then
  echo "[+] Installing Rocky client bundle to: $CLIENT_HOME"
  mkdir -p "$CLIENT_HOME"
  (cd "$SCRIPT_DIR" && tar --exclude='./.git' -cf - .) | (cd "$CLIENT_HOME" && tar -xf -)
  chmod +x "$CLIENT_HOME/install-client.sh" "$CLIENT_HOME/run-scrcpy.sh" "$CLIENT_HOME/client-init-vars.sh"
  exec env ANDROID_LAB_CLIENT_CANONICAL=1 CLIENT_BASE="$CLIENT_BASE" CLIENT_HOME="$CLIENT_HOME" BIN_DIR="$BIN_DIR" "$CLIENT_HOME/install-client.sh" "${ORIG_ARGS[@]}"
fi
NO_BUILD=0
usage() { echo "Usage: ./install-client.sh [--no-build]"; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build) NO_BUILD=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done
if ! command -v podman >/dev/null 2>&1; then
  echo "[-] podman is not installed." >&2
  echo "    On Rocky: sudo dnf install -y podman" >&2
  exit 1
fi
cd "$CLIENT_HOME"
chmod +x install-client.sh run-scrcpy.sh
if [[ "$NO_BUILD" -eq 0 ]]; then
  echo "[+] Building scrcpy client image: $IMAGE"
  podman build -t "$IMAGE" -f Containerfile .
fi
mkdir -p "$BIN_DIR"
cat > "$SCRCPY_WRAPPER" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail
IMAGE="localhost/androidlab-scrcpy-client:latest"
if [[ $# -lt 1 ]]; then
  echo "Usage: androidlab-scrcpy SERVER_INTERNAL_IP[:PORT] [scrcpy args...]" >&2
  exit 1
fi
TARGET="$1"; shift
if [[ "$TARGET" != *:* ]]; then TARGET="${TARGET}:13555"; fi
# Older-compatible scrcpy flags for Rocky/EPEL versions:
# --bit-rate instead of [newer scrcpy bitrate flag]; no --no-audio by default.
if [[ $# -eq 0 ]]; then set -- --max-size 1280 --bit-rate 4M --stay-awake; fi
COMMON=(podman run --rm -it --network host --userns=keep-id --security-opt label=disable -e ADB_CONNECT="$TARGET")
if [[ -e /dev/dri ]]; then COMMON+=(--device /dev/dri); fi
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}"
if [[ -n "$WAYLAND_DISPLAY" && -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]; then
  exec "${COMMON[@]}" -e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" -e WAYLAND_DISPLAY="$WAYLAND_DISPLAY" -e SDL_VIDEODRIVER=wayland -v "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$IMAGE" "$@"
fi
DISPLAY_VALUE="${DISPLAY:-:0}"
XAUTH="${XAUTHORITY:-$HOME/.Xauthority}"
XARGS=(-e DISPLAY="$DISPLAY_VALUE" -v /tmp/.X11-unix:/tmp/.X11-unix:ro)
if [[ -f "$XAUTH" ]]; then XARGS+=(-e XAUTHORITY="$XAUTH" -v "$XAUTH:$XAUTH:ro"); fi
exec "${COMMON[@]}" "${XARGS[@]}" "$IMAGE" "$@"
WRAP
cat > "$ADB_WRAPPER" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail
IMAGE="localhost/androidlab-scrcpy-client:latest"
if [[ $# -lt 1 ]]; then
  echo "Usage: androidlab-adb SERVER_INTERNAL_IP[:PORT] adb-args..." >&2
  exit 1
fi
TARGET="$1"; shift
if [[ "$TARGET" != *:* ]]; then TARGET="${TARGET}:13555"; fi
podman run --rm -it --network host --userns=keep-id --security-opt label=disable --entrypoint bash "$IMAGE" -lc 'adb start-server >/dev/null; adb connect "$0" >/dev/null || true; exec adb -s "$0" "$@"' "$TARGET" "$@"
WRAP
cat > "$SETTINGS_WRAPPER" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -ge 1 ]] || { echo "Usage: androidlab-settings SERVER_INTERNAL_IP[:PORT]" >&2; exit 1; }
TARGET="$1"; [[ "$TARGET" == *:* ]] || TARGET="${TARGET}:13555"
androidlab-adb "$TARGET" shell am start -a android.settings.SETTINGS
WRAP
cat > "$QUICK_SETTINGS_WRAPPER" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -ge 1 ]] || { echo "Usage: androidlab-quicksettings SERVER_INTERNAL_IP[:PORT]" >&2; exit 1; }
TARGET="$1"; [[ "$TARGET" == *:* ]] || TARGET="${TARGET}:13555"
androidlab-adb "$TARGET" shell cmd statusbar expand-settings
WRAP
cat > "$NOTIFICATIONS_WRAPPER" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -ge 1 ]] || { echo "Usage: androidlab-notifications SERVER_INTERNAL_IP[:PORT]" >&2; exit 1; }
TARGET="$1"; [[ "$TARGET" == *:* ]] || TARGET="${TARGET}:13555"
androidlab-adb "$TARGET" shell cmd statusbar expand-notifications
WRAP
chmod +x "$SCRCPY_WRAPPER" "$ADB_WRAPPER" "$SETTINGS_WRAPPER" "$QUICK_SETTINGS_WRAPPER" "$NOTIFICATIONS_WRAPPER"
cat <<MSG

[+] Rocky scrcpy client installed.
Launchers:
  $SCRCPY_WRAPPER
  $ADB_WRAPPER
  $SETTINGS_WRAPPER
  $QUICK_SETTINGS_WRAPPER
  $NOTIFICATIONS_WRAPPER

Add to PATH if needed:
  export PATH="\$HOME/.local/bin:\$PATH"

Run:
  androidlab-scrcpy SERVER_INTERNAL_IP:13555

MSG
