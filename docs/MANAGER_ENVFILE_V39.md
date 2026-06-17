# Manager environment file in base install v39

Version: 0.39.0  
Created: Petr Krivan  
Project: android lab manager

v39 makes `config/manager.env` part of the base install path as well as the web/service install path.

Before v39:

- `web-install.sh` / `scripts/install-manager-service.sh` generated manager service configuration.
- `androidlab.sh install` focused on emulator/image setup and did not necessarily create `config/manager.env`.

After v39:

- `androidlab.sh install` creates a default `config/manager.env` if one does not already exist.
- Default base-install manager values are local-safe: `MANAGER_HOST=127.0.0.1`, `MANAGER_PORT=18080`, empty token.
- `web-install.sh` and `scripts/install-manager-service.sh` still overwrite the file with the requested host, port, token, public host, and CSRF token.

This means `manager.env` is now present after either install path:

```bash
./androidlab.sh install --api 33 --target google_apis
# or
./web-install.sh --api 33 --target google_apis --host 0.0.0.0 --port 18080 --token 'change-me'
```
