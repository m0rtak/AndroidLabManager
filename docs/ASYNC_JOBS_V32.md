# Background jobs and live progress

v32 moves long image builds out of the web request path.

## Why

Building Android SDK/emulator images can take long enough for a browser, proxy, or Flask request to time out. The manager now starts a background job and immediately returns a progress page.

## What runs asynchronously

- **Build/update image** from Profiles
- **Build/update image before spawn** from Spawn
- **Build/update image before create** from Manual Create

## Where logs are stored

Job metadata and logs live under:

```text
$HOME/AndroidLab/android-podman-lab/config/jobs/
```

Each job has:

```text
<job-id>.json
<job-id>.status
<job-id>.log
```

The browser polls:

```text
/job_status/<job-id>
```

## Behavior

A build-before-spawn job runs two steps:

```text
1. ./androidlab.sh build-api API TARGET x86_64
2. ./androidlab.sh spawn NAME MODE API TARGET DEVICE_PROFILE
```

The second step only runs if the first step succeeds.
