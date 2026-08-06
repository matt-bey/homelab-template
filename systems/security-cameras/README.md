# Security Cameras

Status: Operational


Home video surveillance. Today this is a Google Nest ecosystem — 4 indoor cameras plus 1 outdoor video doorbell — cloud-recorded (Nest Aware) and viewed through the Google Home app. The Nest fleet shares its Google Nest ecosystem and Nest Aware subscription with the [climate](../climate/README.md) system's thermostat. A future UniFi Protect deployment (cameras recording locally to the UDM-SE NVR) will be added *alongside* the Nest fleet, not replace it; the two ecosystems coexist.

This system is a tenant of the [network](../network/README.md) fabric, not network infrastructure itself. The current Nest devices are managed through the Google Home / Nest app; the future UniFi cameras are managed through UniFi Protect, a separate application from the UniFi Network app that runs the network gear.

The Nest devices are wireless IoT clients on `<iot-ssid>` (VLAN 30); the planned UniFi Protect cameras will land on the dedicated Cameras VLAN 50. They sit on different VLANs *because they need opposite egress policies* — see [hardware.md](hardware.md).


