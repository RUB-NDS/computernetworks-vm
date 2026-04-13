#!/usr/bin/env bash
set -euo pipefail

echo "[05-vm-tools] Installiere VM-Gastwerkzeuge..."

# spice-vdagent: Display-Resize, Clipboard-Sharing, Maus-Integration (UTM/QEMU/SPICE)
# qemu-guest-agent: Host-Guest-Kommunikation (Shutdown, Freeze, Info-Abfragen)
apt-get -qq install -y spice-vdagent qemu-guest-agent > /dev/null 2>&1

systemctl enable --now spice-vdagentd > /dev/null 2>&1 || true
systemctl enable --now qemu-guest-agent > /dev/null 2>&1 || true

echo "[05-vm-tools] Fertig."
