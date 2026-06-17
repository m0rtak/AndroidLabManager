# Manager environment file early install v40

v40 moves `config/manager.env` creation to the start of the install flow.

Why: v39 created `manager.env` near the end of `androidlab.sh install`, after image build/default emulator creation. If that long step failed or exited early, the environment file was still missing.

Fixes:

- `androidlab.sh install` now ensures `config/manager.env` before `build_api` runs.
- `web-install.sh` also writes the requested manager environment before starting the long Android image install/build path.
- `scripts/install-manager-service.sh` still forces a final rewrite with the requested service values.

This makes `manager.env` exist even if emulator image build fails later.
