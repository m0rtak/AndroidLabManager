# Dynamic noVNC scaling and size profiles

There are two different kinds of noVNC sizing:

1. **Browser-side scaling**: this is dynamic and does not restart the emulator.
   - `1:1` opens noVNC without scaling.
   - `fit` opens noVNC with browser fit-to-window scaling.
   - `remote` asks noVNC/VNC to resize the remote desktop. This depends on VNC server support and may not always work with x11vnc/Xvfb.

2. **Actual virtual desktop / emulator skin size**: this requires recreating the noVNC-mode emulator process.
   - AVD data is preserved.
   - The emulator process is restarted.

The web manager now has an **Apply size profile** control for noVNC instances.

Profiles:

- Compact: `1024x768` desktop, `420x780` emulator skin
- Normal: `1280x900` desktop, `540x960` emulator skin
- Large: `1366x900` desktop, `720x1280` emulator skin
- Extra large: `1600x1000` desktop, `720x1280` emulator skin
- Full HD phone: `1920x1080` desktop, `1080x1920` emulator skin, emulator window scaled `0.55`

For custom CLI values:

```bash
export NOVNC_SCREEN=1366x900x24
export EMULATOR_SKIN=720x1280
export EMULATOR_SCALE=

# Full HD phone example:
export NOVNC_SCREEN=1920x1080x24
export EMULATOR_SKIN=1080x1920
export EMULATOR_SCALE=0.55
./androidlab.sh enable-novnc android-emu13-nostore
```
