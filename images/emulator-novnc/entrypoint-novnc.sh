#!/usr/bin/env bash
set -euo pipefail
AVD_NAME="${AVD_NAME:?AVD_NAME is required}"
ANDROID_API="${ANDROID_API:-33}"
ANDROID_TARGET="${ANDROID_TARGET:-google_apis}"
ANDROID_ARCH="${ANDROID_ARCH:-x86_64}"
GPU_MODE="${GPU_MODE:-swiftshader_indirect}"
DEVICE_PROFILE="${DEVICE_PROFILE:-pixel}"
CPU_CORES="${CPU_CORES:-2}"
RAM_MB="${RAM_MB:-4096}"
VM_HEAP_MB="${VM_HEAP_MB:-512}"
PARTITION_SIZE="${PARTITION_SIZE:-4096}"
DISPLAY="${DISPLAY:-:0}"
SCREEN="${SCREEN:-1280x900x24}"
EMULATOR_SKIN="${EMULATOR_SKIN:-540x960}"
EMULATOR_SCALE="${EMULATOR_SCALE:-}"
mkdir -p "$HOME/.android"
touch "$HOME/.android/repositories.cfg"
SYSTEM_IMAGE="system-images;android-${ANDROID_API};${ANDROID_TARGET};${ANDROID_ARCH}"
if [ ! -d "$HOME/.android/avd/${AVD_NAME}.avd" ]; then
  echo "[+] Creating AVD ${AVD_NAME} using ${SYSTEM_IMAGE}"
  echo "no" | avdmanager create avd --force --name "$AVD_NAME" --package "$SYSTEM_IMAGE" --device "$DEVICE_PROFILE"
fi
AVD_CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
set_avd_config() {
  local key="$1" value="$2"
  [[ -f "$AVD_CONFIG" ]] || return 0
  if grep -q "^${key}=" "$AVD_CONFIG"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$AVD_CONFIG"
  else
    printf '%s=%s
' "$key" "$value" >> "$AVD_CONFIG"
  fi
}
set_avd_config hw.cpu.ncore "$CPU_CORES"
set_avd_config hw.ramSize "$RAM_MB"
set_avd_config vm.heapSize "$VM_HEAP_MB"
POD_IP="$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"
if [ -n "${POD_IP:-}" ]; then
  socat TCP-LISTEN:5554,bind="${POD_IP}",fork,reuseaddr TCP:127.0.0.1:5554 &
  socat TCP-LISTEN:5555,bind="${POD_IP}",fork,reuseaddr TCP:127.0.0.1:5555 &
fi
export QT_X11_NO_MITSHM=1
export DISPLAY
Xvfb "$DISPLAY" -screen 0 "$SCREEN" -ac +extension GLX +render -noreset >/tmp/xvfb.log 2>&1 &
sleep 1
fluxbox >/tmp/fluxbox.log 2>&1 &
xterm -title "AndroidLab noVNC alive - emulator window should appear" -geometry 90x12+10+10 >/tmp/xterm.log 2>&1 &
x11vnc -display "$DISPLAY" -forever -shared -nopw -listen 127.0.0.1 -rfbport 5900 >/tmp/x11vnc.log 2>&1 &
NOVNC_WEB=/usr/share/novnc
if [ ! -d "$NOVNC_WEB" ]; then NOVNC_WEB=/usr/share/novnc/html; fi
echo "[+] noVNC web root: $NOVNC_WEB"
websockify --web="$NOVNC_WEB" 0.0.0.0:6080 127.0.0.1:5900 >/tmp/websockify.log 2>&1 &
echo "[+] noVNC 1:1:    http://HOST:NOVNC_PORT/vnc.html?autoconnect=true&resize=off&path=websockify"
echo "[+] noVNC scaled: http://HOST:NOVNC_PORT/vnc.html?autoconnect=true&resize=scale&path=websockify"
echo "[+] Starting GUI emulator: $AVD_NAME API=$ANDROID_API TARGET=$ANDROID_TARGET"
echo "[+] X screen: $SCREEN  Emulator skin: $EMULATOR_SKIN  Scale: ${EMULATOR_SCALE:-none}"
echo "[+] HW: cores=$CPU_CORES ram=${RAM_MB}MB heap=${VM_HEAP_MB}MB partition=${PARTITION_SIZE}MB"
args=(
  @"$AVD_NAME"
  -ports 5554,5555
  -skip-adb-auth
  -no-audio
  -no-boot-anim
  -gpu "$GPU_MODE"
  -cores "$CPU_CORES"
  -memory "$RAM_MB"
  -skin "$EMULATOR_SKIN"
  -writable-system
  -no-snapshot
  -partition-size "$PARTITION_SIZE"
)
if [[ -n "${EMULATOR_SCALE:-}" ]]; then
  args+=( -scale "$EMULATOR_SCALE" )
fi
exec emulator "${args[@]}"
