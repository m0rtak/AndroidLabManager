#!/usr/bin/env bash
# Version: 0.44.0
# Created: Petr Krivan
# Project: android lab manager
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/init-vars.sh
. "$SCRIPT_DIR/scripts/init-vars.sh"
SELF="$LAB_HOME/androidlab.sh"

api_tag() {
  local api="$1" target="$2" arch="$3"
  echo "api${api}-${target}-${arch}"
}

usage() {
  cat <<USAGE
Android Lab one-script manager

Usage:
  ./androidlab.sh install [--api API] [--target TARGET] [--arch ARCH] [--no-default] [--default-novnc]
  ./androidlab.sh menu
  ./androidlab.sh build-api API [TARGET] [ARCH]
  ./androidlab.sh create NAME ADB_PORT [headless|novnc] [API] [TARGET] [NOVNC_PORT]
  ./androidlab.sh spawn NAME [headless|novnc] [API] [TARGET]     # auto-allocate ports
  ./androidlab.sh list
  ./androidlab.sh delete NAME [--wipe]
  ./androidlab.sh clean-all [--wipe]
  ./androidlab.sh manager
  ./androidlab.sh frida NAME /path/to/frida-server [--start]
  ./androidlab.sh enable-novnc NAME [NOVNC_PORT]       # recreate existing instance as noVNC
  ./androidlab.sh disable-novnc NAME                   # recreate existing instance as headless
  ./androidlab.sh apply-hw NAME                         # apply CPU/RAM/heap/partition env and restart
  ./androidlab.sh update-api API [TARGET] [ARCH]
  ./androidlab.sh api-presets                      # print built-in Android version/API presets
  ./androidlab.sh api-list                         # refresh available API/system-image list
  ./androidlab.sh validate-records
  ./androidlab.sh repair-records
  ./androidlab.sh discover-running                 # rebuild records from running labeled Podman pods
  ./androidlab.sh status NAME
  ./androidlab.sh key NAME [back|home|recents|menu|power|volup|voldown]

Defaults:
  API=33 TARGET=google_apis ARCH=x86_64
  BIND_IP=$BIND_IP GPU_MODE=$GPU_MODE

Targets:
  google_apis            no Play Store, Google APIs/services
  google_apis_playstore  Play Store image, where available
USAGE
}

