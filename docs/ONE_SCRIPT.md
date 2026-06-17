# One Script Usage

Main command:

```bash
./androidlab.sh menu
```

Install default API 33 image and default emulator:

```bash
./androidlab.sh install --api 33 --target google_apis
```

Install without default emulator:

```bash
./androidlab.sh install --api 33 --target google_apis --no-default
```

Build/update another Android API image:

```bash
./androidlab.sh build-api 35 google_apis x86_64
./androidlab.sh update-api 36 google_apis_playstore x86_64
```

Create emulator:

```bash
./androidlab.sh create android-emu35 13556 headless 35 google_apis
```

Create noVNC emulator:

```bash
./androidlab.sh create android-emu35-panel 13557 novnc 35 google_apis 13081
```

List:

```bash
./androidlab.sh list
```

Delete and wipe:

```bash
./androidlab.sh delete android-emu35 --wipe
```

Clean all and wipe:

```bash
./androidlab.sh clean-all --wipe
```

Manager UI:

```bash
./androidlab.sh manager
```
