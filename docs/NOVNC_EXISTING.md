# noVNC for Existing Emulators

A running headless emulator cannot get a noVNC HTML view attached live, because no GUI window exists.

The manager solves this by recreating the same emulator instance as noVNC mode while preserving its AVD data.

Web UI actions:

```text
Enable noVNC
Disable noVNC
```

CLI:

```bash
./androidlab.sh enable-novnc android-emu13-nostore
./androidlab.sh disable-novnc android-emu13-nostore
```

Optional fixed noVNC port:

```bash
./androidlab.sh enable-novnc android-emu13-nostore 13080
```
