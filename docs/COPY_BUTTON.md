# Copy Button

Browsers expose `navigator.clipboard` only on HTTPS or trusted local origins.

Because this lab usually runs over plain HTTP on an internal IP, the web UI uses a fallback copy method:

1. Try `navigator.clipboard` when available.
2. Otherwise select the command input and use `document.execCommand('copy')`.
3. If blocked, show a prompt so you can copy manually.
