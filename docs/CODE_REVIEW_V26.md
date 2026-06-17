# Code Review v26

This review focused on the v25 phone-model release.

## Findings fixed

| Severity | Area | Finding | Fix |
|---|---|---|---|
| High | noVNC mode switch | `enable-novnc` / `disable-novnc` could delete the current pod before discovering the target image was missing. | Preflight the target image before deleting/recreating. |
| Medium | Device profile validation | Device profile accepted any length matching the character regex. | Added 64-character limit in CLI and web validation. |
| Medium | Web install | Manager port was not validated before writing service config. | Added numeric/range validation. |
| Medium | noVNC mode switch | Explicit noVNC port could be duplicate and only fail after deleting the existing pod. | Added pre-delete port allocation check. |

## Notes

Changing the phone model does not mutate an existing AVD. The profile is used when the AVD is first created by `avdmanager`.
