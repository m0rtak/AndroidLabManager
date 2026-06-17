# Installation

## 1. Server install

Run on the server where the Android emulator will run.

```bash
mkdir -p "$HOME/AndroidLab"
tar -xzf android-podman-lab-server-final.tar.gz -C "$HOME/AndroidLab"
cd "$HOME/AndroidLab/server-android"
./install.sh
```

The installer copies itself to:

```text
$HOME/AndroidLab/android-podman-lab
```

Default ADB endpoint:

```text
SERVER_INTERNAL_IP:13555
```

Bind to a specific internal IP:

```bash
BIND_IP=192.168.1.50 ADB_PORT=13555 ./install.sh
```

Wipe emulator data and reinstall:

```bash
./install.sh --wipe-data
```

## 2. Rocky client install

Run on the Rocky Linux workstation with GUI.

```bash
tar -xzf rocky-scrcpy-client-final.tar.gz
cd client-rocky-scrcpy
./install-client.sh
```

If Podman is missing:

```bash
sudo dnf install -y podman
```

Add launchers to PATH if needed:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Run:

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:13555
```
