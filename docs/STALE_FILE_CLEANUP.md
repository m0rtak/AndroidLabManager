# Stale file cleanup

Older bundles installed helper scripts such as:

- `scripts/02-up.sh`
- `scripts/05-client-commands.sh`

Those files are obsolete and may still contain flags unsupported by older Rocky scrcpy versions.

Run:

```bash
cd "$HOME/AndroidLab/android-podman-lab"
scripts/clean-stale-files.sh
scripts/regression-test.sh
```

v23 installer replaces managed source directories instead of overlaying them, so stale scripts should not remain after a normal `web-install.sh` update.
