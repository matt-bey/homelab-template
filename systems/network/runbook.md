# Network — Runbook

Operational notes for the home network. This is the file to open at 11pm when something is offline.

## Mesh management

The Google Wifi mesh is managed through the Google Home app on a phone or tablet. Account is the primary Google account on file (see `deployment.md`).

Common app-driven actions:

- View connected devices and their assigned IPs
- Add or update DHCP reservations
- Restart a node remotely
- Run a speed test from the main node
- View backhaul quality between nodes

## DHCP reservations

Most "prime" devices on the network have DHCP reservations assigned via the Google Home app. The reservations themselves live in the Google Wifi config — there is no exported source of truth in this repo today. See `deployment.md` for the captured-state table.

## Common procedures

### Power-cycle the internet path

Order matters when you're trying to recover from an internet outage:

1. Unplug the modem (Arris SB6190).
2. Unplug the main mesh node (Google Wifi, home office).
3. Wait 30 seconds.
4. Plug the modem back in. Wait until all four front lights are solid (typically 1-2 minutes).
5. Plug the main mesh node back in. Wait until its LED settles (typically another 1-2 minutes).
6. The two satellite mesh nodes should rejoin automatically.

### Verify a node has rejoined the mesh

Open the Google Home app, select the Wifi network, and check that all three points show as "Online" with a backhaul quality indicator. If a node shows as offline for more than a few minutes, power-cycle that node specifically (just unplug-replug it).

### Check what's actually connected

Google Home app → Wi-Fi → Devices. Each shows hostname (where known), MAC, IP, and which mesh point it's connected to.

## Failure modes seen / suspected

None recorded yet. Add entries here as they happen — date, symptom, what you tried, what worked.

## Things to check first when something feels slow

1. **Wi-Fi vs wired.** If only Wi-Fi clients are slow but wired clients are fine, the issue is mesh, not WAN. Try moving the affected client closer to a node, or check whether the entryway-closet node (wireless backhaul) is overloaded.
2. **Single device or all devices?** If only one device is slow, it's probably client-side, not network.
3. **Modem indicator lights.** All four steady → DOCSIS sync is fine. Blinking US/DS → channel renegotiation; if it persists, that's a sign of upstream noise or a modem hang (see `notes.md` on the SB6190 chipset history).
4. **Spectrum status page.** Outages happen. Check before chasing internal causes.
