# Frida Cheat Sheet

Frida workflow for Android Lab emulators.

ADB examples in this file use raw `adb` from the client/workstation. The emulator runs on the server, and the client connects to the exposed endpoint `SERVER_INTERNAL_IP:ADB_PORT`.

## Upload frida-server from the web manager

Use the **Frida upload** panel in the web UI:

1. Pick the emulator instance.
2. Upload a matching `frida-server` binary for Android x86_64.
3. Check **start** if you want the manager to start it automatically.

CLI equivalent on the server:

```bash
./androidlab.sh frida android-emu13-nostore /path/to/frida-server --start
```

## Connect ADB from the client

```bash
adb connect SERVER_INTERNAL_IP:13555
adb devices -l
export ANDROID_SERIAL=SERVER_INTERNAL_IP:13555
```

You can then use either `adb shell ...` with `ANDROID_SERIAL` set, or `adb -s SERVER_INTERNAL_IP:13555 ...` explicitly.

## Verify frida-server on Android

```bash
adb -s SERVER_INTERNAL_IP:13555 shell ls -l /data/local/tmp/frida-server
adb -s SERVER_INTERNAL_IP:13555 shell ps -A | grep frida
adb -s SERVER_INTERNAL_IP:13555 shell cat /data/local/tmp/frida.log
```

## Start frida-server manually

```bash
adb -s SERVER_INTERNAL_IP:13555 shell chmod 755 /data/local/tmp/frida-server
adb -s SERVER_INTERNAL_IP:13555 shell '/data/local/tmp/frida-server >/data/local/tmp/frida.log 2>&1 &'
```

## Connect Frida from the client

With ADB connected from the client:

```bash
frida-ps -Uai
```

If you prefer TCP forwarding:

```bash
adb -s SERVER_INTERNAL_IP:13555 forward tcp:27042 tcp:27042
adb -s SERVER_INTERNAL_IP:13555 forward tcp:27043 tcp:27043
frida-ps -H 127.0.0.1:27042
```

## Spawn or attach to an app

```bash
frida-ps -Uai
frida -U -f com.example.app
frida -U -n com.example.app
```

## Load a script

```bash
frida -U -f com.example.app -l script.js
frida -U -n com.example.app -l script.js
```

Minimal script:

```javascript
Java.perform(function () {
  console.log('Frida attached');
});
```

## Trace Java methods

```bash
frida-trace -U -f com.example.app -j 'com.example.*!*'
```

## Troubleshooting

### Version mismatch

Frida client and `frida-server` versions should match.

```bash
frida --version
adb -s SERVER_INTERNAL_IP:13555 shell /data/local/tmp/frida-server --version
```

### Permission denied

```bash
adb -s SERVER_INTERNAL_IP:13555 shell chmod 755 /data/local/tmp/frida-server
```

### Process not visible

```bash
adb -s SERVER_INTERNAL_IP:13555 shell ps -A | grep example
frida-ps -Uai
```

### Restart frida-server

```bash
adb -s SERVER_INTERNAL_IP:13555 shell pkill frida-server
adb -s SERVER_INTERNAL_IP:13555 shell '/data/local/tmp/frida-server >/data/local/tmp/frida.log 2>&1 &'
```
