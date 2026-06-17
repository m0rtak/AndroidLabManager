# Architecture

## Final decision

The lab uses ADB and scrcpy instead of browser screen streaming.

```text
Server
└── Podman pod: android-emu13-nostore
    └── Android Emulator API 33, google_apis, x86_64
        └── ADB exposed on SERVER_INTERNAL_IP:13555

Rocky workstation
└── Podman scrcpy client
    ├── adb
    ├── scrcpy
    ├── Wayland/X11 socket mount
    └── connects to SERVER_INTERNAL_IP:13555
```

## Why not WebRTC/noVNC

- noVNC was too slow for daily interaction.
- Browser WebRTC worked but performed poorly and required fragile UI/network handling.
- scrcpy gives a native, low-latency Android screen path.

## GPU policy

The emulator uses:

```text
GPU_MODE=swiftshader
```

This keeps the server GPU free for AI workloads.

## Security boundary

ADB is powerful. Keep `13555/tcp` restricted to the trusted internal network or a specific workstation IP.
