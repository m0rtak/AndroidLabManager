# ADB Cheat Sheet

Common ADB commands for Android Lab emulators.

## Connection

```bash
androidlab-adb SERVER:13555 devices -l
androidlab-adb SERVER:13555 shell getprop ro.build.version.release
androidlab-adb SERVER:13555 shell getprop ro.product.model
```

## Install and remove APKs

```bash
androidlab-adb SERVER:13555 install app.apk
androidlab-adb SERVER:13555 install -r app.apk
androidlab-adb SERVER:13555 uninstall com.example.app
```

## Files

```bash
androidlab-adb SERVER:13555 push local.txt /sdcard/Download/local.txt
androidlab-adb SERVER:13555 pull /sdcard/Download/remote.txt .
androidlab-adb SERVER:13555 shell ls -la /sdcard/Download
```

## Open Android UI screens

```bash
androidlab-settings SERVER:13555
androidlab-quicksettings SERVER:13555
androidlab-notifications SERVER:13555
androidlab-adb SERVER:13555 shell am start -a android.settings.WIFI_SETTINGS
androidlab-adb SERVER:13555 shell am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS
```

## Screen and input

```bash
androidlab-adb SERVER:13555 shell wm size
androidlab-adb SERVER:13555 shell wm density
androidlab-adb SERVER:13555 shell wm size 1080x1920
androidlab-adb SERVER:13555 shell wm density 420
androidlab-adb SERVER:13555 shell wm size reset
androidlab-adb SERVER:13555 shell wm density reset
androidlab-adb SERVER:13555 shell input text hello
androidlab-adb SERVER:13555 shell input keyevent KEYCODE_HOME
androidlab-adb SERVER:13555 shell input swipe 500 1500 500 300
```

## Network proxy

```bash
androidlab-adb SERVER:13555 shell settings put global http_proxy PROXY_IP:8080
androidlab-adb SERVER:13555 shell settings put global http_proxy :0
androidlab-adb SERVER:13555 shell settings get global http_proxy
```

## Logs

```bash
androidlab-adb SERVER:13555 logcat
androidlab-adb SERVER:13555 logcat -c
androidlab-adb SERVER:13555 logcat ActivityManager:I AndroidRuntime:E '*:S'
```

## Packages and activities

```bash
androidlab-adb SERVER:13555 shell pm list packages
androidlab-adb SERVER:13555 shell pm list packages | grep example
androidlab-adb SERVER:13555 shell dumpsys package com.example.app | grep -i activity
androidlab-adb SERVER:13555 shell monkey -p com.example.app 1
```

## Screenshots and recording

```bash
androidlab-adb SERVER:13555 shell screencap -p /sdcard/screen.png
androidlab-adb SERVER:13555 pull /sdcard/screen.png .
androidlab-adb SERVER:13555 shell screenrecord /sdcard/demo.mp4
androidlab-adb SERVER:13555 pull /sdcard/demo.mp4 .
```

## Emulator console through container

For some emulator-only actions, use the emulator console from inside the emulator container.

```bash
podman exec -it android-emu13-nostore-emulator bash
adb devices
```

Examples depend on whether the emulator console port is exposed in your mode.
