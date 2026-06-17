# Instance Lifecycle

The manager can stop and start emulator instances without deleting AVD data.

## Web UI

Open the manager, go to **Instances**, then use:

- **Stop** to stop the Podman pod and free CPU/RAM runtime load.
- **Start** to start the same pod again.
- **Delete** to remove the pod while keeping AVD data.
- **Wipe** to remove the pod and delete the AVD data directory.

Stopped instances remain in `config/instances.tsv`, so the manager still shows them and preserves their ADB/noVNC port assignments.

## CLI

```bash
./androidlab.sh stop android-emu13-nostore
./androidlab.sh start android-emu13-nostore
./androidlab.sh state android-emu13-nostore
```

## Notes

A stopped instance keeps its record, but it does not run the emulator process. If the Podman pod is deleted, use **Delete** or recreate/spawn a new instance.
