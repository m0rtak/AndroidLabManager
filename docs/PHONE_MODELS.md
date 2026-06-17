# Phone Model Profiles

New emulator instances can choose an Android Emulator device profile such as `pixel`, `pixel_5`, `pixel_6`, or `pixel_6_pro`.

The selected profile is passed to `avdmanager create avd --device <profile>` as `DEVICE_PROFILE`. It is used only when the AVD is first created. If an emulator already has persistent AVD data, changing this value later will not reshape the existing AVD; create a new instance or wipe/recreate the instance if you need a different hardware profile.

## CLI examples

```bash
./androidlab.sh spawn android-pixel6 headless 33 google_apis pixel_6
./androidlab.sh create android-pixel6-panel 13556 novnc 33 google_apis 13080 pixel_6
```

## Web UI

Use **Phone model** in the Spawn or Manual Create form. A custom profile field is available for SDK profiles not listed in the dropdown.
