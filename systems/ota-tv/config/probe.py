#!/usr/bin/env python3
"""OTA TV HDHomeRun signal probe.

Actively samples per-station signal metrics (ss / snq / seq) from the
SiliconDust HDHomeRun and pushes them to a Prometheus Pushgateway.

Why *active* sampling: the HDHomeRun only reports ss/snq/seq for a tuner that
is currently locked to a channel. There is no passive "all stations" readout,
so this probe borrows a free tuner, steps it through the watched RF channels
via the control protocol (hdhomerun_config), reads each status line, then
releases the tuner. The whole point of the system is the historical record this
builds — see systems/ota-tv/README.md.

Why the control-protocol CLI and not the HTTP JSON API: the HTTP API
(/status.json) only reports signal for tuners that are *already* streaming, and
has no clean "tune this idle tuner to RF 28 and tell me the SNR" call. Forcing
a tune over HTTP means opening a video stream just to read three numbers. The
control protocol does set-channel + read-status with no stream, so it is the
right tool for measurement. hdhomerun_config wraps it.

Why address by IP, not device ID: this container runs on docker-host (a
different subnet than the tuner on VLAN 30). Passing the 8-char device ID makes
hdhomerun_config rely on UDP broadcast discovery, which does not cross subnets.
Passing the IP uses unicast control and routes fine (subject to the inter-VLAN
firewall rule). See systems/ota-tv/deployment.md for the reserved IP.

Tuner etiquette: probes the highest-numbered free tuner first (clients and any
future DVR grab the lowest free tuner), checks both /target and /lockkey to
skip tuners in use, and re-tunes the borrowed tuner to "none" when done. If all
four tuners are busy (rare today — no DVR, tuners idle almost always) the sweep
is skipped and only ota_tv_probe_success=0 is pushed. The brief race where a
client grabs the same tuner mid-sweep is accepted as proportionate for a
near-always-idle home tuner; the upgrade path is lockkey-held tuning, worth
adding only if a DVR ever makes tuner contention real.
"""

import os
import subprocess
import sys
import time

from prometheus_client import CollectorRegistry, Gauge, push_to_gateway

# Address the tuner by IP (see module docstring for why not the device ID).
HDHR_ADDR = os.environ.get("HDHR_ADDR", "<ota-tuner-ip>")
PUSHGATEWAY_URL = os.environ.get("PUSHGATEWAY_URL", "pushgateway:9091")
PROBE_INTERVAL = int(os.environ.get("PROBE_INTERVAL_SECONDS", "600"))
SETTLE_SECONDS = float(os.environ.get("TUNE_SETTLE_SECONDS", "5"))
JOB = "ota_tv_signal"
TUNER_COUNT = 4
LABELS = ["station", "network", "virtual", "rf"]

# Watched stations. The RF (physical) channel is what we tune; virtual/network
# are dashboard labels. Source of truth: systems/ota-tv/deployment.md. Keep
# this list in sync with deployment.md if the watched set changes.
# Note: WWHO (CW) and WTTE (FOX) share the RF 27 transmitter (551 MHz) after
# the FCC repack. sweep() tunes each unique RF once and fans the reading out to
# every station on it, so CW and FOX always report identical ss/snq/seq.
STATIONS = [
    {"call": "WCMH-TV", "network": "NBC", "virtual": "4", "rf": 14},
    {"call": "WOSU-D1", "network": "PBS", "virtual": "34", "rf": 16},
    {"call": "WBNS-TV", "network": "CBS", "virtual": "10", "rf": 21},
    {"call": "WTTE", "network": "FOX", "virtual": "28", "rf": 27},
    {"call": "WWHO", "network": "CW", "virtual": "53", "rf": 27},
    {"call": "WSYX", "network": "ABC", "virtual": "6", "rf": 28},
]


def hdhr(*args):
    """Run hdhomerun_config against the tuner; return stripped stdout."""
    cmd = ["hdhomerun_config", HDHR_ADDR, *args]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    return result.stdout.strip()


def tuner_is_free(n):
    """A tuner is free when it is neither streaming (target) nor locked."""
    target = hdhr("get", f"/tuner{n}/target")
    lockkey = hdhr("get", f"/tuner{n}/lockkey")
    return target in ("none", "") and lockkey in ("none", "")


def find_free_tuner():
    # Highest-numbered first: consumers and DVRs grab the lowest free tuner, so
    # starting at the top minimizes the chance of colliding with a live viewer.
    for n in range(TUNER_COUNT - 1, -1, -1):
        try:
            if tuner_is_free(n):
                return n
        except subprocess.SubprocessError:
            continue
    return None