ensure_canonical() {
  guard_lab_paths
  if [[ "$SCRIPT_DIR" != "$LAB_HOME" && "${ANDROID_LAB_CANONICAL:-0}" != "1" ]]; then
    echo "[+] Installing lab to $LAB_HOME"
    mkdir -p "$LAB_HOME"
    # Replace managed source directories instead of overlaying them; this removes stale scripts from older bundles.
    rm -rf       "$LAB_HOME/scripts"       "$LAB_HOME/manager"       "$LAB_HOME/images"       "$LAB_HOME/docs"       "$LAB_HOME/client-rocky-scrcpy"
    rm -f       "$LAB_HOME/androidlab.sh"       "$LAB_HOME/install.sh"       "$LAB_HOME/web-install.sh"       "$LAB_HOME/README.md"
    find "$LAB_HOME" -path '*/__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true
    (cd "$SCRIPT_DIR" && tar --exclude='./.git' --exclude='./config' --exclude='./uploads' --exclude='./.venv' -cf - .) | (cd "$LAB_HOME" && tar -xf -)
    chmod +x "$SELF" "$LAB_HOME"/scripts/*.sh "$LAB_HOME"/images/emulator-headless/entrypoint.sh "$LAB_HOME"/images/emulator-novnc/entrypoint-novnc.sh
    exec env ANDROID_LAB_CANONICAL=1 LAB_BASE="$LAB_BASE" LAB_HOME="$LAB_HOME" LAB_DATA="$LAB_DATA" BIND_IP="$BIND_IP" GPU_MODE="$GPU_MODE" "$SELF" "$@"
  fi
}

check_host() {
  guard_lab_paths
  command -v podman >/dev/null || { echo "[-] podman missing" >&2; exit 1; }
  [[ "${SKIP_KVM_CHECK:-0}" == "1" || -e /dev/kvm ]] || { echo "[-] /dev/kvm missing" >&2; exit 1; }
  mkdir -p "$LAB_HOME/config" "$LAB_HOME/uploads" "$LAB_DATA"
}

records_file() { echo "$LAB_HOME/config/instances.tsv"; }

guard_lab_paths() {
  [[ -n "${LAB_HOME:-}" && "$LAB_HOME" != "/" && "$LAB_HOME" != "$HOME" ]] || { echo "Unsafe LAB_HOME: ${LAB_HOME:-unset}" >&2; exit 1; }
  [[ -n "${LAB_DATA:-}" && "$LAB_DATA" != "/" && "$LAB_DATA" != "$HOME" ]] || { echo "Unsafe LAB_DATA: ${LAB_DATA:-unset}" >&2; exit 1; }
}

validate_name() {
  local name="${1:-}"
  [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid name: $name" >&2; exit 1; }
}

validate_api_target_arch() {
  local api="${1:-}" target="${2:-}" arch="${3:-x86_64}"
  [[ "$api" =~ ^[0-9]{2,3}$ ]] || { echo "Invalid Android API: $api" >&2; exit 1; }
  [[ "$target" == "google_apis" || "$target" == "google_apis_playstore" ]] || { echo "Invalid target: $target" >&2; exit 1; }
  [[ "$arch" == "x86_64" ]] || { echo "Invalid arch: $arch" >&2; exit 1; }
}

validate_device_profile() {
  local device="${1:-pixel}"
  [[ "$device" =~ ^[a-zA-Z0-9_.-]+$ ]] || { echo "Invalid device profile: $device" >&2; exit 1; }
  (( ${#device} <= 64 )) || { echo "Device profile too long: $device" >&2; exit 1; }
}

device_presets() {
  cat <<'EOF'
pixel	Generic Pixel
pixel_5	Pixel 5
pixel_6	Pixel 6
pixel_6_pro	Pixel 6 Pro
pixel_7	Pixel 7
pixel_7_pro	Pixel 7 Pro
pixel_8	Pixel 8
pixel_8_pro	Pixel 8 Pro
EOF
}

validate_port() {
  local p="${1:-}"
  [[ "$p" =~ ^[0-9]+$ ]] || { echo "Invalid port: $p" >&2; exit 1; }
  (( p >= 1024 && p <= 65535 )) || { echo "Port out of range: $p" >&2; exit 1; }
}

validate_hw_profile() {
  local cpu="${1:-2}" ram="${2:-4096}" heap="${3:-512}" part="${4:-4096}"
  [[ "$cpu" =~ ^[0-9]+$ && "$ram" =~ ^[0-9]+$ && "$heap" =~ ^[0-9]+$ && "$part" =~ ^[0-9]+$ ]] || { echo "Invalid HW profile: cpu=$cpu ram=$ram heap=$heap partition=$part" >&2; exit 1; }
  (( cpu >= 1 && cpu <= 16 )) || { echo "CPU cores out of range: $cpu" >&2; exit 1; }
  (( ram >= 512 && ram <= 65536 )) || { echo "RAM MB out of range: $ram" >&2; exit 1; }
  (( heap >= 64 && heap <= 8192 )) || { echo "VM heap MB out of range: $heap" >&2; exit 1; }
  (( part >= 1024 && part <= 131072 )) || { echo "Partition MB out of range: $part" >&2; exit 1; }
}

normalize_records_file() {
  local input="${1:?input records file required}"
  awk -F'	' '
    NF && $1 {
      if (NF >= 12) {name=$1; mode=$2; adb=$3; novnc=$4; api=$5; target=$6; created=$7; device=$8; cpu=$9; ram=$10; heap=$11; part=$12}
      else if (NF >= 8) {name=$1; mode=$2; adb=$3; novnc=$4; api=$5; target=$6; created=$7; device=$8; cpu="2"; ram="4096"; heap="512"; part="4096"}
      else if (NF == 7) {name=$1; mode=$2; adb=$3; novnc=$4; api=$5; target=$6; created=$7; device="pixel"; cpu="2"; ram="4096"; heap="512"; part="4096"}
      else if (NF == 6) {name=$1; mode=$2; adb=$3; novnc=""; api=$4; target=$5; created=$6; device="pixel"; cpu="2"; ram="4096"; heap="512"; part="4096"}
      else {name=$1; mode=($2?$2:"headless"); adb=$3; novnc=""; api=($4?$4:"33"); target=($5?$5:"google_apis"); created=($6?$6:""); device="pixel"; cpu="2"; ram="4096"; heap="512"; part="4096"}
      if (mode != "novnc") novnc="";
      if (!device) device="pixel";
      if (!cpu) cpu="2"; if (!ram) ram="4096"; if (!heap) heap="512"; if (!part) part="4096";
      print name "	" mode "	" adb "	" novnc "	" api "	" target "	" created "	" device "	" cpu "	" ram "	" heap "	" part
    }
  ' "$input"
}



api_presets() {
  cat <<'EOF'
33	Android 13	Tiramisu	google_apis	No Play Store; Google APIs/services
33	Android 13	Tiramisu	google_apis_playstore	Play Store image, if available
34	Android 14	Upside Down Cake	google_apis	No Play Store; Google APIs/services
34	Android 14	Upside Down Cake	google_apis_playstore	Play Store image, if available
35	Android 15	Vanilla Ice Cream	google_apis	No Play Store; Google APIs/services
35	Android 15	Vanilla Ice Cream	google_apis_playstore	Play Store image, if available
36	Android 16	Baklava	google_apis	No Play Store; Google APIs/services
36	Android 16	Baklava	google_apis_playstore	Play Store image, if available
EOF
}

validate_records() {
  local records tmp
  records="$(records_file)"
  [[ -f "$records" ]] || { echo "[+] No records file"; return 0; }
  tmp="$(mktemp)"
  normalize_records_file "$records" > "$tmp"
  echo "[+] Checking records: $records"
  awk -F'\t' '
    NF && $1 {
      if (seen_name[$1]++) print "duplicate-name", $1;
      if ($3 && seen_port[$3]++) print "duplicate-port", $3;
      if ($4 && seen_port[$4]++) print "duplicate-port", $4;
    }
  ' "$tmp"
  rm -f "$tmp"
}

repair_records() {
  local records tmp normalized
  records="$(records_file)"
  mkdir -p "$(dirname "$records")"
  touch "$records"
  tmp="$records.tmp"
  normalized="$(mktemp)"
  normalize_records_file "$records" > "$normalized"
  # Normalize and de-duplicate. Keep newest/last occurrence of names and ports.
  tac "$normalized" | awk -F'\t' 'NF && $1 && !name[$1]++ && (!$3 || !port[$3]++) && (!$4 || !port[$4]++) {print}' | tac > "$tmp"
  rm -f "$normalized"
  mv "$tmp" "$records"
  echo "[+] Repaired records; current records:"
  list_emulators
}



record_exists() {
  local name="${1:?NAME required}" records
  records="$(records_file)"
  [[ -f "$records" ]] || return 1
  normalize_records_file "$records" | awk -F'\t' -v n="$name" '$1==n {found=1} END{exit found?0:1}'
}

port_is_allocated() {
  local p="$1" records
  records="$(records_file)"
  [[ -f "$records" ]] && awk -F'\t' -v p="$p" '($3==p || $4==p){found=1} END{exit found?0:1}' "$records" && return 0
  ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE ":${p}$" && return 0
  return 1
}

published_port() {
  local pod="$1" container="$2" port="$3" out infra
  out="$(podman port "$container" "${port}/tcp" 2>/dev/null || true)"
  if [[ -z "$out" ]]; then
    infra="$(podman pod inspect "$pod" --format '{{.InfraContainerID}}' 2>/dev/null || true)"
    if [[ -n "$infra" ]]; then out="$(podman port "$infra" "${port}/tcp" 2>/dev/null || true)"; fi
  fi
  printf '%s\n' "$out" | awk -F: 'NF {print $NF; exit}'
}

container_env_value() {
  local container="$1" key="$2"
  podman inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | awk -F= -v k="$key" '$1==k {print substr($0, length(k)+2); exit}'
}

discover_running() {
  check_host
  local records tmp pod container adb novnc api target image mode created device_profile cpu_cores ram_mb vm_heap_mb partition_size
  records="$(records_file)"
  mkdir -p "$(dirname "$records")"
  touch "$records"
  tmp="$(mktemp)"
  normalize_records_file "$records" > "$tmp"
  while IFS= read -r pod; do
    [[ -z "${pod:-}" ]] && continue
    [[ "$pod" =~ ^[a-zA-Z0-9_-]+$ ]] || continue
    container="$pod-emulator"
    podman container exists "$container" 2>/dev/null || continue
    adb="$(published_port "$pod" "$container" 5555)"
    [[ "$adb" =~ ^[0-9]+$ ]] || continue
    novnc="$(published_port "$pod" "$container" 6080)"
    api="$(container_env_value "$container" ANDROID_API)"; api="${api:-33}"
    target="$(container_env_value "$container" ANDROID_TARGET)"; target="${target:-google_apis}"
    device_profile="$(container_env_value "$container" DEVICE_PROFILE)"; device_profile="${device_profile:-pixel}"
    cpu_cores="$(container_env_value "$container" CPU_CORES)"; cpu_cores="${cpu_cores:-2}"
    ram_mb="$(container_env_value "$container" RAM_MB)"; ram_mb="${ram_mb:-4096}"
    vm_heap_mb="$(container_env_value "$container" VM_HEAP_MB)"; vm_heap_mb="${vm_heap_mb:-512}"
    partition_size="$(container_env_value "$container" PARTITION_SIZE)"; partition_size="${partition_size:-4096}"
    image="$(podman inspect "$container" --format '{{.ImageName}}' 2>/dev/null || true)"
    mode="headless"
    if [[ "$image" == *novnc* || "$novnc" =~ ^[0-9]+$ ]]; then mode="novnc"; else novnc=""; fi
    created="$(podman inspect "$container" --format '{{.Created}}' 2>/dev/null || true)"; created="${created:-$(date -Is)}"
    awk -F'\t' -v n="$pod" '$1 != n' "$tmp" > "$tmp.next" || true
    mv "$tmp.next" "$tmp"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$pod" "$mode" "$adb" "$novnc" "$api" "$target" "$created" "$device_profile" "$cpu_cores" "$ram_mb" "$vm_heap_mb" "$partition_size" >> "$tmp"
  done < <(podman pod ls --filter label=android.lab=true --format '{{.Name}}' 2>/dev/null || true)
  normalize_records_file "$tmp" > "$records.tmp"
  mv "$records.tmp" "$records"
  rm -f "$tmp"
  repair_records
}

build_api() {
  local api="${1:-33}" target="${2:-google_apis}" arch="${3:-x86_64}"
  validate_api_target_arch "$api" "$target" "$arch"
  local tag; tag="$(api_tag "$api" "$target" "$arch")"
  cd "$LAB_HOME"
  echo "[+] Building headless image for API=$api TARGET=$target ARCH=$arch"
  podman build \
    --build-arg ANDROID_API="$api" \
    --build-arg ANDROID_TARGET="$target" \
    --build-arg ANDROID_ARCH="$arch" \
    -t "localhost/android-emulator-headless:${tag}" \
    -f images/emulator-headless/Containerfile images/emulator-headless
  echo "[+] Building noVNC image for API=$api TARGET=$target ARCH=$arch"
  podman build \
    --build-arg BASE_IMAGE="localhost/android-emulator-headless:${tag}" \
    -t "localhost/android-emulator-novnc:${tag}" \
    -f images/emulator-novnc/Containerfile images/emulator-novnc
  echo "[+] Built images with tag: $tag"
}

create_emulator() {
  local name="${1:?NAME required}" adb_port="${2:?ADB_PORT required}" mode="${3:-headless}" api="${4:-33}" target="${5:-google_apis}" novnc_port="${6:-}" device_profile="${7:-pixel}" arch="x86_64"
  if [[ "$mode" == "headless" && -n "${6:-}" && ! "${6:-}" =~ ^[0-9]+$ ]]; then device_profile="$6"; novnc_port=""; fi
  validate_name "$name"
  validate_port "$adb_port"
  validate_api_target_arch "$api" "$target" "$arch"
  validate_device_profile "$device_profile"
  [[ "$mode" == "headless" || "$mode" == "novnc" ]] || { echo "mode must be headless or novnc" >&2; exit 1; }
  if [[ "$mode" == "novnc" && -z "$novnc_port" ]]; then echo "novnc mode requires NOVNC_PORT" >&2; exit 1; fi
  if [[ "$mode" == "novnc" ]]; then validate_port "$novnc_port"; fi
  local tag image pod data records
  tag="$(api_tag "$api" "$target" "$arch")"
  image="localhost/android-emulator-headless:${tag}"
  [[ "$mode" == "novnc" ]] && image="localhost/android-emulator-novnc:${tag}"
  local instance_gpu="$GPU_MODE"
  local novnc_screen="${NOVNC_SCREEN:-1280x900x24}"
  local emulator_skin="${EMULATOR_SKIN:-540x960}"
  local emulator_scale="${EMULATOR_SCALE:-}"
  local cpu_cores="${CPU_CORES:-2}"
  local ram_mb="${RAM_MB:-4096}"
  local vm_heap_mb="${VM_HEAP_MB:-512}"
  local partition_size="${PARTITION_SIZE:-4096}"
  validate_hw_profile "$cpu_cores" "$ram_mb" "$vm_heap_mb" "$partition_size"
  if [[ "$mode" == "novnc" && "$instance_gpu" == "swiftshader" ]]; then instance_gpu="swiftshader_indirect"; fi
  pod="$name"
  data="$LAB_DATA/$name"
  records="$(records_file)"
  podman image exists "$image" || { echo "Image missing: $image" >&2; echo "Build it first: ./androidlab.sh build-api $api $target $arch" >&2; exit 1; }
  if record_exists "$name"; then
    echo "Instance already exists in records: $name" >&2
    exit 1
  fi
  if podman pod exists "$name" 2>/dev/null; then
    echo "Pod already exists: $name" >&2
    exit 1
  fi
  if port_is_allocated "$adb_port"; then
    echo "ADB port already allocated/listening: $adb_port" >&2
    exit 1
  fi
  if [[ "$mode" == "novnc" ]] && port_is_allocated "$novnc_port"; then
    echo "noVNC port already allocated/listening: $novnc_port" >&2
    exit 1
  fi
  mkdir -p "$data/android-home" "$data/work" "$LAB_HOME/config"
  podman network exists android-lab-net 2>/dev/null || podman network create --driver bridge android-lab-net >/dev/null
  local publish=(--publish "${BIND_IP}:${adb_port}:5555/tcp")
  [[ "$mode" == "novnc" ]] && publish+=(--publish "${BIND_IP}:${novnc_port}:6080/tcp")
  podman pod create --name "$pod" --network android-lab-net "${publish[@]}" --label android.lab=true --label android.lab.name="$name"
  if ! podman run -d \
    --pod "$pod" \
    --name "$name-emulator" \
    --device /dev/kvm \
    --group-add keep-groups \
    --security-opt label=disable \
    --ulimit nofile=65535:65535 \
    -e AVD_NAME="$name" \
    -e ANDROID_API="$api" \
    -e ANDROID_TARGET="$target" \
    -e ANDROID_ARCH="$arch" \
    -e DEVICE_PROFILE="$device_profile" \
    -e GPU_MODE="$instance_gpu" \
    -e CPU_CORES="$cpu_cores" \
    -e RAM_MB="$ram_mb" \
    -e VM_HEAP_MB="$vm_heap_mb" \
    -e PARTITION_SIZE="$partition_size" \
    -e SCREEN="$novnc_screen" \
    -e EMULATOR_SKIN="$emulator_skin" \
    -e EMULATOR_SCALE="$emulator_scale" \
    -v "$data/android-home:/root/.android:Z" \
    -v "$data/work:/work:Z" \
    "$image"; then
    echo "[-] Failed to start emulator container; removing pod $pod" >&2
    podman pod rm -f "$pod" 2>/dev/null || true
    exit 1
  fi
  touch "$records"
  awk -F'\t' -v n="$name" '$1 != n' "$records" > "$records.tmp" || true
  mv "$records.tmp" "$records"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$mode" "$adb_port" "${novnc_port:-}" "$api" "$target" "$(date -Is)" "$device_profile" "$cpu_cores" "$ram_mb" "$vm_heap_mb" "$partition_size" >> "$records"
  echo "[+] Created $name mode=$mode api=$api target=$target device=$device_profile hw=${cpu_cores}c/${ram_mb}MB/heap${vm_heap_mb}/part${partition_size} adb=${BIND_IP}:${adb_port} novnc=${novnc_port:-none}"
}

list_emulators() {
  local records; records="$(records_file)"
  printf '%-28s %-9s %-7s %-7s %-5s %-22s %-18s %-18s %s\n' NAME MODE ADB NOVNC API TARGET DEVICE HW CREATED
  [[ -f "$records" ]] || return 0
  normalize_records_file "$records" | awk -F'\t' 'NF && $1 {printf "%-28s %-9s %-7s %-7s %-5s %-22s %-18s %-18s %s\n", $1, $2, $3, $4, $5, $6, $8, ($9"c/"$10"MB"), $7}'
}



pod_state() {
  local name="${1:?NAME required}" state
  validate_name "$name"
  if ! podman pod exists "$name" 2>/dev/null; then
    echo "missing"
    return 0
  fi
  state="$(podman pod inspect "$name" --format '{{.State}}' 2>/dev/null || true)"
  state="${state:-unknown}"
  echo "$state"
}

stop_emulator() {
  local name="${1:?NAME required}"
  validate_name "$name"
  podman pod exists "$name" 2>/dev/null || { echo "Pod not found: $name" >&2; exit 1; }
  echo "[+] Stopping $name"
  podman pod stop "$name"
  echo "[+] Stopped $name"
}

start_emulator() {
  local name="${1:?NAME required}"
  validate_name "$name"
  podman pod exists "$name" 2>/dev/null || { echo "Pod not found: $name. If it was deleted, recreate/spawn it from records or create a new instance." >&2; exit 1; }
  echo "[+] Starting $name"
  podman pod start "$name"
  echo "[+] Started $name"
}

delete_emulator() {
  local name="${1:?NAME required}" wipe="${2:-}" records
  podman pod rm -f "$name" 2>/dev/null || true
  podman rm -f "$name-emulator" 2>/dev/null || true
  records="$(records_file)"
  if [[ -f "$records" ]]; then awk -F'\t' -v n="$name" '$1 != n' "$records" > "$records.tmp" || true; mv "$records.tmp" "$records"; fi
  if [[ "$wipe" == "--wipe" ]]; then rm -rf "$LAB_DATA/$name"; echo "[+] Deleted $name and wiped data"; else echo "[+] Deleted $name; data kept"; fi
}

clean_all() {
  local wipe="${1:-}" records name
  records="$(records_file)"
  mkdir -p "$(dirname "$records")"
  # Remove pods tracked in records.
  if [[ -f "$records" ]]; then
    while IFS=$'\t' read -r name _; do
      [[ -z "${name:-}" ]] && continue
      podman pod rm -f "$name" 2>/dev/null || true
      podman rm -f "$name-emulator" 2>/dev/null || true
      [[ "$wipe" == "--wipe" ]] && rm -rf "$LAB_DATA/$name"
    done < "$records"
  fi
  # Also remove labeled lab pods, in case records were stale/corrupt.
  while read -r name; do
    [[ -z "${name:-}" ]] && continue
    podman pod rm -f "$name" 2>/dev/null || true
    podman rm -f "$name-emulator" 2>/dev/null || true
    [[ "$wipe" == "--wipe" ]] && rm -rf "$LAB_DATA/$name"
  done < <(podman pod ls --filter label=android.lab=true --format '{{.Name}}' 2>/dev/null || true)
  : > "$records"
  echo "[+] Clean all complete wipe=${wipe:-no}"
}

frida_upload() {
  local name="${1:?NAME required}" file="${2:?FILE required}" start="${3:-}" c="$name-emulator"
  validate_name "$name"
  [[ -f "$file" ]] || { echo "File not found: $file" >&2; exit 1; }
  podman container exists "$c" || { echo "Container not found: $c" >&2; exit 1; }
  podman cp "$file" "$c:/tmp/frida-server"
  podman exec "$c" adb start-server >/dev/null || true
  podman exec "$c" adb connect 127.0.0.1:5555 >/dev/null || true
  podman exec "$c" adb root >/dev/null 2>&1 || true
  sleep 2
  podman exec "$c" adb connect 127.0.0.1:5555 >/dev/null || true
  podman exec "$c" adb push /tmp/frida-server /data/local/tmp/frida-server
  podman exec "$c" adb shell chmod 755 /data/local/tmp/frida-server
  if [[ "$start" == "--start" ]]; then
    podman exec "$c" adb shell 'nohup /data/local/tmp/frida-server >/data/local/tmp/frida.log 2>&1 &' || true
    echo "[+] Uploaded and attempted to start frida-server on $name"
  else
    echo "[+] Uploaded frida-server to $name:/data/local/tmp/frida-server"
  fi
}

run_manager() {
  cd "$LAB_HOME"
  if [[ ! -d .venv ]]; then
    python3 -m venv .venv
    .venv/bin/pip install --upgrade pip
    .venv/bin/pip install flask
  fi
  exec .venv/bin/python manager/app.py
}

adb_keyevent() {
  local name="${1:?NAME required}" key="${2:?KEY required}" code
  validate_name "$name"
  case "$key" in
    back|triangle) code=4 ;;
    home|circle) code=3 ;;
    recents|recent|overview|square|app_switch) code=187 ;;
    menu) code=82 ;;
    power) code=26 ;;
    volup|volumeup) code=24 ;;
    voldown|volumedown) code=25 ;;
    *) echo "Invalid key: $key" >&2; echo "Allowed: back home recents menu power volup voldown" >&2; exit 1 ;;
  esac
  podman container exists "$name-emulator" 2>/dev/null || { echo "Container not found: $name-emulator" >&2; exit 1; }
  echo "[+] Sending Android keyevent $key ($code) to $name"
  podman exec "$name-emulator" adb shell input keyevent "$code"
}

status_one() {
  local name="${1:?NAME required}"
  podman pod ps | grep -E "POD|$name" || true
  podman ps --pod | grep -E "CONTAINER|$name" || true
  podman logs "$name-emulator" 2>/dev/null | tail -80 || true
}

device_list() {
  local img out
  mkdir -p "$LAB_HOME/config"
  out="$LAB_HOME/config/device-list.txt"
  img="$(podman images --format '{{.Repository}}:{{.Tag}}' | grep '^localhost/android-emulator-headless:' | head -n1 || true)"
  if [[ -z "$img" ]]; then
    echo "[-] No localhost/android-emulator-headless image found." >&2
    echo "    Build one first, e.g.: ./androidlab.sh build-api 33 google_apis x86_64" >&2
    exit 1
  fi
  echo "[+] Refreshing Android Emulator device profiles using image: $img" >&2
  podman run --rm --entrypoint bash "$img" -lc "avdmanager list device 2>/dev/null | awk '
    /^id: / {id=\$0; sub(/^.* or \"/,\"\",id); sub(/\".*/,\"\",id)}
    /^[[:space:]]*Name:/ {name=\$0; sub(/^[[:space:]]*Name:[[:space:]]*/,\"\",name); if (id) {print id \"\\t\" name; id=\"\"}}
  ' | sort -u" | tee "$out"
  echo "[+] Saved device profile list to $out" >&2
}

api_list() {
  local records img out
  mkdir -p "$LAB_HOME/config"
  out="$LAB_HOME/config/api-list.txt"
  img="$(podman images --format '{{.Repository}}:{{.Tag}}' | grep '^localhost/android-emulator-headless:' | head -n1 || true)"
  if [[ -z "$img" ]]; then
    echo "[-] No localhost/android-emulator-headless image found." >&2
    echo "    Build one first, e.g.: ./androidlab.sh build-api 33 google_apis x86_64" >&2
    exit 1
  fi
  echo "[+] Refreshing SDK package list using image: $img" >&2
  podman run --rm --entrypoint bash "$img" -lc "sdkmanager --list 2>/dev/null | grep -oE 'system-images;android-[0-9]+;(google_apis|google_apis_playstore);x86_64' | sort -u" | tee "$out"
  echo "[+] Saved API list to $out" >&2
}

menu() {
  while true; do
    echo
    echo "Android Lab Menu"
    echo "1) List emulators"
    echo "2) Build/update Android API image"
    echo "2a) Show Android API presets"
    echo "3) Create headless emulator"
    echo "4) Create noVNC emulator"
    echo "5) Stop emulator"
    echo "6) Start emulator"
    echo "7) Delete emulator"
    echo "8) Delete emulator + wipe data"
    echo "9) Clean all"
    echo "10) Clean all + wipe data"
    echo "11) Upload Frida server"
    echo "12) Run manager UI"
    echo "13) Validate records"
    echo "14) Repair records"
    echo "0) Exit"
    read -rp "Choice: " ch
    case "$ch" in
      1) list_emulators ;;
      2) read -rp "API [33]: " api; api=${api:-33}; read -rp "Target [google_apis]: " target; target=${target:-google_apis}; build_api "$api" "$target" x86_64 ;;
      2a) api_presets ;;
      3) read -rp "Name: " name; read -rp "ADB port: " adb; read -rp "API [33]: " api; api=${api:-33}; read -rp "Target [google_apis]: " target; target=${target:-google_apis}; read -rp "Device profile [pixel]: " dev; dev=${dev:-pixel}; create_emulator "$name" "$adb" headless "$api" "$target" "$dev" ;;
      4) read -rp "Name: " name; read -rp "ADB port: " adb; read -rp "noVNC port: " novnc; read -rp "API [33]: " api; api=${api:-33}; read -rp "Target [google_apis]: " target; target=${target:-google_apis}; read -rp "Device profile [pixel]: " dev; dev=${dev:-pixel}; create_emulator "$name" "$adb" novnc "$api" "$target" "$novnc" "$dev" ;;
      5) read -rp "Name: " name; stop_emulator "$name" ;;
      6) read -rp "Name: " name; start_emulator "$name" ;;
      7) read -rp "Name: " name; delete_emulator "$name" ;;
      8) read -rp "Name: " name; delete_emulator "$name" --wipe ;;
      9) clean_all ;;
      10) clean_all --wipe ;;
      11) read -rp "Name: " name; read -rp "frida-server path: " file; read -rp "Start after upload? [y/N]: " s; [[ "$s" =~ ^[Yy] ]] && frida_upload "$name" "$file" --start || frida_upload "$name" "$file" ;;
      12) run_manager ;;
      13) validate_records ;;
      14) repair_records ;;
      0) exit 0 ;;
      *) echo "Unknown" ;;
    esac
  done
}

