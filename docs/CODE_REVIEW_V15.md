# Code review fixes in v23

v23 is a hardening release after reviewing v14 source.

Fixes:

- `create` now refuses duplicate instance names before creating pods.
- `create` refuses pre-existing Podman pods with the same name.
- If container startup fails after pod creation, the new pod is removed.
- `LAB_HOME` and `LAB_DATA` are guarded against dangerous values like `/` or `$HOME` before managed `rm -rf` operations.
- systemd manager environment values reject whitespace/comment characters to avoid broken `EnvironmentFile` parsing.
- web install warns if no manager token is configured.
- enabling noVNC from the instance row now accepts the selected noVNC size profile.
- noVNC resize validates the noVNC port before restart/recreate.
