# Asset Split v36

Version: 0.36.0  
Created: Petr Krivan  
Project: android lab manager

v36 splits the manager UI shell into separate maintainable files:

- `manager/templates/base.html` contains the shared HTML page shell.
- `manager/templates/job.html` contains the async job progress card.
- `manager/templates/novnc.html` contains the controlled noVNC session card.
- `manager/static/app.css` contains the dark UI stylesheet.
- `manager/static/app.js` contains copy fallback, navigation, filtering, async job polling, and noVNC keyevent helpers.
- `manager/definitions.py` contains API presets, noVNC size profiles, and device profile presets.

Each new split file includes this header block:

```text
Version: 0.36.0
Created: Petr Krivan
Project: android lab manager
```