cmd="${1:-}"
case "$cmd" in
  install)
    shift
    ensure_canonical install "$@"
    check_host
    api="$ANDROIDLAB_DEFAULT_API"; target="$ANDROIDLAB_DEFAULT_TARGET"; arch="$ANDROIDLAB_DEFAULT_ARCH"; no_default=0; default_novnc=0
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --api) api="$2"; shift ;;
        --target) target="$2"; shift ;;
        --arch) arch="$2"; shift ;;
        --no-default) no_default=1 ;;
        --default-novnc) default_novnc=1 ;;
        *) echo "Unknown install option: $1" >&2; exit 1 ;;
      esac; shift
    done
    if [[ -x "$LAB_HOME/scripts/ensure-manager-env.sh" ]]; then
      LAB_DATA="$LAB_DATA" MANAGER_HOST="${MANAGER_HOST:-$ANDROIDLAB_MANAGER_LOCAL_HOST_DEFAULT}" MANAGER_PORT="${MANAGER_PORT:-$ANDROIDLAB_MANAGER_PORT_DEFAULT}" "$LAB_HOME/scripts/ensure-manager-env.sh"
    fi
    build_api "$api" "$target" "$arch"
    if [[ "$no_default" -eq 0 ]]; then
      if record_exists android-emu13-nostore; then
        echo "[+] Default emulator android-emu13-nostore already exists in records; skipping default creation."
      elif port_is_allocated 13555; then
        echo "[+] ADB port 13555 is already allocated/listening; skipping default emulator creation."
        echo "    Use './androidlab.sh spawn NAME headless $api $target' for another instance, or './androidlab.sh clean-all' if you want to recreate from scratch."
      elif [[ "$default_novnc" -eq 1 ]]; then
        if port_is_allocated 13080; then
          echo "[+] noVNC port 13080 is already allocated/listening; skipping default noVNC emulator creation."
          echo "    Use './androidlab.sh spawn NAME novnc $api $target' to auto-allocate another noVNC port."
        else
          create_emulator android-emu13-nostore 13555 novnc "$api" "$target" 13080
        fi
      else
        create_emulator android-emu13-nostore 13555 headless "$api" "$target"
      fi
    fi
    discover_running || true
    echo "[+] Install complete. Run: $SELF menu"
    ;;
  menu) ensure_canonical menu; check_host; menu ;;
  build-api|update-api) ensure_canonical "$@"; check_host; shift; build_api "${1:-33}" "${2:-google_apis}" "${3:-x86_64}" ;;
  api-presets) ensure_canonical "$@"; api_presets ;;
  device-presets) ensure_canonical "$@"; device_presets ;;
  api-list) ensure_canonical "$@"; check_host; api_list ;;
  device-list) ensure_canonical "$@"; check_host; device_list ;;
  validate-records) ensure_canonical "$@"; validate_records ;;
  repair-records) ensure_canonical "$@"; check_host; repair_records ;;
  discover-running) ensure_canonical "$@"; discover_running ;;
  create) ensure_canonical "$@"; check_host; shift; create_emulator "$@" ;;
  spawn) ensure_canonical "$@"; check_host; shift; "$LAB_HOME/scripts/spawn-emulator.sh" "$@" ;;
  list) ensure_canonical "$@"; list_emulators ;;
  state) ensure_canonical "$@"; shift; pod_state "$@" ;;
  stop) ensure_canonical "$@"; check_host; shift; stop_emulator "$@" ;;
  start) ensure_canonical "$@"; check_host; shift; start_emulator "$@" ;;
  delete) ensure_canonical "$@"; shift; delete_emulator "$@" ;;
  clean-all) ensure_canonical "$@"; shift; clean_all "${1:-}" ;;
  frida) ensure_canonical "$@"; shift; frida_upload "$@" ;;
  enable-novnc) ensure_canonical "$@"; check_host; shift; "$LAB_HOME/scripts/enable-novnc.sh" "$@" ;;
  disable-novnc) ensure_canonical "$@"; check_host; shift; "$LAB_HOME/scripts/disable-novnc.sh" "$@" ;;
  apply-hw) ensure_canonical "$@"; check_host; shift; "$LAB_HOME/scripts/apply-hw.sh" "$@" ;;
  manager) ensure_canonical "$@"; check_host; run_manager ;;
  status) ensure_canonical "$@"; shift; status_one "$@" ;;
  key) ensure_canonical "$@"; check_host; shift; adb_keyevent "$@" ;;
  -h|--help|help|"") usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 1 ;;
esac
