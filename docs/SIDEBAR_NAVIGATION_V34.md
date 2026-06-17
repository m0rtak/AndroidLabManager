# Sidebar navigation fix

v34 makes sidebar navigation robust.

## Problem

The dashboard originally used hash-only links and JavaScript-only view switching. In some states, such as result/progress pages or browser history navigation, the click could be intercepted even when the target view was not present.

## Fix

Sidebar links now use real view URLs:

```text
/?view=spawn#spawn
/?view=profiles#profiles
/?view=instances#instances
```

The JavaScript still switches sections instantly on the dashboard, but if the target view is not present, the browser performs a normal navigation to the dashboard view URL.

Browser back/forward is also handled with `popstate`.
