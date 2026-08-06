# Telephony

Status: Operational

A working analog telephone setup bridged to VoIP. A Grandstream HT802 ATA, now racked in the [network](../network/) crawl-space rack, provides FXS ports for two vintage phones; calls route through Callcentric over SIP. Its data/SIP uplink lands on the IoT VLAN, and its FXS ports patch into Cat3 keystones on the patch panel that carry the analog tails out to the office (rotary phone) and the former closet run (Princess phone). The setup exists for fun and as a low-key way to keep working analog telephony in the house — distinct from the <your-sibling-repo> `antique-telephone-ai-operator` project, which is a different antique phone with an AI operator behind it.

