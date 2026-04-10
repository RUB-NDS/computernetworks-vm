#!/usr/bin/env bash
set -euo pipefail

REAL_USER="${SUDO_USER:-kali}"
KEYRING="/usr/share/keyrings/microsoft.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/vscode.list"
SOURCES_DEB822="/etc/apt/sources.list.d/vscode.sources"

echo "[70-vscode] Installiere Visual Studio Code..."

# Idempotenz: Nur einrichten, wenn WEDER die .list NOCH die .sources Datei existiert
if [[ ! -f "$SOURCES_LIST" && ! -f "$SOURCES_DEB822" ]]; then
    echo "[70-vscode] Richte Microsoft-Repository ein..."
    install -m 0755 -d /usr/share/keyrings

    # Schlüssel sicher umleiten
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | tee "$KEYRING" > /dev/null
    chmod 644 "$KEYRING"

    # Eintrag exakt so, wie Microsoft ihn erwartet
    echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYRING] https://packages.microsoft.com/repos/code stable main" \
        > "$SOURCES_LIST"

    apt-get -qq update > /dev/null 2>&1
else
    echo "[70-vscode] VS Code-Repository ist bereits eingerichtet."
fi

echo "[70-vscode] Installiere Paket 'code'..."
apt-get -qq install -y --no-install-recommends code > /dev/null 2>&1

echo "[70-vscode] Prüfe/Installiere VS Code Extensions..."
EXTENSIONS=("humao.rest-client")

for EXT in "${EXTENSIONS[@]}"; do
    if ! sudo -u "$REAL_USER" HOME="/home/$REAL_USER" code --list-extensions 2>/dev/null | grep -qi "^${EXT}$"; then
        echo "[70-vscode] Installiere Extension: $EXT"
        sudo -u "$REAL_USER" HOME="/home/$REAL_USER" code --install-extension "$EXT" > /dev/null 2>&1
    else
        echo "[70-vscode] Extension bereits installiert: $EXT"
    fi
done

echo "[70-vscode] Fertig."