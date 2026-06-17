# Navigation fix in v23

The v21 sidebar used page-local anchors such as `#spawn` and `#instances`.

That worked on the dashboard page, but failed from `/docs` pages because those anchors do not exist there.

v23 changes the sidebar links to absolute dashboard anchors:

- `/#spawn`
- `/#api`
- `/#instances`
- `/#frida`

It also adds a direct Dashboard link.
