# NUT — UPS monitoring and staged shutdown

Source-of-truth config for [NUT (Network UPS Tools)](https://networkupstools.org/)
on the Proxmox host. This tree mirrors the on-host `/etc/nut/` layout exactly.

The CyberPower CP1500PFCRM2U is cabled by **USB** to this host, so the NUT driver
and server run on **bare metal** — not in an LXC, Docker container, or VM. The
reasoning (USB ownership + downward shutdown authority) is recorded in

## Two layers

- **Layer 1 — visibility (live now).** `nut.conf` + `ups.conf` + `upsd.conf` get
  `upsc` returning battery %, load, and runtime, and expose `upsd` on the LAN for
  the `nut-exporter` container on docker-host.
- **Layer 2 — control (mixed).** `upsmon.conf` + `upssched.conf` +
  `handlers/upssched-cmd`. The **ntfy event alerts are live** (see "Alerting"
  below). The **staged load-shed actions are stubbed** (they log what they would
  do) until the UniFi API token and container list are settled post-UDM-install;
  the `LOWBATT` host halt is live via `upsmon`'s `SHUTDOWNCMD`.

## Files

| File | Secrets? | Purpose |
| --- | --- | --- |
| `nut.conf` | no | Operating mode (`netserver`). |
| `ups.conf` | no | The `[cp1500]` device + `usbhid-ups` driver. |
| `upsd.conf` | no | `upsd` listeners (localhost + LAN for the exporter). |
| `upsd.users.example` | **yes** | Login accounts. Copy to `upsd.users`, set passwords. |
| `upsmon.conf.example` | **yes** | Master monitor + shutdown. Copy to `upsmon.conf`, set password. |
| `upssched.conf` | no | Staged timers (T+5 / T+10), ONLINE cancels, and the event-notify EXECUTE rules. |
| `handlers/upssched-cmd` | no | Dispatcher: pushes ntfy alerts (onbatt/online/lowbatt) and runs the stubbed stage actions. |
| `handlers/ntfy.env.example` | token-maybe | ntfy URL/topic/token for the alerts. Seeded automatically; defaults work unauthenticated. |

`upsd.users` and `upsmon.conf` are gitignored — the passwords must match between
them, so set the same value in both. `handlers/ntfy.env` is gitignored too (it may
carry a token), but its `.example` defaults are functional, so the deploy seeds it
and alerts work without any manual step.

## Alerting

Power-state alerts come from `upsmon` on this **bare-metal host**, not from the
Grafana/Prometheus stack — deliberately. The monitoring stack (and ntfy itself)
runs on `docker-host`, a VM that is *also* on this UPS and gets shut down during
the event; the bare-metal NUT master is the survivor-tier component that outlives
it, so it's the resilient place to fire alerts. `upssched` runs
`handlers/upssched-cmd` on each event, which pushes to ntfy:

| Event | ntfy priority | Meaning |
| --- | --- | --- |
| `ONBATT` | high | Mains lost, switched to battery (fires at T+0, everything still up — rock-solid). |
| `LOWBATT` | max | Battery low, graceful shutdown beginning (best-effort — see below). |
| `ONLINE` | default | Mains restored, pending shutdown timers cancelled. |

### Potential future upgrades (not built)

- **Grafana threshold/trend alerts (#2).** The `nut_*` metrics in Prometheus can
  drive Grafana alerts for things events can't express — `nut_battery_charge <
  0.25`, estimated runtime under N minutes, or **"exporter down"** (lost UPS
  visibility) — routed through the existing `n8n-relay` → ntfy contact point. Best
  treated as informational/redundant: reliable for `ONBATT` (T+0) but not at
  `LOWBATT`, when its own stack is shutting down. Complements the `upsmon` events;
  doesn't replace them.
- **Guaranteed terminal alert via ntfy.sh.** The `LOWBATT` push is best-effort
  because local ntfy (on `docker-host`) may already be down — and the iOS relay
  needs the local server up to fetch the body. For a *guaranteed* "shutting down"
  alert, also POST `LOWBATT` directly to a public `ntfy.sh/<topic>` the phone
  subscribes to, decoupled from `docker-host`. Add a second `notify` call in the
  `lowbatt` case pointed at `ntfy.sh` and subscribe the phone to that topic.

## Deploy (from your workstation)

First, create the real secret files **locally** (they're gitignored and never
committed — same pattern as litellm's `.env`), and set a matching `[upsmon]`
password in both:

```bash
cd systems/homelab-server/config/nut
cp upsd.users.example  upsd.users     # set [upsmon] + [monuser] passwords
cp upsmon.conf.example upsmon.conf    # same [upsmon] password on the MONITOR line
```

Then deploy — the script ships this tree (including your local secret files) to
`/etc/nut`, installs NUT if needed, reapplies the USB udev rules, fixes perms, and
(re)starts the driver + server + monitor:

```bash
git pull origin main
bash systems/homelab-server/scripts/deploy-nut.sh
```

The local real files are the **source of truth** and are pushed on every run, so
edit them locally and redeploy. (If you skip creating them, the deploy seeds
`.example` on the host once and stops; it always refuses to start while a
`CHANGEME` placeholder remains.) The script ends by printing the `upsc` readout —
`battery.charge`, `ups.load`, `battery.runtime`, `ups.status` (`OL` = on mains).
That's layer 1 done.

The script connects as `root` by default — `admin@pam` is a Proxmox user with no
Linux sudo, and `/etc/nut` + `systemctl` need root. Env overrides: `HOMELAB_HOST`,
`HOMELAB_USER`, `SUDO` (set `SUDO="sudo"` for a sudo-capable user), `SSH_KEY`
(see `scripts/_deploy.sh`).

### What it does (manual equivalent / 11pm fallback)

If you ever need to do it by hand on the host: confirm the UPS with
`lsusb | grep -iE 'cyber|0764'`, `apt install -y nut`, copy the no-secret files
into `/etc/nut` and the two `.example` files to their real names, set matching
passwords, then validate the driver *before* the daemon with `upsdrvctl start`
(expect `Using subdriver: CyberPower HID ...`) and bring it up with
`systemctl enable --now nut-server nut-monitor`. On NUT 2.8 (Debian 13 / PVE 9)
the driver runs as an instanced unit — if it doesn't come up after a config
change, `systemctl restart nut-driver-enumerator` regenerates `nut-driver@cp1500`.

## Troubleshooting

**`libusb1: Could not open any HID devices: insufficient permissions`** — the
driver drops privileges to the `nut` user, so the USB node must be group-owned by
`nut`. This fails when the UPS was plugged in before NUT was installed (the udev
hotplug rule never ran). `deploy-nut.sh` reapplies the rules automatically; to fix
by hand: `udevadm control --reload-rules && udevadm trigger --action=add
--subsystem-match=usb`, then confirm `ls -l /dev/bus/usb/<bus>/<dev>` shows
`root nut`. If the device ID isn't covered by the shipped rules, add `user = root`
to the global section of `ups.conf` as a fallback.

**`upsmon: insufficient power configured! Sum of power values: 0`** — `upsmon.conf`
has no valid `MONITOR` line (commented out or mangled when setting the password).
It must read `MONITOR cp1500@localhost 1 upsmon <password> master`, uncommented,
with `<password>` matching the `[upsmon]` entry in `upsd.users`.

**`upsc` says `Connection refused`** — `upsd` isn't listening; check
`journalctl -u nut-server`. If it logged `upsd disabled ... set MODE`, then
`nut.conf` doesn't have `MODE=netserver`.

**`upsc` intermittently shows `Data stale`** — CyberPower USB can be chatty;
uncomment `pollinterval = 15` in `ups.conf`. Only if genuinely unstable, fall back
to CyberPower's PowerPanel for Linux, which can fire the same
`handlers/upssched-cmd` stages.
