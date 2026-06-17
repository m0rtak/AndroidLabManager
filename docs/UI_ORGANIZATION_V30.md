# UI Organization v30

v30 reorganizes the manager into focused dashboard sections instead of one long scrolling page.

## Sections

- **Dashboard**: summary and feature status.
- **Spawn**: auto-port and manual emulator creation.
- **Profiles**: Android API images, SDK system-image refresh, and phone/device profiles.
- **Instances**: visible instance cards plus a readable compact table.
- **Frida**: upload/start helper.

## Readability changes

The detailed table keeps a table layout but removes the long scrcpy command column. The command is now shown in each instance card, while the table focuses on compact fields such as status, power, mode, ports, API, target, and device.
