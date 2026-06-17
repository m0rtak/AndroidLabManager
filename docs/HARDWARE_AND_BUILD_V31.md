# Hardware profiles and build-before-spawn

v31 adds hardware controls and a safer image workflow.

## Hardware overrides

New instances can set:

| Field | Default | Range |
|---|---:|---:|
| CPU cores | 2 | 1-16 |
| RAM MB | 4096 | 512-65536 |
| VM heap MB | 512 | 64-8192 |
| Partition MB | 4096 | 1024-131072 |

The values are passed into the emulator container and applied to the AVD config before boot:

```bash
CPU_CORES=4 RAM_MB=8192 VM_HEAP_MB=512 PARTITION_SIZE=8192 ./androidlab.sh spawn android-api33 headless 33 google_apis pixel_6
```

For an existing instance, use **Apply HW + restart** in the Instances view or:

```bash
CPU_CORES=4 RAM_MB=8192 VM_HEAP_MB=512 PARTITION_SIZE=8192 ./androidlab.sh apply-hw android-emu13-nostore
```

This restarts the instance while keeping the AVD data.

## Missing image behavior

If a selected API/target image is not built yet, the manager now shows a clear missing-image message. Enable **Build/update image before spawn** to build the API image and spawn the instance in one action.

## SDK list refresh fix

The SDK package and device-profile refresh commands now override the emulator image entrypoint with `--entrypoint bash`, so they no longer accidentally start `/entrypoint.sh` and fail with `AVD_NAME is required`.
