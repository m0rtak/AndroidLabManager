# ADB Cookbook

Replace `SERVER_INTERNAL_IP:13555` with your actual endpoint.

## Screen

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:13555
```

Lower bandwidth:

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:13555 --max-size 1024 --bit-rate 2M --max-fps 30 --stay-awake
```

## Android settings

```bash
androidlab-settings SERVER_INTERNAL_IP:13555
androidlab-quicksettings SERVER_INTERNAL_IP:13555
androidlab-notifications SERVER_INTERNAL_IP:13555
```

## Generic ADB

```bash
androidlab-adb SERVER_INTERNAL_IP:13555 devices -l
androidlab-adb SERVER_INTERNAL_IP:13555 shell getprop ro.build.version.release
androidlab-adb SERVER_INTERNAL_IP:13555 shell getprop sys.boot_completed
```

## APK install

```bash
androidlab-adb SERVER_INTERNAL_IP:13555 install app.apk
```

## Files

```bash
androidlab-adb SERVER_INTERNAL_IP:13555 push localfile /sdcard/Download/
androidlab-adb SERVER_INTERNAL_IP:13555 pull /sdcard/Download/file ./file
```

## Screen size and density

```bash
androidlab-adb SERVER_INTERNAL_IP:13555 shell wm size 1080x1920
androidlab-adb SERVER_INTERNAL_IP:13555 shell wm density 420
androidlab-adb SERVER_INTERNAL_IP:13555 shell wm size reset
androidlab-adb SERVER_INTERNAL_IP:13555 shell wm density reset
```

## Proxy

```bash
androidlab-adb SERVER_INTERNAL_IP:13555 shell settings put global http_proxy 192.168.1.10:8080
androidlab-adb SERVER_INTERNAL_IP:13555 shell settings put global http_proxy :0
```

## Rotation

```bash
androidlab-adb SERVER_INTERNAL_IP:13555 shell settings put system accelerometer_rotation 0
androidlab-adb SERVER_INTERNAL_IP:13555 shell settings put system user_rotation 1
```
