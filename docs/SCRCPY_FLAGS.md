# scrcpy flags

Rocky/EPEL commonly provides scrcpy 1.25. For that version use:

```bash
androidlab-scrcpy SERVER:13555 --max-size 1280 --bit-rate 4M --stay-awake
```

If an old local launcher still fails, reinstall the bundled client:

```bash
cd "$HOME/AndroidLab/android-podman-lab/client-rocky-scrcpy"
./install-client.sh
```
