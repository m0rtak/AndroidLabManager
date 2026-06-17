# Troubleshooting

## Server: check pod and port

```bash
cd "$HOME/AndroidLab/android-podman-lab"
make status
ss -ltnp | grep 13555
```

## Server: KVM access

```bash
ls -l /dev/kvm
```

If your user lacks access:

```bash
sudo usermod -aG kvm "$USER"
newgrp kvm
```

## Client: launcher not found

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Client: scrcpy option unknown

Use older-compatible flags:

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:13555 --max-size 1024 --bit-rate 2M --stay-awake
```

Do not use `[newer scrcpy bitrate flag]` on older scrcpy builds.

## Client: Wayland does not open window

The launcher falls back to X11 if Wayland is unavailable. If needed, log into an X11 session or make sure XWayland is running.

## ADB cannot connect

Check firewall and server bind address:

```bash
ss -ltnp | grep 13555
podman pod ps
podman logs android-emu13-nostore-emulator | tail -80
```

Make sure the client can reach:

```text
SERVER_INTERNAL_IP:13555
```
