# noVNC phone controls

v35 adds a controlled noVNC wrapper page for Android navigation buttons.

## Why

The Android Emulator side toolbar or Android navigation bar can be awkward or missing inside a noVNC browser session. The wrapper page adds explicit controls for:

- Back
- Home
- Recents
- Menu
- Power

## How it works

The manager opens noVNC inside an iframe and sends Android keyevents through ADB:

```bash
./androidlab.sh key INSTANCE back
./androidlab.sh key INSTANCE home
./androidlab.sh key INSTANCE recents
```

The CLI sends the command inside the emulator container:

```bash
podman exec INSTANCE-emulator adb shell input keyevent KEYCODE
```

## Usage

From the Instances card, use:

```text
Open with controls
```

This opens:

```text
/novnc/<instance-name>
```

The direct noVNC links are still available for 1:1, fit, and remote resize modes.
