# noVNC display size

noVNC can make the emulator look tiny if the virtual X desktop is too large and the browser scales it down.

v23 changes the defaults to a smaller virtual desktop:

- `NOVNC_SCREEN=1280x900x24`
- `EMULATOR_SKIN=540x960`
- `EMULATOR_SCALE=` unset by default

The web UI now opens the noVNC **1:1** URL by default:

```text
/vnc.html?autoconnect=true&resize=off&path=websockify
```

A secondary `scaled` link is still available if you prefer fit-to-window scaling.

To customize size before creating or enabling a noVNC instance:

```bash
export NOVNC_SCREEN=1366x900x24
export EMULATOR_SKIN=720x1280
export EMULATOR_SCALE=0.85
./androidlab.sh spawn android-emu13-panel novnc 33 google_apis
```

For an existing headless instance:

```bash
export NOVNC_SCREEN=1366x900x24
export EMULATOR_SKIN=720x1280
./androidlab.sh enable-novnc android-emu13-nostore
```

Changing these values requires recreating/restarting the noVNC-mode emulator. The AVD data is preserved unless you explicitly wipe it.
