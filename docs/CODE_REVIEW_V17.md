# Code review fixes in v23

v23 is a web-manager safety review release after v16 UI polish.

Fixes:

- Web manager now records non-zero CLI exit codes in command output.
- noVNC resize stops after a failed `disable-novnc`; it no longer blindly runs `enable-novnc` after a failed first step.
- Unknown action values in `/action` no longer fall through to delete.
- Web routes validate mode/API/target before calling CLI, in addition to CLI-side validation.
- Full HD profile and modern UI from v16 are retained.

Remaining limits:

- Full emulator/KVM boot testing still must be done on the target server.
- Manager still shells out to `androidlab.sh`; this is intentional for a simple local/internal manager, but it should remain protected by Basic Auth and network firewalling.
