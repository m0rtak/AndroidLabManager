# Manager environment file creation v38

v38 fixes missing `config/manager.env` after installation or service repair.

Changes:

- Added `scripts/ensure-manager-env.sh`.
- `scripts/install-manager-service.sh` now calls the helper with `--force` and fails if `manager.env` is not created.
- The generated systemd user unit now runs `ExecStartPre=.../scripts/ensure-manager-env.sh` before starting the manager.
- `scripts/run-manager.sh` also calls the helper and sources `config/manager.env` as a final fallback.

Repair command:

```bash
cd "$HOME/AndroidLab/android-podman-lab"
scripts/install-manager-service.sh 0.0.0.0 18080 'change-me' SERVER_INTERNAL_IP
systemctl --user daemon-reload
systemctl --user restart androidlab-manager.service
```

Verify:

```bash
ls -l "$HOME/AndroidLab/android-podman-lab/config/manager.env"
systemctl --user cat androidlab-manager.service
```
