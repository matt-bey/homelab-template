# Security Cameras — Hardware

## Google Nest (current — operational)

Five Wi-Fi devices on the Google Nest / Google Home ecosystem. Cloud-recorded (Nest Aware), viewed through the Google Home app. All are wireless IoT clients on `<iot-ssid>` (VLAN 30).

| Device         | Model                                | Location               | Notes                                |
| -------------- | ------------------------------------ | ---------------------- | ------------------------------------ |
| Indoor camera  | Nest Cam Indoor 1st gen (NC1102ES)   | Evelyn's room          | 1080p, wired-power, 2015-era         |
| Indoor camera  | Nest Cam Indoor 1st gen (NC1102ES)   | Leo's room             | 1080p, wired-power, 2015-era         |
| Indoor camera  | Nest Cam Indoor 1st gen (NC1102ES)   | Kenna's room           | 1080p, wired-power, 2015-era         |
| Indoor camera  | Nest Cam Indoor 1st gen (NC1102ES)   | Basement playroom      | 1080p, wired-power, 2015-era         |
| Video doorbell | Nest Hello, wired 1st gen (NC5100US) | Front entry (outdoor)  | Rebranded "Nest Doorbell (wired)"    |

The doorbell name wrinkle: the box and original release call it **Nest Hello** (model NC5100US, 2018); Google retroactively renamed it **"Nest Doorbell (wired)"** in the Google Home app — same hardware. The four indoor units are the original 2015 **Nest Cam Indoor** (the magnetic-base cylinder), which Google Home also just labels "Nest Cam"; the NC1102ES model number disambiguates it from later Nest Cam generations.

None of these five support local recording — they are cloud-only by design, which is the hardware reason they must stay on the egress-allowed IoT VLAN (see below).


## UniFi Protect (future — planned)


## Why two ecosystems on two VLANs

The Nest devices and the future UniFi cameras land on different VLANs because they need *opposite* egress policies — a clean illustration of the network's "VLAN by policy, not by device kind" rule:

- **Nest → IoT (VLAN 30).** Cloud cameras: recording and viewing depend on Google's cloud, so they require internet egress. IoT is exactly that policy — egress allowed, cannot initiate into Core/Clients.
- **UniFi Protect → Cameras (VLAN 50).** Local NVR: footage stays on the UDM-SE, so these are blocked from internet egress entirely (NVR-only). That stricter policy is what earns VLAN 50 its own slot.

Same device kind, opposite policy, different VLAN.
