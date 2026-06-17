# Idempotent install

The installer is safe to run over an existing lab.

Managed source directories are replaced so stale scripts from older releases are removed, but these are preserved:

- `config/instances.tsv`
- `uploads/`
- `.venv/`
- emulator data under `$HOME/AndroidLab/data`

If the default emulator already exists, or if ADB port `13555` is already listening, install skips default emulator creation instead of failing.

To create another emulator, use the web UI spawn form or:

```bash
./androidlab.sh spawn android-emu13-extra headless 33 google_apis
./androidlab.sh spawn android-emu13-panel novnc 33 google_apis
```

To recreate everything from scratch:

```bash
./androidlab.sh clean-all
```

To wipe emulator data too:

```bash
./androidlab.sh clean-all --wipe
```
