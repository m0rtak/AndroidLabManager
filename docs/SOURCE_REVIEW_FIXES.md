# Source Review Fixes

## noVNC blank page/display

The noVNC link now uses:

```text
/vnc.html?autoconnect=true&resize=scale&path=websockify
```

The noVNC container also starts a diagnostic xterm inside Xvfb. If noVNC opens but no emulator appears, the xterm proves the VNC path works and the emulator GUI startup is the remaining issue.

Logs inside the noVNC emulator container:

```text
/tmp/xvfb.log
/tmp/fluxbox.log
/tmp/x11vnc.log
/tmp/websockify.log
/tmp/xterm.log
```

## Duplicate ports

Port checks now inspect the records file by field:

```text
field 3 = ADB port
field 4 = noVNC port
```

Manual creation now refuses already allocated/listening ports.

## scrcpy compatibility

Generated web commands use scrcpy 1.25-compatible syntax:

```bash
androidlab-scrcpy SERVER:PORT --max-size 1280 --bit-rate 4M --stay-awake
```
