#!/usr/bin/env bash
set -euo pipefail

echo "[05-vm-tools] Erkenne Hypervisor und installiere passende Gastwerkzeuge..."

VIRT=$(systemd-detect-virt 2>/dev/null || echo "none")
echo "[05-vm-tools] Erkannter Hypervisor: $VIRT"

case "$VIRT" in
    qemu|kvm)
        # UTM / QEMU / KVM
        echo "[05-vm-tools] Installiere SPICE- und QEMU-Gastwerkzeuge..."
        apt-get -qq install -y spice-vdagent qemu-guest-agent > /dev/null 2>&1
        systemctl enable --now spice-vdagentd > /dev/null 2>&1 || true
        systemctl enable --now qemu-guest-agent > /dev/null 2>&1 || true
        ;;
    oracle)
        # VirtualBox
        echo "[05-vm-tools] Installiere VirtualBox Guest Additions..."
        apt-get -qq install -y virtualbox-guest-x11 > /dev/null 2>&1
        ;;
    vmware)
        # VMware Workstation / Fusion
        echo "[05-vm-tools] Installiere open-vm-tools..."
        apt-get -qq install -y open-vm-tools open-vm-tools-desktop > /dev/null 2>&1
        systemctl enable --now vmtoolsd > /dev/null 2>&1 || true
        ;;
    *)
        echo "[05-vm-tools] Unbekannter Hypervisor ($VIRT), installiere generische Tools..."
        apt-get -qq install -y spice-vdagent qemu-guest-agent > /dev/null 2>&1 || true
        ;;
esac

echo "[05-vm-tools] Fertig."
