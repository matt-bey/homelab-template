# OTA TV — Hardware

## Antenna

| Field       | Value                                                                  |
| ----------- | ---------------------------------------------------------------------- |
| Model       | RCA ANT705E — compact directional (Yagi-style), outdoor/attic          |
| Form factor | Short-boom UHF Yagi                                                    |
| Rated range | 70 mi                                                                  |
| Band        | UHF-biased (strong suit); limited VHF-High                             |
| Location    | Attic, mounted on a custom wooden shim bracket aimed at **228° (WSW)** |
| Aim         | 228° covers all five WSW channels (NBC/CBS/FOX/CW/ABC, spanning 226–235°) within ±5° on-axis |

## Tuner — SiliconDust HDHomeRun

| Field    | Value                                                            |
| -------- | --------------------------------------------------------------- |
| Model    | SiliconDust HDHomeRun FLEX 4K (HDFX-4K)                          |
| Firmware | `20250815`                                                      |
| Tuners   | 4 total — all 4 tune ATSC 1.0; **2 of the 4 also tune ATSC 3.0** (NextGen TV). Also QAM64/256 for unencrypted clear-QAM cable. |
| Input    | Single F-connector (coax) from antenna                          |
| Output   | **100BASE-TX (100 Mbps)** Ethernet to LAN; streams to clients over HTTP. Not gigabit — plenty for OTA, but worth knowing for the rack uplink. |
| Location | Crawl-space rack (vented shelf) — coax service loop terminates here; on the rack UPS |


## Coax

| Field      | Value                                                                         |
| ---------- | ----------------------------------------------------------------------------- |
| Cable      | Quad-shield RG6, 100 ft (not shortened — excess coiled at rack end)           |
| Route      | Attic antenna → through attic floor → wall cavity → server rack               |
| Connectors | IDEAL TLC tool-less compression, RG6 quad, 0–3 GHz — one at each end         |
| Service loop | ~2–3 ft of slack left at the rack end before the HDHomeRun F-connector      |

## Signal path

Antenna (attic, 228° WSW) → 100 ft quad-shield RG6 → HDHomeRun → Ethernet → [network](../network/) switch → any LAN client (TV app, Plex, etc.).
