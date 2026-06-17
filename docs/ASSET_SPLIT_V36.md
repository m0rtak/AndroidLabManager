# Asset Split v36

v36 splits the manager UI shell into separate maintainable files:

- `manager/templates/base.html` contains the shared HTML page shell.
- `manager/templates/job.html` contains the async job progress card.
- `manager/templates/novnc.html` contains the controlled noVNC session card.
- `manager/static/app.css` contains the dark UI stylesheet.
- `manager/static/app.js` contains copy fallback, navigation, filtering, async job polling, and noVNC keyevent helpers.
- `manager/definitions.py` contains API presets, noVNC size profiles, and device profile presets.

The split source files keep the requested source-file metadata headers; Markdown documentation no longer carries those headers as of v44.
