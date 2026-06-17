# Copy-pasteable scrcpy commands

The web manager shows a client command for every emulator instance:

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:ADB_PORT
```

Use `--public-host` during install so the UI generates the correct hostname/IP:

```bash
./web-install.sh --public-host 192.168.1.50 --token 'change-me'
```

or for an internal DNS name:

```bash
./web-install.sh --public-host androidlab.internal --token 'change-me'
```
