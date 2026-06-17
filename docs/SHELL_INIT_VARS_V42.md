# Shell init variable split v42

Version: 0.42.0  
Created: Petr Krivan  
Project: android lab manager

v42 centralizes shell-side default variables that were previously repeated across multiple scripts.

Server-side defaults now live in:

```text
scripts/init-vars.sh
```

Client-side Rocky scrcpy defaults now live in:

```text
client-rocky-scrcpy/client-init-vars.sh
```

Examples of centralized values:

- `LAB_BASE`
- `LAB_HOME`
- `LAB_DATA`
- `BIND_IP`
- `GPU_MODE`
- `ANDROIDLAB_DEFAULT_API`
- `ANDROIDLAB_DEFAULT_TARGET`
- `ANDROIDLAB_MANAGER_HOST_DEFAULT`
- `ANDROIDLAB_MANAGER_PORT_DEFAULT`
- `ANDROIDLAB_ADB_PORT_BASE`
- `ANDROIDLAB_NOVNC_PORT_BASE`
- `ANDROIDLAB_DEFAULT_DEVICE_PROFILE`

Script-local values such as positional arguments, parsed record fields, and temporary variables remain in the script where they are used.


Central helper functions:

- `androidlab_init_web_install_defaults`
- `androidlab_init_manager_env_defaults`
- `androidlab_client_init_runtime_defaults`
