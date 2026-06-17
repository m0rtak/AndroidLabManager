# Rocky Linux scrcpy Podman Client

Installs a Podman-based scrcpy client on Rocky Linux.

The canonical ADB workflow uses raw `adb` on the client/workstation:

```bash
adb connect SERVER_INTERNAL_IP:13555
adb -s SERVER_INTERNAL_IP:13555 shell getprop ro.build.version.release
```

The emulator runs on the server. The client connects to the server-published ADB endpoint shown in the manager instance card.

The client package still provides the scrcpy launcher:

```text
androidlab-scrcpy
```

It uses older-compatible scrcpy flags: `--bit-rate`.

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

## Run scrcpy

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:13555
```

## Run raw ADB from the client

```bash
adb connect SERVER_INTERNAL_IP:13555
adb devices -l
adb -s SERVER_INTERNAL_IP:13555 shell getprop sys.boot_completed
```
