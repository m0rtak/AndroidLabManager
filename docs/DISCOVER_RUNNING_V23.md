# Discover running pods in v23

If the manager records file is missing or stale after an update, an emulator pod can still be running while the web UI shows no instances.

v23 adds recovery/adoption:

```bash
./androidlab.sh discover-running
```

The command scans Podman pods labeled `android.lab=true`, detects the matching `NAME-emulator` container, extracts:

- ADB published port
- noVNC published port, if present
- Android API from container environment
- target from container environment
- mode from image/port information

Then it rebuilds `config/instances.tsv`.

The web UI also has a **Discover running pods** button in the Instances section.
