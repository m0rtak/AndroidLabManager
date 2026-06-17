#!/usr/bin/env bash
# Version: 0.44.0
# Created: Petr Krivan
# Project: android lab manager

CLIENT_BASE="${CLIENT_BASE:-$HOME/AndroidLab}"
CLIENT_HOME="${CLIENT_HOME:-$CLIENT_BASE/scrcpy-client}"
ANDROIDLAB_SCRCPY_IMAGE="${ANDROIDLAB_SCRCPY_IMAGE:-localhost/androidlab-scrcpy-client:latest}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
ANDROIDLAB_DEFAULT_ADB_PORT="${ANDROIDLAB_DEFAULT_ADB_PORT:-13555}"
ANDROIDLAB_DEFAULT_SCRCPY_ARGS="${ANDROIDLAB_DEFAULT_SCRCPY_ARGS:---max-size 1280 --bit-rate 4M --stay-awake}"

androidlab_client_init_runtime_defaults() {
  ADB_CONNECT="${ADB_CONNECT:-}"
  SCRCPY_SERIAL="${SCRCPY_SERIAL:-$ADB_CONNECT}"
}
