#!/usr/bin/env bash
set -euo pipefail

REAL_USER="${SUDO_USER:-kali}"
KEYRING="/etc/apt/keyrings/docker.asc"
SOURCES="/etc/apt/sources.list.d/docker.list"

echo "[40-docker] Konfiguriere Docker CE..."

if [[ ! -f "$SOURCES" ]]; then
    echo "[40-docker] Richte offizielles Docker-Repository ein..."

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o "$KEYRING"
    chmod a+r "$KEYRING"

    echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://download.docker.com/linux/debian bookworm stable" \
        > "$SOURCES"

    apt-get -qq update > /dev/null 2>&1
else
    echo "[40-docker] Docker-Repository ist bereits eingerichtet."
fi

echo "[40-docker] Installiere Docker-Pakete..."
apt-get -qq install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin > /dev/null 2>&1

# enable --now startet den Dienst sofort und aktiviert ihn für den Systemstart
systemctl enable --now docker > /dev/null 2>&1 || true

# User zur Docker-Gruppe hinzufügen (überschreibt nichts, falls er schon drin ist)
usermod -aG docker "$REAL_USER"

echo "[40-docker] Fertig. (Hinweis: docker-Befehle ohne sudo erfordern Logout/Login)"