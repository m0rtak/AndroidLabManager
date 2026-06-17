# Emulator modes

There are two process modes:

## headless

The emulator starts with `-no-window`. Use scrcpy for the screen.

## novnc

The emulator starts with a GUI window inside Xvfb. noVNC exposes that GUI in the browser.
ADB is still exposed, so scrcpy can also connect to a noVNC instance.

Important: noVNC cannot be attached live to a running headless `-no-window` emulator. Enabling noVNC recreates the emulator process in GUI/noVNC mode while keeping the AVD data volume.
