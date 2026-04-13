#!/usr/bin/env bash
set -euo pipefail

ARCH="$(dpkg --print-architecture)"
REAL_USER="${SUDO_USER:-kali}"

echo "[30-tor] Installiere Tor (Arch: $ARCH)..."

# tor: Proxy-Dienst (verfuegbar fuer alle Architekturen)
apt-get -qq install -y tor

if [[ "$ARCH" == "amd64" ]]; then
    # torbrowser-launcher: Übernimmt Download und Signaturprüfung des Tor Browsers
    echo "[30-tor] Installiere Torbrowser-Launcher..."
    apt-get -qq install -y torbrowser-launcher
    echo "[30-tor] Fertig. Starten mit: torbrowser-launcher"
else
    # Kein torbrowser-launcher fuer ARM – Nightly-Build manuell installieren
    NIGHTLY_BASE="https://nightlies.tbb.torproject.org/nightly-builds/tor-browser-builds"
    INSTALL_DIR="/opt/tor-browser"

    if [[ -d "$INSTALL_DIR" ]]; then
        echo "[30-tor] Tor Browser bereits installiert unter $INSTALL_DIR, ueberspringe."
    else
        echo "[30-tor] Lade Tor Browser Nightly fuer aarch64 herunter..."

        # Neuestes Nightly-Datum aus dem Verzeichnislisting ermitteln
        LATEST_DATE=$(curl -fsSL "$NIGHTLY_BASE/" \
            | grep -oP 'tbb-nightly\.\K[0-9]{4}\.[0-9]{2}\.[0-9]{2}' \
            | sort -r | head -1)

        if [[ -z "$LATEST_DATE" ]]; then
            echo "[30-tor] WARNUNG: Konnte kein Nightly-Build finden, ueberspringe Tor Browser."
            echo "[30-tor] Fertig. Tor-Proxy ist installiert und nutzbar (z.B. via proxychains)."
            exit 0
        fi

        TARBALL="tor-browser-linux-aarch64-tbb-nightly.${LATEST_DATE}.tar.xz"
        URL="${NIGHTLY_BASE}/tbb-nightly.${LATEST_DATE}/nightly-linux-aarch64/${TARBALL}"

        echo "[30-tor] Lade herunter: $TARBALL"
        curl -fsSL "$URL" -o "/tmp/$TARBALL"
        mkdir -p "$INSTALL_DIR"
        tar -xJf "/tmp/$TARBALL" -C "$INSTALL_DIR" --strip-components=1
        rm -f "/tmp/$TARBALL"
        chown -R "$REAL_USER:$REAL_USER" "$INSTALL_DIR"

        # Desktop-Eintrag erstellen
        cat > /usr/share/applications/tor-browser.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Tor Browser (Nightly)
GenericName=Web Browser
Comment=Tor Browser Nightly – ARM64
Exec=$INSTALL_DIR/start-tor-browser --detach
Icon=$INSTALL_DIR/browser/chrome/icons/default/default128.png
Terminal=false
Categories=Network;WebBrowser;
StartupWMClass=Tor Browser
EOF
        chmod 644 /usr/share/applications/tor-browser.desktop

        echo "[30-tor] Tor Browser Nightly installiert unter $INSTALL_DIR"
    fi

    echo "[30-tor] Fertig. Starten mit: $INSTALL_DIR/start-tor-browser"
fi