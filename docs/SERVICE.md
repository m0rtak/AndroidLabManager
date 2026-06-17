# systemd User Service

Install service:

```bash
scripts/install-manager-service.sh 0.0.0.0 18080 'change-me'
```

Status:

```bash
systemctl --user status androidlab-manager.service
```

Logs:

```bash
journalctl --user -u androidlab-manager.service -f
```

Remove service:

```bash
scripts/remove-manager-service.sh
```
