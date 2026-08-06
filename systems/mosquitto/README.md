# Mosquitto

Status: Planned

Host: [docker-host](../docker-host/)

Eclipse Mosquitto MQTT broker. Handles pub/sub messaging for Raspberry Pi and Arduino projects on the LAN. Not proxied through Traefik — clients connect directly via TCP.

| Port | Protocol          | Use                                  |
| ---- | ----------------- | ------------------------------------ |
| 1883 | MQTT              | Pi/Arduino/ESP clients               |
| 9001 | MQTT over WebSocket | Browser-based clients and dashboards |

## Connecting

From any device on the LAN (replace IP with docker-host's):

```bash
# Publish
mosquitto_pub -h <docker-host-ip> -t homelab/test -m "hello"

# Subscribe
mosquitto_sub -h <docker-host-ip> -t homelab/#
```

## Topic conventions

Use a hierarchical namespace: `<location>/<device>/<measurement>`. Examples:

```
lab/pi-sensor-01/temperature
lab/pi-sensor-01/humidity
lab/esp32-desk/co2
```
