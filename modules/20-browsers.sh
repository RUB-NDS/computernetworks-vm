#!/usr/bin/env bash
set -euo pipefail

REAL_USER="${SUDO_USER:-kali}"
CA_CERT="${COURSE_CERT_DIR:-/etc/ssl/kali-course}/ca.crt"
CA_LABEL="${COURSE_CA_NAME:-kali-course Root CA}"
CA_FILE_NAME="${COURSE_ID:-kali-course}-ca.crt"
CHROME_DB="/home/$REAL_USER/.pki/nssdb"

ARCH="$(dpkg --print-architecture)"

echo "[20-browsers] Konfiguriere Browser und System-Trust-Stores (Arch: $ARCH)..."

apt-get -qq install -y libnss3-tools > /dev/null 2>&1

cp "$CA_CERT" "/usr/local/share/ca-certificates/${CA_FILE_NAME}"
update-ca-certificates -f > /dev/null 2>&1

if ! command -v google-chrome &>/dev/null; then
    CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_${ARCH}.deb"
    echo "[20-browsers] Versuche Google Chrome fuer $ARCH herunterzuladen..."
    if curl -fsSL "$CHROME_URL" -o /tmp/chrome.deb 2>/dev/null; then
        apt-get -qq install -y /tmp/chrome.deb > /dev/null 2>&1
        rm -f /tmp/chrome.deb
        echo "[20-browsers] Google Chrome installiert."
    else
        rm -f /tmp/chrome.deb
        echo "[20-browsers] Chrome fuer $ARCH nicht verfuegbar, installiere Chromium als Fallback..."
        apt-get -qq install -y chromium > /dev/null 2>&1
    fi
else
    echo "[20-browsers] Google Chrome bereits installiert, überspringe."
fi

sudo -u "$REAL_USER" mkdir -p "$CHROME_DB"
if [ ! -f "$CHROME_DB/cert9.db" ]; then
    sudo -u "$REAL_USER" certutil -N --empty-password -d "sql:$CHROME_DB" > /dev/null 2>&1
fi
sudo -u "$REAL_USER" certutil -D -n "$CA_LABEL" -d "sql:$CHROME_DB" > /dev/null 2>&1 || true
sudo -u "$REAL_USER" certutil -A -n "$CA_LABEL" -t "CT,C,C" -i "$CA_CERT" -d "sql:$CHROME_DB" > /dev/null 2>&1

for policy_dir in /etc/firefox-esr/policies /etc/firefox/policies; do
    mkdir -p "$policy_dir"
    cat > "$policy_dir/policies.json" <<EOF
{
  "policies": {
    "Certificates": {
      "Install": ["$CA_CERT"]
    }
  }
}
EOF
done

echo "[20-browsers] Fertig."