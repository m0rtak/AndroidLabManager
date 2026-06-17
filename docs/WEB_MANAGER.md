# Web Manager Usage

Install and start the web manager:

```bash
./web-install.sh --api 33 --target google_apis --host 0.0.0.0 --port 18080 --token 'change-me'
```

Open:

```text
http://SERVER_INTERNAL_IP:18080
```

The web manager can:

- Build/update API images.
- Create headless/scrcpy emulators.
- Create noVNC emulators.
- Delete/wipe emulators.
- Clean all / wipe all.
- Upload and start frida-server.

## Security

Bind to an internal IP or protect access with firewall rules. The manager can run Podman commands and should not be exposed publicly.

Basic Auth is enabled when `MANAGER_TOKEN` or `--token` is set.
