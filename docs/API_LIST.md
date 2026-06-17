# API List Refresh

The web UI includes **Refresh available API/system-image list**.

It runs:

```bash
./androidlab.sh api-list
```

The command uses an already-built Android emulator image to run `sdkmanager --list`, extracts available x86_64 system images, and saves them to:

```text
config/api-list.txt
```

Build at least one API image first, usually API 33 from install.
