# Frida Cheat Sheet

Frida workflow for Android Lab emulators.

## Upload frida-server from the web manager

Use the **Frida upload** panel in the web UI:

1. Pick the emulator instance.
2. Upload a matching `frida-server` binary for Android x86_64.
3. Check **start** if you want the manager to start it automatically.

CLI equivalent:

```bash
./androidlab.sh frida android-emu13-nostore /path/to/frida-server --start
```

## Verify frida-server on Android

```bash
androidlab-adb SERVER:13555 shell ls -l /data/local/tmp/frida-server
androidlab-adb SERVER:13555 shell ps -A | grep frida
androidlab-adb SERVER:13555 shell cat /data/local/tmp/frida.log
```

## Start frida-server manually

```bash
androidlab-adb SERVER:13555 shell chmod 755 /data/local/tmp/frida-server
androidlab-adb SERVER:13555 shell '/data/local/tmp/frida-server >/data/local/tmp/frida.log 2>&1 &'
```

## Connect from client

If ADB is connected from the client:

```bash
adb connect SERVER:13555
frida-ps -Uai
```

If you prefer TCP forwarding:

```bash
adb -s SERVER:13555 forward tcp:27042 tcp:27042
adb -s SERVER:13555 forward tcp:27043 tcp:27043
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
androidlab-adb SERVER:13555 shell /data/local/tmp/frida-server --version
```

### Permission denied

```bash
androidlab-adb SERVER:13555 shell chmod 755 /data/local/tmp/frida-server
```

### Process not visible

```bash
androidlab-adb SERVER:13555 shell ps -A | grep example
frida-ps -Uai
```

### Restart frida-server

```bash
androidlab-adb SERVER:13555 shell pkill frida-server
androidlab-adb SERVER:13555 shell '/data/local/tmp/frida-server >/data/local/tmp/frida.log 2>&1 &'
```
