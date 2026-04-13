#!/usr/bin/env bash
set -euo pipefail

echo "[35-burpsuite] Installiere Burp Suite Community Edition..."

apt-get -qq install -y burpsuite > /dev/null 2>&1

# Burp Suite zu XFCE Whisker-Menu-Favoriten hinzufuegen
WHISKER_DEFAULTS="/etc/xdg/xfce4/whiskermenu/defaults.rc"
BURP_DESKTOP=$(find /usr/share/applications -maxdepth 1 -name '*burp*' -printf '%f\n' 2>/dev/null | head -1)
if [[ -f "$WHISKER_DEFAULTS" && -n "$BURP_DESKTOP" ]] && ! grep -q "$BURP_DESKTOP" "$WHISKER_DEFAULTS" 2>/dev/null; then
    sed -i "s/^favorites=\(.*\)/favorites=\1,$BURP_DESKTOP/" "$WHISKER_DEFAULTS"
    echo "[35-burpsuite] $BURP_DESKTOP zu Whisker-Menu-Favoriten hinzugefuegt."
fi

echo "[35-burpsuite] Fertig."
