# Intro
`Spawn, manage, and instrument Android emulators in Podman.`
- designed for Rocky Linux, but easily adaptable to any distro
- can be spawned on the server as a remote instance
- supports emulator GUI with noVNC via HTML, scrcpy
- uses Podman and systemctl --user for emulator control
- still in progress, but it works
- adb over TCP
  
```bash
adb connect server:port
adb devices -l
```
- see DOCS via web for full info

![img1](img1.png)
![img2](img2.png)

## Install/update

### Release
![Latest package release v44](android-podman-lab-web-manager-spawn-v44.tar.gz)

When used as archive:

```bash
mkdir -p "$HOME/AndroidLab"
tar -xzf android-podman-lab-web-manager-spawn-v44.tar.gz -C "$HOME/AndroidLab"
cd "$HOME/AndroidLab/android-podman-lab-web-manager-spawn-v44"
```

### Installation (from git):

```bash
./web-install.sh \
  --api 33 \
  --target google_apis \
  --host 0.0.0.0 \
  --port 18080 \
  --public-host SERVER_INTERNAL_IP \
  --token 'change-me'
```

#### After installation:

```bash
cd "$HOME/AndroidLab/android-podman-lab"

scripts/clean-stale-files.sh
./androidlab.sh discover-running
./androidlab.sh repair-records
scripts/regression-test.sh
systemctl --user restart androidlab-manager.service
```

This version reorganizes the web manager into focused dashboard sections, keeps the table format for detailed review, removes long command text from the table, and shows Start/Stop plus scrcpy commands in readable instance cards.
