# Security Notes

ADB is powerful. Treat access to `13555/tcp` as administrative access to the emulator.

Recommended policy:

- Bind ADB to an internal server IP, not a public interface.
- Restrict `13555/tcp` to your workstation IP or trusted subnet.
- Do not expose ADB to the public internet.

Example server install binding:

```bash
BIND_IP=192.168.1.50 ADB_PORT=13555 ./install.sh
```

firewalld example:

```bash
sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="YOUR_WORKSTATION_IP/32" port port="13555" protocol="tcp" accept' --permanent
sudo firewall-cmd --reload
```
