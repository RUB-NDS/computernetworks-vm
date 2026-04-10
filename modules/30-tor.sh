#!/usr/bin/env bash
set -euo pipefail

echo "[30-tor] Installiere Tor und Torbrowser-Launcher..."

# tor: Proxy-Dienst
# torbrowser-launcher: Übernimmt Download und Signaturprüfung des Tor Browsers
apt-get -qq install -y tor torbrowser-launcher

echo "[30-tor] Fertig. Starten mit: torbrowser-launcher"