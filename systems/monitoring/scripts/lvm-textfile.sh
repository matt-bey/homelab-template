#!/usr/bin/env bash
# lvm-textfile.sh — emit LVM thin-pool fill metrics for node-exporter's textfile collector.
#
# Installed to /usr/local/sbin/ on the Proxmox host by install-lvm-textfile-collector.sh.
# Triggered by lvm-textfile.timer every minute. Output is consumed by the bare-metal
# prometheus-node-exporter via its --collector.textfile.directory.
#
# We emit data_percent and metadata_percent for every thin-pool LV. The Proxmox default
# layout has exactly one thin-pool (pve/data); future thin-pools (e.g., a future backup pool)
# pick up the same metrics automatically without code changes.
set -euo pipefail

OUT="${1:-/var/lib/prometheus/node-exporter/lvm.prom}"
TMP="${OUT}.tmp.$$"

# Trap to clean up tmp file on any abort.
trap 'rm -f "${TMP}"' EXIT

{
    echo "# HELP node_lvm_thin_pool_data_percent_used Percent of LVM thin-pool data extents in use."
    echo "# TYPE node_lvm_thin_pool_data_percent_used gauge"
    echo "# HELP node_lvm_thin_pool_metadata_percent_used Percent of LVM thin-pool metadata extents in use."
    echo "# TYPE node_lvm_thin_pool_metadata_percent_used gauge"

    # lv_attr's first char is 't' for thin-pool LVs. Filter to those only.
    # --nosuffix gives bare numbers; we never use the byte counts here, but
    # --units b keeps the unit stable should we ever add size metrics.
    lvs --noheadings --units b --nosuffix \
        -o vg_name,lv_name,lv_attr,data_percent,metadata_percent 2>/dev/null \
      | awk '$3 ~ /^t/ {
            gsub(/^[ \t]+/, "", $1); gsub(/^[ \t]+/, "", $2);
            printf "node_lvm_thin_pool_data_percent_used{vg=\"%s\",pool=\"%s\"} %s\n", $1, $2, $4;
            printf "node_lvm_thin_pool_metadata_percent_used{vg=\"%s\",pool=\"%s\"} %s\n", $1, $2, $5;
        }'
} > "${TMP}"

# Atomic rename so Prometheus never reads a half-written file.
mv "${TMP}" "${OUT}"
