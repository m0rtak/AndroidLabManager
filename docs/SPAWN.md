# Spawning Emulator Instances

The web UI has a **Spawn emulator instance** form.

It automatically allocates:

```text
ADB ports from 13555 upward
noVNC ports from 13080 upward
```

## CLI

Spawn headless/scrcpy emulator:

```bash
./androidlab.sh spawn android-emu35 headless 35 google_apis
```

Spawn noVNC emulator:

```bash
./androidlab.sh spawn android-emu35-panel novnc 35 google_apis
```

List assigned ports:

```bash
./androidlab.sh list
```

Use scrcpy:

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:ADB_PORT
```

Open noVNC:

```text
http://SERVER_INTERNAL_IP:NOVNC_PORT/vnc.html
```
