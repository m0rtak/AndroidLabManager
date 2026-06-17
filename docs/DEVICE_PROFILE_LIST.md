# Device Profile List

The web manager includes built-in phone model presets and can refresh the actual Android Emulator device profiles from the SDK image.

Use **Runtime profiles → Refresh SDK device-profile list** in the web UI, or run:

```bash
./androidlab.sh device-list
```

This runs `avdmanager list device` inside a built emulator image and saves the result to:

```text
config/device-list.txt
```

The selector keeps built-in Pixel presets visible even when the SDK list has not been refreshed.
