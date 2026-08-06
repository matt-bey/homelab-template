# OTA TV

Status: Operational

Over-the-air television reception for the house — antenna, coax, and a SiliconDust HDHomeRun network tuner that makes broadcast channels available to any client on the LAN. The tuner's Ethernet uplink lands on the [network](../network/) rack; its coax feed comes from an RCA ANT705E Yagi mounted in the attic on a custom aim bracket at 228° (WSW).

This is a network *tenant*, not network infrastructure — same shape as [telephony](../telephony/). Swapping the antenna or tuner touches nothing about VLANs, switching, or DNS, so it lives on its own rather than inside `network`.


Signal monitoring: [config/](config/) (the HDHomeRun signal probe) actively samples per-station `ss`/`snq`/`seq` every 5 min and ships them to the [monitoring](../monitoring/) stack — surfaced on the **OTA TV — Signal** Grafana dashboard.

