# noVNC Fallback

Use noVNC when you need the full Android Emulator GUI panel.

Create noVNC emulator:

```bash
./androidlab.sh create android-emu13-panel 13556 novnc 33 google_apis 13080
```

Open:

```text
http://SERVER_INTERNAL_IP:13080/vnc.html
```

Use scrcpy for daily interaction and noVNC only when you need the emulator panel.
