# Home Automation

Status: Planned

Host: [docker-host](../docker-host/)

Local-first home automation control plane: Home Assistant running as a container on `docker-host`, with a single Z-Wave coordinator for physical devices. Acts as the device/protocol abstraction layer — [n8n](../n8n/) stays the cross-service workflow layer and triggers HA over its REST API.

First and motivating integration: observe the (dumb, UL-listed) BRK hardwired smoke/CO detectors via a Zooz ZEN55 Z-Wave bridge and surface smoke/CO events into [monitoring](../monitoring/) → [ntfy](../ntfy/). Life-safety stays local and dumb; HA only observes.

