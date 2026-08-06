# Climate — Hardware

## Nest Learning Thermostat (3rd gen)

| Attribute    | Value                                                |
| ------------ | ---------------------------------------------------- |
| Device       | Nest Learning Thermostat                             |
| Generation   | 3rd gen (Display model 3.4 / Backplate model 5.4)    |
| Retail SKU   | T300x / T301x family — exact color/SKU not captured  |
| Connectivity | Wi-Fi (IoT VLAN) + Bluetooth/Thread to sensors       |
| Management   | Nest iOS app                                         |

Generation is read from the internal hardware strings: a Display model beginning with `3` is the 3rd-generation Nest Learning Thermostat (2015). The consumer-facing SKU for 3rd gen is the T300x/T301x family (color/region variants); capture the exact SKU off the unit if it's ever needed.

## Nest Temperature Sensors

Three battery-powered Nest Temperature Sensors paired to the thermostat for room-level readings. They connect to the thermostat over **Bluetooth/Thread, not Wi-Fi** — so they are satellites of the thermostat, not independent network clients (no MAC on the LAN).

| Location      | Device                  |
| ------------- | ----------------------- |
| Kenna's room  | Nest Temperature Sensor |
| Leo's room    | Nest Temperature Sensor |
| Evelyn's room | Nest Temperature Sensor |

These three rooms also have Nest Cam Indoor units — see [../security-cameras/hardware.md](../security-cameras/hardware.md).
