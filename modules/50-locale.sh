#!/usr/bin/env bash
set -euo pipefail

TIMEZONE="Europe/Berlin"
KEYBOARD_LAYOUT="de"
REAL_USER="${SUDO_USER:-kali}"

echo "[50-locale] Konfiguriere Zeitzone, Locale und Tastatur..."

# --- 1. Locale (UTF-8) ---
echo "[50-locale] Stelle sicher, dass en_US.UTF-8 generiert und aktiv ist..."
sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen > /dev/null 2>&1
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- 2. Zeitzone ---
timedatectl set-timezone "$TIMEZONE"

# --- 3. Tastaturlayout ---
echo "[50-locale] Erzwinge Tastaturlayout auf '$KEYBOARD_LAYOUT'..."

# a) Systemd-Weg für die grafische Oberfläche (X11)
localectl set-x11-keymap "$KEYBOARD_LAYOUT"

# b) Debian-nativer Weg (Persistenz über Neustarts)
sed -i "s/^XKBLAYOUT=.*/XKBLAYOUT=\"$KEYBOARD_LAYOUT\"/" /etc/default/keyboard
export DEBIAN_FRONTEND=noninteractive
dpkg-reconfigure -f noninteractive keyboard-configuration >/dev/null 2>&1 || true

# c) SOFORT-Aktivierung in der laufenden Desktop-Sitzung
if command -v setxkbmap >/dev/null 2>&1; then
    sudo -u "$REAL_USER" DISPLAY=:0 setxkbmap "$KEYBOARD_LAYOUT" >/dev/null 2>&1 || true
fi

# d) Hardware-Events neu triggern
udevadm trigger --subsystem-match=input --action=change >/dev/null 2>&1 || true

echo "[50-locale] Fertig. Tastatur und Zeitzone aktualisiert."