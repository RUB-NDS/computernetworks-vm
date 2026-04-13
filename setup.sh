#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[-] Fehler: Bitte mit 'sudo bash' ausfuehren."
    exit 1
fi

# ============================================================
# KONFIGURATION – alle Eigennamen zentral an einer Stelle
# ============================================================

# Wird genutzt für: Dateinamen, Ordner, Apache-Configs
export COURSE_ID="computernetze"

export COURSE_TITLE="Computernetze"

# ============================================================
# Abgeleitete Variablen (brauchen normalerweise nicht geändert zu werden)
export COURSE_CERT_DIR="/etc/ssl/${COURSE_ID}"
export COURSE_CA_NAME="${COURSE_TITLE} Root CA"
export COURSE_ORG="${COURSE_TITLE}"

export ROOT_PASSWORD="toor"
export USER_PASSWORD="kali"

export COURSE_DOMAINS_STRING="attacker.com honest-sp.com honest-idp.com malicious.com"
export COURSE_DOCKER_DOMAIN="malicious.com"

export SUDO_USER="${SUDO_USER:-kali}"
export DEBIAN_FRONTEND=noninteractive
# ============================================================

BRANCH="${KALI_SETUP_BRANCH:-main}"
SERVER="${KALI_SETUP_SERVER:-https://raw.githubusercontent.com/RUB-NDS/computernetworks-vm/${BRANCH}/}"
MODULE_DIR="/tmp/kali-modules"
LOG_FILE="/var/log/kali-setup.log"
MODULES=(00-base 05-vm-tools 10-apache-ssl 20-browsers 30-tor 35-burpsuite 40-docker 50-locale 60-hosts 70-vscode)

mkdir -p "$MODULE_DIR"
trap 'rm -rf "$MODULE_DIR"' EXIT

echo "[*] $(date '+%Y-%m-%d %H:%M:%S') Kali Setup startet (User: $SUDO_USER)" | tee -a "$LOG_FILE"

echo "[*] Lade Module von $SERVER..."
for mod in "${MODULES[@]}"; do
    echo "[*] Lade: $mod" | tee -a "$LOG_FILE"
    curl -fsSL "$SERVER/modules/${mod}.sh" -o "$MODULE_DIR/${mod}.sh"
done

for mod in "${MODULES[@]}"; do
    echo "" | tee -a "$LOG_FILE"
    echo "[*] $(date '+%H:%M:%S') === $mod ===" | tee -a "$LOG_FILE"
    if bash "$MODULE_DIR/${mod}.sh" 2>&1 | tee -a "$LOG_FILE"; then
        echo "[+] $(date '+%H:%M:%S') $mod abgeschlossen." | tee -a "$LOG_FILE"
    else
        echo "[-] $(date '+%H:%M:%S') $mod FEHLGESCHLAGEN – Setup wird abgebrochen." | tee -a "$LOG_FILE"
        exit 1
    fi
done

echo "" | tee -a "$LOG_FILE"
echo "[*] Räume auf..." | tee -a "$LOG_FILE"
apt-get autoremove -y > /dev/null
apt-get autoclean   > /dev/null

echo "[+] $(date '+%Y-%m-%d %H:%M:%S') Setup erfolgreich abgeschlossen." | tee -a "$LOG_FILE"

# --- Spuren entfernen: saubere VM fuer Studierende ---
echo "[*] Bereinige Logs und Shell-History..."
rm -f "$LOG_FILE"

# Shell-History (kali + root)
rm -f /home/"$SUDO_USER"/.zsh_history /home/"$SUDO_USER"/.bash_history
rm -f /root/.zsh_history /root/.bash_history

# System-Logs
rm -rf /var/log/apt/*
rm -f /var/log/auth.log* /var/log/syslog* /var/log/messages*
rm -f /var/log/kern.log* /var/log/daemon.log* /var/log/dpkg.log*
rm -f /var/log/alternatives.log* /var/log/bootstrap.log
journalctl --rotate --vacuum-time=1s > /dev/null 2>&1 || true

# Temp-Dateien
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

echo "[+] Setup abgeschlossen. VM ist bereit."