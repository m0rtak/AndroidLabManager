# Regression tests

This package includes `scripts/regression-test.sh` for static checks before release/use.

It checks:

- all shell scripts parse with `bash -n`
- manager Python parses with `py_compile`
- no unsupported scrcpy bitrate flag is present in active source/docs
- generated manager page contains `--bit-rate` and not the unsupported newer flag
- copy code contains HTTP fallback paths
- API presets include Android 13 through Android 16
- port allocation helpers are present

Run:

```bash
cd "$HOME/AndroidLab/android-podman-lab"
scripts/regression-test.sh
```
