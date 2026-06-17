# Web UI fixes v9

Fixed issues:

- Old six-column `instances.tsv` rows are normalized so API numbers are not treated as noVNC ports.
- noVNC links are only shown for `novnc` mode rows with a real noVNC port.
- Android version/API presets are rendered server-side, not dependent on JavaScript.
- scrcpy commands use `--bit-rate`, compatible with scrcpy 1.25.
- Commands are shown in textareas. Click a command and press Ctrl+C if browser copy APIs are blocked on plain HTTP.
- Regression tests render the manager HTML with a fake old record and verify that `http://server:33/vnc.html` is not generated.