def parse_status(line):
    """`ch=auto:14 lock=8vsb ss=99 snq=87 seq=100 bps=... pps=...` -> dict."""
    fields = {}
    for token in line.split():
        if "=" in token:
            key, value = token.split("=", 1)
            fields[key] = value
    return fields


def sweep(tuner):
    """Tune each unique watched RF once and map its reading back to every station
    on that RF.

    Deduping by RF is for correctness, not just speed: WWHO (CW) and WTTE (FOX)
    share RF 27, so iterating per-station would re-tune the borrowed tuner to an
    RF it was already on. That re-tune restarts lock acquisition, and a status
    read fired before it completes reports lock=none -> ss/snq/seq=0 — a false
    dropout (see notes.md). Tuning each RF once removes the redundant re-tune;
    both stations then report the same reading by construction.
    """
    hdhr("set", f"/tuner{tuner}/channelmap", "us-bcast")
    # Unique RFs in first-appearance order.
    rfs = list(dict.fromkeys(station["rf"] for station in STATIONS))
    by_rf = {}
    try:
        for rf in rfs:
            # `auto:<rf>` lets the tuner detect modulation (8VSB vs ATSC 3.0
            # OFDM) per channel — see the ATSC 3.0 note in notes.md.
            hdhr("set", f"/tuner{tuner}/channel", f"auto:{rf}")
            time.sleep(SETTLE_SECONDS)
            by_rf[rf] = parse_status(hdhr("get", f"/tuner{tuner}/status"))
    finally:
        # Release the tuner promptly so a viewer/DVR can reclaim it.
        hdhr("set", f"/tuner{tuner}/channel", "none")
    return [(station, by_rf[station["rf"]]) for station in STATIONS]


def to_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def build_registry(results, tuner):
    """Build a fresh registry. push_to_gateway replaces the whole job group, so
    on a skipped sweep only probe_success=0 is published (per-station series
    show an honest gap)."""
    registry = CollectorRegistry()
    success = Gauge(
        "ota_tv_probe_success",
        "1 if the probe found a free tuner and swept; 0 if all tuners busy.",
        registry=registry,
    )
    if results is None:
        success.set(0)
        return registry
    success.set(1)

    g_ss = Gauge("ota_tv_signal_strength", "Signal strength (ss), 0-100.", LABELS, registry=registry)
    g_snq = Gauge("ota_tv_signal_quality", "Signal quality / SNR (snq), 0-100.", LABELS, registry=registry)
    g_seq = Gauge("ota_tv_symbol_quality", "Symbol quality (seq), 0-100.", LABELS, registry=registry)
    g_lock = Gauge("ota_tv_locked", "1 if the tuner locked the channel, else 0.", LABELS, registry=registry)
    g_tuner = Gauge("ota_tv_probe_tuner", "Tuner index used for the latest sweep.", registry=registry)
    g_tuner.set(tuner)

    for station, status in results:
        labels = dict(
            station=station["call"],
            network=station["network"],
            virtual=station["virtual"],
            rf=str(station["rf"]),
        )
        g_ss.labels(**labels).set(to_int(status.get("ss")))
        g_snq.labels(**labels).set(to_int(status.get("snq")))
        g_seq.labels(**labels).set(to_int(status.get("seq")))
        g_lock.labels(**labels).set(0 if status.get("lock", "none") in ("none", "") else 1)
    return registry


def run_once():
    tuner = find_free_tuner()
    if tuner is None:
        print("all tuners busy; skipping sweep", flush=True)
        results = None
    else:
        print(f"sweeping {len(STATIONS)} stations on tuner{tuner}", flush=True)
        results = sweep(tuner)
        for station, status in results:
            print(
                f"  {station['call']:8} rf{station['rf']:<3} "
                f"ss={status.get('ss', '?')} snq={status.get('snq', '?')} "
                f"seq={status.get('seq', '?')} lock={status.get('lock', '?')}",
                flush=True,
            )
    push_to_gateway(PUSHGATEWAY_URL, job=JOB, registry=build_registry(results, tuner or 0))
    print(f"pushed to {PUSHGATEWAY_URL} (job={JOB})", flush=True)


def main():
    run_once_only = "--once" in sys.argv
    while True:
        try:
            run_once()
        except Exception as exc:  # keep the loop alive across transient errors
            print(f"probe error: {exc}", file=sys.stderr, flush=True)
        if run_once_only:
            return
        time.sleep(PROBE_INTERVAL)


if __name__ == "__main__":
    main()
