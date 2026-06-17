# noVNC controls 500 fix v41

Version: 0.41.0  
Created: Petr Krivan  
Project: android lab manager

v41 fixes Internal Server Error cases when opening the controlled noVNC wrapper from an instance card.

Root causes:

1. The noVNC route referenced a stale helper name, `load_records()`, which no longer existed after record parsing was normalized around `rows()` / `record_by_name()`.
2. The local template helper used `name` as its first parameter:

```python
def render_ui_template(name, **ctx):
```

The noVNC route also passed the instance name as `name=...`, producing:

```text
TypeError: render_ui_template() got multiple values for argument 'name'
```

Fix: rename the helper parameter to `template_name`, so the noVNC template can safely receive `name` as context.

The route now uses `record_by_name(name)` and the renderer parameter is named `template_name`.
