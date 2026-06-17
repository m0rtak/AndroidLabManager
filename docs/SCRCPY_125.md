# scrcpy 1.25 Compatibility

Rocky's scrcpy may be version 1.25. That version does not support:

```text
[newer scrcpy bitrate flag]
--no-audio
```

Use:

```text
--bit-rate
```

The web UI now generates commands like:

```bash
androidlab-scrcpy SERVER_INTERNAL_IP:13555 --max-size 1280 --bit-rate 4M --stay-awake
```
