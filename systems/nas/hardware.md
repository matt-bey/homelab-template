# NAS — Hardware

Planned spec. Nothing acquired yet; this describes the intended build.

## Unit — Synology DiskStation DS925+

| Field         | Value                                                       |
| ------------- | ----------------------------------------------------------- |
| Model         | Synology DS925+ (4-bay desktop, 2025 model)                 |
| CPU           | AMD Ryzen V1500B, 4-core / 8-thread, 2.2 GHz                 |
| iGPU          | None (no hardware transcoding — not needed; see ADR 001)    |
| RAM           | 4 GB DDR4 ECC SODIMM; 2 slots, expandable to 32 GB (2 × 16) — **plan a bump beyond 4 GB** as the Photos library / AI indexing grows |
| M.2 slots     | 2 × M.2 2280 NVMe — cache or storage pool; read cache worthwhile for a large Photos library (Synology NVMe required) |
| Network       | 2 × 2.5GbE (no PCIe slot — no 10GbE upgrade path)           |
| USB           | 2 × USB 3.2 Gen 1 + 1 × USB-C expansion (DX525)             |
| Expansion     | DX525 unit → up to 9 bays total                             |
| Tested perf   | 522 MB/s read / 565 MB/s write                              |
| Power         | 37.91 W (access) / 12.33 W (idle); 100–120 W adapter        |
| Noise         | 20.5 dB(A)                                                  |
| Dimensions    | 166 mm (H) × 199 mm (W) × 223 mm (D); 2.26 kg               |
| Warranty      | 3-year (extendable to 5 with EW)                            |

## Storage layout

| Field             | Value                                                       |
| ----------------- | ----------------------------------------------------------- |
| Initial drives    | 3 × 8 TB CMR NAS HDD                                         |
| Drive model       | Seagate IronWolf 8 TB (ST8000VN004), standard / non-Pro tier — CMR, on Synology compat list, ~$300/unit (2026). See `decisions.md`. |
| Array             | SHR-1 (single-drive fault tolerance) — ~16 TB usable        |
| Expansion         | 1 bay left open; add a 4th 8 TB and online-expand to ~24 TB |
| File system       | Btrfs (snapshots, file self-healing)                        |

Drive-topology reasoning (3 × 8 TB over 4 × 4 TB) is in `decisions.md`. Third-party HDDs form storage pools normally — the 2025-model drive lockdown was reversed in DSM 7.3 (Oct 2025); off-list drives get "limited support" only, so staying on the compatibility list is the safe choice. M.2 NVMe (cache or pool) requires Synology-branded drives.

## Placement

**Set on top of the open-frame crawl-space rack** — not rail-mounted, not on an internal shelf. Measured to fit cleanly on the top surface, so it consumes **zero internal rack U** (every bay stays free for other gear). See ADR 001 for why a desktop unit over a rackmount.

| Constraint        | Value / note                                                          |
| ----------------- | --------------------------------------------------------------------- |
| Footprint         | 199 mm W × 223 mm D, ~2.26 kg (≈4.4 kg with three drives) — trivial, stable load on the rack top |
| Clearance         | Leave room above/behind for the rear exhaust fan and the power-brick barrel connector |
| Heat              | Top of rack is the warmest spot (rising heat); the NAS draws front-to-back and runs cool, so this is a non-issue in practice |

## Networking

- 1GbE at launch (matches current rack fabric). Both onboard ports are **2.5GbE** — the upgrade target once a multi-gig switch is in the rack (the planned Phase 2 `USW-Pro-Max-16-PoE`). Second 2.5GbE port is spare (bondable or a future direct link).
- No 10GbE path — the DS925+ has no PCIe slot. Accepted (see ADR 001 Non-Goals).
