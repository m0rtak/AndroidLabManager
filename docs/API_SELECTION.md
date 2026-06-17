# Android API Selection and Updates

The image build is API-specific. To add or update an API image, run:

```bash
./androidlab.sh update-api API TARGET x86_64
```

Examples:

```bash
./androidlab.sh update-api 33 google_apis x86_64
./androidlab.sh update-api 35 google_apis x86_64
./androidlab.sh update-api 36 google_apis_playstore x86_64
```

Supported targets depend on what `sdkmanager` can download:

```text
google_apis
google_apis_playstore
```

Use `google_apis` for pentest work unless you specifically need Play Store.
