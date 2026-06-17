# ADB Cookbook

Replace `SERVER_INTERNAL_IP:13555` with the ADB endpoint from the manager instance card.

These ADB commands run on the **Rocky client/workstation**. The emulator is running on the server; the client connects directly to the server-published ADB socket.

## Screen with scrcpy

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:13555
```

Lower bandwidth:

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:13555 --max-size 1024 --bit-rate 2M --max-fps 30 --stay-awake
```

## Raw ADB connection

```bash
adb connect SERVER_INTERNAL_IP:13555
adb devices -l
export ANDROID_SERIAL=SERVER_INTERNAL_IP:13555
```

With `ANDROID_SERIAL` set, plain `adb shell ...` targets that emulator. To avoid relying on shell state, use `adb -s SERVER_INTERNAL_IP:13555 ...` explicitly.

## Android settings

```bash
adb -s SERVER_INTERNAL_IP:13555 shell am start -a android.settings.SETTINGS
adb -s SERVER_INTERNAL_IP:13555 shell cmd statusbar expand-settings
adb -s SERVER_INTERNAL_IP:13555 shell cmd statusbar expand-notifications
```

## Generic ADB

```bash
adb -s SERVER_INTERNAL_IP:13555 shell getprop ro.build.version.release
adb -s SERVER_INTERNAL_IP:13555 shell getprop sys.boot_completed
adb -s SERVER_INTERNAL_IP:13555 shell getprop ro.product.model
```

## APK install

```bash
adb -s SERVER_INTERNAL_IP:13555 install app.apk
adb -s SERVER_INTERNAL_IP:13555 install -r app.apk
```

## Files

```bash
adb -s SERVER_INTERNAL_IP:13555 push localfile /sdcard/Download/
adb -s SERVER_INTERNAL_IP:13555 pull /sdcard/Download/file ./file
```

## Screen size and density

```bash
adb -s SERVER_INTERNAL_IP:13555 shell wm size 1080x1920
adb -s SERVER_INTERNAL_IP:13555 shell wm density 420
adb -s SERVER_INTERNAL_IP:13555 shell wm size reset
adb -s SERVER_INTERNAL_IP:13555 shell wm density reset
```

## Proxy

```bash
adb -s SERVER_INTERNAL_IP:13555 shell settings put global http_proxy 192.168.1.10:8080
adb -s SERVER_INTERNAL_IP:13555 shell settings get global http_proxy
adb -s SERVER_INTERNAL_IP:13555 shell settings put global http_proxy :0
```

## Rotation

```bash
adb -s SERVER_INTERNAL_IP:13555 shell settings put system accelerometer_rotation 0
adb -s SERVER_INTERNAL_IP:13555 shell settings put system user_rotation 1
```

## Disconnect

```bash
adb disconnect SERVER_INTERNAL_IP:13555
```
