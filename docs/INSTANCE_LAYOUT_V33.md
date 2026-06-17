# Instance layout polish

v33 changes the Instances view to avoid malformed wrapped rows.

## What changed

- Instance cards are now the primary control surface.
- The table is compact and read-only.
- Long scrcpy commands are shown only in cards, not in table cells.
- Start/Stop, noVNC controls, hardware controls, and danger actions are grouped into card sections.
- Table cells use no-wrap with horizontal scrolling so text does not collapse vertically.

## Sections in each instance card

| Section | Purpose |
|---|---|
| Access | Start/Stop, scrcpy command, noVNC links |
| Runtime controls | noVNC mode/size and hardware profile restart |
| Danger zone | Delete and wipe |
