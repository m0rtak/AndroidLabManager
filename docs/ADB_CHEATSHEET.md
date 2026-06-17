# ADB Cheat Sheet

Canonical ADB workflow for Android Lab emulators.

Run these commands on the **client/workstation** where `adb` is installed. The emulator runs on the server, and the server publishes each emulator ADB endpoint as `SERVER_INTERNAL_IP:ADB_PORT`.

Do not use an Android Lab ADB wrapper in these examples. Use raw `adb` from the client.

## Connect from the client

Replace `SERVER_INTERNAL_IP:13555` with the ADB endpoint shown in the manager instance card.

```bash
adb connect SERVER_INTERNAL_IP:13555
adb devices -l
```

For repeated commands, either pass the serial explicitly:

```bash
adb -s SERVER_INTERNAL_IP:13555 shell getprop ro.build.version.release
adb -s SERVER_INTERNAL_IP:13555 shell getprop ro.product.model
```

or export it once in the client shell:

```bash
export ANDROID_SERIAL=SERVER_INTERNAL_IP:13555
adb shell getprop ro.build.version.release
adb shell getprop ro.product.model
```

## Install and remove APKs

```bash
adb -s SERVER_INTERNAL_IP:13555 install app.apk
adb -s SERVER_INTERNAL_IP:13555 install -r app.apk
adb -s SERVER_INTERNAL_IP:13555 uninstall com.example.app
```

## Files

```bash
adb -s SERVER_INTERNAL_IP:13555 push local.txt /sdcard/Download/local.txt
adb -s SERVER_INTERNAL_IP:13555 pull /sdcard/Download/remote.txt .
adb -s SERVER_INTERNAL_IP:13555 shell ls -la /sdcard/Download
```

## Open Android UI screens

```bash
adb -s SERVER_INTERNAL_IP:13555 shell am start -a android.settings.SETTINGS
adb -s SERVER_INTERNAL_IP:13555 shell am start -a android.settings.WIFI_SETTINGS
adb -s SERVER_INTERNAL_IP:13555 shell am start -a android.settings.APPLICATION_DEVELOPMENT_SETTINGS
adb -s SERVER_INTERNAL_IP:13555 shell cmd statusbar expand-settings
adb -s SERVER_INTERNAL_IP:13555 shell cmd statusbar expand-notifications
```

## Screen and input

```bash
adb -s SERVER_INTERNAL_IP:13555 shell wm size
adb -s SERVER_INTERNAL_IP:13555 shell wm density
adb -s SERVER_INTERNAL_IP:13555 shell wm size 1080x1920
adb -s SERVER_INTERNAL_IP:13555 shell wm density 420
adb -s SERVER_INTERNAL_IP:13555 shell wm size reset
adb -s SERVER_INTERNAL_IP:13555 shell wm density reset
adb -s SERVER_INTERNAL_IP:13555 shell input text hello
adb -s SERVER_INTERNAL_IP:13555 shell input keyevent KEYCODE_HOME
adb -s SERVER_INTERNAL_IP:13555 shell input keyevent KEYCODE_BACK
adb -s SERVER_INTERNAL_IP:13555 shell input keyevent KEYCODE_APP_SWITCH
adb -s SERVER_INTERNAL_IP:13555 shell input swipe 500 1500 500 300
```

## Network proxy

Use the proxy IP as reachable from inside the emulator network path. For a Burp/ZAP proxy on your workstation, use the workstation IP that the server/emulator can reach.

```bash
adb -s SERVER_INTERNAL_IP:13555 shell settings put global http_proxy PROXY_IP:8080
adb -s SERVER_INTERNAL_IP:13555 shell settings get global http_proxy
adb -s SERVER_INTERNAL_IP:13555 shell settings put global http_proxy :0
```

## Logs

```bash
adb -s SERVER_INTERNAL_IP:13555 logcat
adb -s SERVER_INTERNAL_IP:13555 logcat -c
adb -s SERVER_INTERNAL_IP:13555 logcat ActivityManager:I AndroidRuntime:E '*:S'
```

## Packages and activities

```bash
adb -s SERVER_INTERNAL_IP:13555 shell pm list packages
adb -s SERVER_INTERNAL_IP:13555 shell pm list packages | grep example
adb -s SERVER_INTERNAL_IP:13555 shell dumpsys package com.example.app | grep -i activity
adb -s SERVER_INTERNAL_IP:13555 shell monkey -p com.example.app 1
```

## Screenshots and recording

```bash
adb -s SERVER_INTERNAL_IP:13555 shell screencap -p /sdcard/screen.png
adb -s SERVER_INTERNAL_IP:13555 pull /sdcard/screen.png .
adb -s SERVER_INTERNAL_IP:13555 shell screenrecord /sdcard/demo.mp4
adb -s SERVER_INTERNAL_IP:13555 pull /sdcard/demo.mp4 .
```

## Offline or stale localhost transport

If `adb devices -l` shows `localhost:5555 offline`, clear the local/stale transport and reconnect to the server-published endpoint:

```bash
adb disconnect localhost:5555
adb disconnect 127.0.0.1:5555
adb disconnect
adb kill-server
adb start-server
adb connect SERVER_INTERNAL_IP:13555
adb devices -l
```

From the client, the expected serial is `SERVER_INTERNAL_IP:ADB_PORT`, not `localhost:5555`, unless you intentionally created an SSH tunnel.

## Disconnect

```bash
adb disconnect SERVER_INTERNAL_IP:13555
```

## Server-side Podman note

Only use server-side commands when you intentionally need to inspect the emulator container itself. Normal pentest and automation work should use raw `adb` from the client to `SERVER_INTERNAL_IP:ADB_PORT`.

```bash
podman exec -it INSTANCE-emulator bash
adb devices
```
