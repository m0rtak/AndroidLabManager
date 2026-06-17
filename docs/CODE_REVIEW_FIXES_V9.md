# Code review fixes v23

Findings fixed:

- `repair-records`, `enable-novnc`, and `disable-novnc` parsed old 6-column records incorrectly.
- `repair-records` now normalizes records before deduplication.
- `create` validates API, target, arch, ports, and image existence before creating a pod.
- Web destructive POST routes now include a CSRF token when auth is enabled.
- Manager systemd service now uses an EnvironmentFile instead of raw inline Environment values.
- `__pycache__` is excluded from the package.
- Regression tests check rendered HTML, record normalization, CSRF presence, no bad scrcpy flag, no pycache, and no bad noVNC URL.
