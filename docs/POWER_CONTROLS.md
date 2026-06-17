# Power Controls

Each instance row has a dedicated **Power** column with **Start** and **Stop** buttons.

These controls call:

```bash
./androidlab.sh start NAME
./androidlab.sh stop NAME
```

Stopped instances remain in `config/instances.tsv`, keep their assigned ADB/noVNC ports, and can be started later.

If a pod is missing, the Power buttons are disabled and the row should be repaired or deleted.
