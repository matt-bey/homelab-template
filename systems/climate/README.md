# Climate

Status: Operational

Home heating/cooling control and room-level temperature sensing. Currently a single Google Nest Learning Thermostat (3rd gen) paired with three Nest Temperature Sensors, managed through the Nest iOS app. It shares the Google Nest ecosystem and Nest Aware subscription with the [security-cameras](../security-cameras/README.md) Nest fleet.

This system is a tenant of the [network](../network/README.md) fabric, not network infrastructure itself. The thermostat is a wireless IoT client on `<iot-ssid>` (VLAN 30); the temperature sensors pair to the thermostat over Bluetooth/Thread and are not network clients.

