# Android Podman Lab Web Manager v35

This release adds a controlled noVNC wrapper with Back/Home/Recents phone controls using ADB keyevents.

# Android Podman Lab Web Manager v34

This release fixes sidebar navigation by using robust `/?view=...#...` URLs plus JavaScript enhancement and browser back/forward handling.

# Android Podman Lab Web Manager v32

This release adds background build/spawn jobs with live progress polling so long image builds do not block web requests.

# Android Podman Lab Web Manager v31

This release fixes SDK profile refresh, adds hardware profile controls, and adds build-before-spawn support.

# Android Podman Lab Web Manager v23

Primary display/control path: **scrcpy over ADB**.
Optional fallback path: **noVNC** for the full Android Emulator GUI/panel.

v23 fixes the web UI layer:

- noVNC URLs no longer use API numbers as ports when old records exist.
- Android version/API selector is server-rendered and does not depend on JavaScript.
- Copy command uses visible textareas and HTTP-safe fallbacks.
- Generated scrcpy commands use `--bit-rate`.
- Regression tests render the actual manager HTML and test the previous `server:33/vnc.html` failure.

## Install/update

```bash
mkdir -p "$HOME/AndroidLab"
tar -xzf android-podman-lab-web-manager-spawn-v23.tar.gz -C "$HOME/AndroidLab"
cd "$HOME/AndroidLab/android-podman-lab-web-manager-spawn-v23"

./web-install.sh \
  --api 33 \
  --target google_apis \
  --host 0.0.0.0 \
  --port 18080 \
  --public-host SERVER_INTERNAL_IP \
  --token 'change-me'
```

After update:

```bash
cd "$HOME/AndroidLab/android-podman-lab"
./androidlab.sh repair-records
scripts/regression-test.sh
```

## v23 visual polish

v23 adds a dark professional web-manager theme. It keeps the Full HD noVNC profile and all v17 safety hardening.

## v23 dashboard UI

v23 adds a sidebar dashboard layout, quick stats, and an instance filter/search box. The UI remains dependency-free and keeps all v18/v17 safety fixes.

## v23 documentation polish

v23 adds professional docs pages, an ADB cheat sheet, and a Frida cheat sheet. The web docs view now renders markdown into readable sections instead of raw text blocks.

## v23 docs rendering

v23 improves the docs page with categorized cards, a docs filter, and a better dependency-free markdown renderer supporting headings, lists, links, code fences, blockquotes, and simple markdown tables.


## v24 lifecycle controls

This version adds Stop/Start/State actions for emulator instances. Stopped instances remain listed in the web UI and keep their assigned ADB/noVNC ports, but the emulator process is not running.


## v26 code review hardening

This version adds preflight image checks before noVNC/headless mode switching, tighter device profile length validation, and web-install port validation.


## v27 profile selector review

This version makes the phone model selector more explicit, adds a Runtime profiles section, and adds SDK device-profile list refresh via `./androidlab.sh device-list`.


## v28 visible power controls

This version moves Start/Stop into a dedicated Power column near the left side of the Instances table so the controls are always visible instead of hidden in the far-right Actions column.


## v30 organized UI

This version reorganizes the web manager into focused dashboard sections, keeps the table format for detailed review, removes long command text from the table, and shows Start/Stop plus scrcpy commands in readable instance cards.
