# Manager EnvironmentFile hardening v37

v37 fixes a startup failure where `androidlab-manager.service` could fail before launching the manager when systemd could not load `config/manager.env`.

The generated user unit now includes:

```ini
Environment=LAB_HOME=...
Environment=LAB_DATA=...
EnvironmentFile=-.../config/manager.env
```

The leading `-` on `EnvironmentFile` tells systemd to ignore a missing environment file instead of failing service load. The installer still creates `config/manager.env` with the selected host, port, token, public host, and CSRF token.

To repair an existing install:

```bash
cd "$HOME/AndroidLab/android-podman-lab"
scripts/install-manager-service.sh 0.0.0.0 18080 'change-me' SERVER_INTERNAL_IP
systemctl --user daemon-reload
systemctl --user restart androidlab-manager.service
```
