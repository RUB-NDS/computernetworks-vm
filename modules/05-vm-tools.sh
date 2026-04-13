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

# Shared-Folder einrichten (VirtFS oder SPICE WebDAV)
REAL_USER="${SUDO_USER:-kali}"
SHARE_DIR="/home/$REAL_USER/shared"
mkdir -p "$SHARE_DIR"
chown "$REAL_USER:$REAL_USER" "$SHARE_DIR"

# VirtFS (9p) — fuer UTM mit VirtFS-Sharing
FSTAB_9P="share $SHARE_DIR 9p trans=virtio,version=9p2000.L,rw,_netdev,nofail,noauto,x-systemd.automount 0 0"
if ! grep -q "^share $SHARE_DIR 9p" /etc/fstab 2>/dev/null; then
    echo "[05-vm-tools] Richte VirtFS (9p) Shared-Folder ein..."
    echo "$FSTAB_9P" >> /etc/fstab
fi

# SPICE WebDAV — fuer UTM mit SPICE-Sharing
echo "[05-vm-tools] Installiere SPICE WebDAV Unterstuetzung..."
apt-get -qq install -y spice-webdavd davfs2 > /dev/null 2>&1 || true
systemctl enable --now spice-webdavd > /dev/null 2>&1 || true
FSTAB_DAV="http://localhost:9843 $SHARE_DIR davfs _netdev,nofail,noauto,x-systemd.automount,user 0 0"
if ! grep -q "localhost:9843" /etc/fstab 2>/dev/null; then
    echo "[05-vm-tools] Richte SPICE WebDAV Shared-Folder ein..."
    # davfs2 ohne Passwort-Abfrage konfigurieren
    mkdir -p /etc/davfs2
    echo "http://localhost:9843 \"\" \"\"" >> /etc/davfs2/secrets
    echo "$FSTAB_DAV" >> /etc/fstab
fi

echo "[05-vm-tools] Fertig."
