# Rocky Linux scrcpy Podman Client

Installs a Podman-based scrcpy client on Rocky Linux.

The client package creates these launchers:

```text
androidlab-scrcpy
androidlab-adb
androidlab-settings
androidlab-quicksettings
androidlab-notifications
```

It uses older-compatible scrcpy flags: `--bit-rate.

## Install

```bash
tar -xzf rocky-scrcpy-client-final.tar.gz
cd client-rocky-scrcpy
./install-client.sh
```

If Podman is missing:

```bash
sudo dnf install -y podman
```

## Run

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:13555
```
