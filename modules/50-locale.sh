#!/usr/bin/env bash
set -euo pipefail

TIMEZONE="Europe/Berlin"
KEYBOARD_LAYOUT="de"
REAL_USER="${SUDO_USER:-kali}"

echo "[50-locale] Konfiguriere Zeitzone und Tastatur (Systemsprache bleibt Englisch)..."

# --- 1. Zeitzone ---
timedatectl set-timezone "$TIMEZONE"

# --- 2. Tastaturlayout ---
echo "[50-locale] Erzwinge Tastaturlayout auf '$KEYBOARD_LAYOUT'..."

# A) Systemd-Weg für die grafische Oberfläche (X11)
localectl set-x11-keymap "$KEYBOARD_LAYOUT"

# B) Debian-nativer Weg (Persistenz über Neustarts)
sed -i "s/^XKBLAYOUT=.*/XKBLAYOUT=\"$KEYBOARD_LAYOUT\"/" /etc/default/keyboard
export DEBIAN_FRONTEND=noninteractive
dpkg-reconfigure -f noninteractive keyboard-configuration >/dev/null 2>&1 || true

# C) SOFORT-Aktivierung in der laufenden Desktop-Sitzung
if command -v setxkbmap >/dev/null 2>&1; then
    sudo -u "$REAL_USER" DISPLAY=:0 setxkbmap "$KEYBOARD_LAYOUT" >/dev/null 2>&1 || true
fi

# D) Hardware-Events neu triggern
udevadm trigger --subsystem-match=input --action=change >/dev/null 2>&1 || true

echo "[50-locale] Fertig. Tastatur und Zeitzone aktualisiert."