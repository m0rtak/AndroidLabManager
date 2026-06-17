# Raw ADB Client Workflow v43

v43 updates the ADB documentation to use raw `adb` commands from the client/workstation.

Reason:

- The emulator runs on the server.
- Each emulator instance publishes an ADB TCP port on the server.
- The Rocky client connects directly to `SERVER_INTERNAL_IP:ADB_PORT`.
- Documentation should not hide that network boundary behind an Android Lab ADB wrapper.

Canonical pattern:

```bash
adb connect SERVER_INTERNAL_IP:13555
adb -s SERVER_INTERNAL_IP:13555 shell getprop ro.build.version.release
adb -s SERVER_INTERNAL_IP:13555 install app.apk
```

Optional shell shortcut:

```bash
export ANDROID_SERIAL=SERVER_INTERNAL_IP:13555
adb shell getprop ro.product.model
```

Manager-side commands such as `./androidlab.sh start INSTANCE`, `./androidlab.sh stop INSTANCE`, and `./androidlab.sh key INSTANCE back` are still server-side lifecycle/control commands. They are separate from the client ADB workflow.
