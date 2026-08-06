#!/usr/bin/env bash
# vm-create.sh — Create a Proxmox VM from a vm.conf spec file.
# Usage (run from repo root on dev-workstation):
#   bash systems/homelab-server/scripts/vm-create.sh <path/to/vm.conf>
#
# Environment overrides:
#   PROXMOX_HOST     SSH target for the Proxmox host   (default: root@<homelab-server-ip>)
#   SSH_KEY_TINKER   Path to dev-workstation public key (default: ~/.ssh/id_ed25519_homelab.pub)
#   SSH_KEY_MACBOOK  Path to MacBook public key         (default: ~/.ssh/id_ed25519_macbook.pub)
#   VM_BRIDGE        Proxmox bridge name                (default: vmbr0)
#   PROXMOX_STORAGE  Proxmox storage pool               (default: local-lvm)
set -euo pipefail

SPEC_FILE="${1:?Usage: vm-create.sh <path/to/vm.conf>}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

PROXMOX_HOST="${PROXMOX_HOST:-root@homelab-server.local}"
SSH_KEY_TINKER="${SSH_KEY_TINKER:-${HOME}/.ssh/id_ed25519_homelab.pub}"
SSH_KEY_MACBOOK="${SSH_KEY_MACBOOK:-${HOME}/.ssh/id_ed25519_macbook.pub}"
VM_BRIDGE="${VM_BRIDGE:-vmbr0}"
PROXMOX_STORAGE="${PROXMOX_STORAGE:-local-lvm}"

IMAGES_DIR="/root/images"
SNIPPETS_DIR="/var/lib/vz/snippets"

# --- Load VM spec ---

[ -f "${SPEC_FILE}" ] || { echo "vm.conf not found: ${SPEC_FILE}"; exit 1; }
# shellcheck source=/dev/null
source "${SPEC_FILE}"

for var in VM_ID VM_NAME VM_CORES VM_MEMORY VM_DISK IMAGE_NAME IMAGE_URL CHECKSUM_URL CHECKSUM_CMD USER_DATA; do
    [ -n "${!var:-}" ] || { echo "vm.conf missing required field: ${var}"; exit 1; }
done

USER_DATA_PATH="${REPO_ROOT}/${USER_DATA}"
IMAGE_CACHE="${IMAGES_DIR}/${IMAGE_NAME}"
USER_DATA_DEST="${SNIPPETS_DIR}/${VM_NAME}-user-data.yaml"

remote() { ssh "${PROXMOX_HOST}" "$@"; }

# --- Prerequisites ---

echo "==> Checking prerequisites"
[ -f "${SSH_KEY_TINKER}" ]  || { echo "SSH key not found: ${SSH_KEY_TINKER}"; exit 1; }
[ -f "${SSH_KEY_MACBOOK}" ] || { echo "SSH key not found: ${SSH_KEY_MACBOOK}"; exit 1; }
[ -f "${USER_DATA_PATH}" ]  || { echo "user-data not found: ${USER_DATA_PATH}"; exit 1; }

remote "grep -A5 '^dir: local' /etc/pve/storage.cfg | grep -q snippets" \
    || { echo "ERROR: 'snippets' not enabled on local storage. Enable it in the Proxmox UI under Datacenter > Storage > local > Content."; exit 1; }

# --- Cloud image ---

remote "mkdir -p ${IMAGES_DIR}"

if remote "[ -f '${IMAGE_CACHE}' ]"; then
    echo "==> Cloud image already present on host: ${IMAGE_CACHE}"
else
    echo "==> Downloading ${IMAGE_NAME} on Proxmox host"
    remote "wget -nv -O '${IMAGE_CACHE}' '${IMAGE_URL}'"

    echo "==> Verifying checksum"
    expected="$(remote "wget -qO - '${CHECKSUM_URL}'" | grep "${IMAGE_NAME}" | awk '{print $1}')"
    actual="$(remote "${CHECKSUM_CMD} '${IMAGE_CACHE}'" | awk '{print $1}')"
    [ "${expected}" = "${actual}" ] || {
        remote "rm -f '${IMAGE_CACHE}'"
        echo "Checksum mismatch — aborting"
        exit 1
    }
fi

# --- Cloud-init user-data ---

echo "==> Injecting SSH keys and uploading user-data"
SSH_PUB_TINKER="$(cat "${SSH_KEY_TINKER}")"
SSH_PUB_MACBOOK="$(cat "${SSH_KEY_MACBOOK}")"
sed -e "s|__SSH_KEY_TINKER__|${SSH_PUB_TINKER}|g" \
    -e "s|__SSH_KEY_MACBOOK__|${SSH_PUB_MACBOOK}|g" \
    "${USER_DATA_PATH}" \
    | remote "cat > '${USER_DATA_DEST}'"

# --- VM creation ---

if remote "qm status ${VM_ID}" &>/dev/null; then
    echo "==> VM ${VM_ID} already exists — skipping creation"
else
    echo "==> Creating VM ${VM_ID} (${VM_NAME})"
    remote "qm create ${VM_ID} \
        --name ${VM_NAME} \
        --cores ${VM_CORES} \
        --memory ${VM_MEMORY} \
        --balloon 0 \
        --onboot 1 \
        --cpu host \
        --net0 virtio,bridge=${VM_BRIDGE} \
        --serial0 socket \
        --vga serial0 \
        --ostype l26 \
        --agent enabled=1 \
        --boot order=scsi0"

    echo "==> Importing disk"
    remote "qm importdisk ${VM_ID} '${IMAGE_CACHE}' ${PROXMOX_STORAGE}"
    remote "qm set ${VM_ID} \
        --scsihw virtio-scsi-pci \
        --scsi0 ${PROXMOX_STORAGE}:vm-${VM_ID}-disk-0,discard=on"

    echo "==> Resizing disk to ${VM_DISK}"
    remote "qm resize ${VM_ID} scsi0 ${VM_DISK}"

    echo "==> Attaching cloud-init drive"
    remote "qm set ${VM_ID} \
        --ide2 ${PROXMOX_STORAGE}:cloudinit \
        --cicustom user=local:snippets/${VM_NAME}-user-data.yaml \
        --ipconfig0 ip=dhcp \
        --nameserver 1.1.1.1"
fi

echo ""
echo "==> Done. Get the VM's MAC address before starting:"
echo "    ssh ${PROXMOX_HOST} \"qm config ${VM_ID} | grep net0\""
echo ""
echo "    Set a DHCP reservation in Google Wifi for that MAC, then start:"
echo "    ssh ${PROXMOX_HOST} qm start ${VM_ID}"
echo ""
echo "    Watch first-boot:"
echo "    ssh ${PROXMOX_HOST} qm terminal ${VM_ID}"
echo ""
echo "    Confirm the assigned IP:"
echo "    ssh ${PROXMOX_HOST} \"qm guest cmd ${VM_ID} network-get-interfaces\""
echo ""
echo "    Then update systems/${VM_NAME}/deployment.md with the IP and MAC."
