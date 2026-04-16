#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[-] Fehler: Bitte mit 'sudo bash' ausfuehren."
    exit 1
fi

# ============================================================
# KONFIGURATION
# ============================================================
BRANCH="${1:-${KALI_SETUP_BRANCH:-main}}"
REPO_URL="https://github.com/RUB-NDS/computernetworks-vm.git"
CLONE_DIR="/tmp/computernetworks-vm"
LOG_FILE="/var/log/kali-setup.log"
REAL_USER="${SUDO_USER:-kali}"

echo "[*] $(date '+%Y-%m-%d %H:%M:%S') Kali Setup startet (User: $REAL_USER)" | tee -a "$LOG_FILE"

# --- 1. APT-Quellen sicherstellen ---
KALI_REPO="deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware"
if ! grep -rq "^deb .*kali" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null && \
   ! grep -rq "^URIs:.*kali" /etc/apt/sources.list.d/ 2>/dev/null; then
    echo "[*] Kali APT-Quellen nicht gefunden, richte ein..." | tee -a "$LOG_FILE"
    echo "$KALI_REPO" > /etc/apt/sources.list
fi

# --- 2. Ansible und Git installieren ---
echo "[*] Installiere Ansible und Git..." | tee -a "$LOG_FILE"
apt-get -qq update
apt-get -qq install -y ansible git

# --- 3. Repository klonen ---
rm -rf "$CLONE_DIR"
echo "[*] Klone Repository (Branch: $BRANCH)..." | tee -a "$LOG_FILE"
git clone -b "$BRANCH" --depth 1 "$REPO_URL" "$CLONE_DIR"

# --- 4. Ansible Playbook ausfuehren ---
echo "[*] Starte Ansible Playbook..." | tee -a "$LOG_FILE"
ANSIBLE_FORCE_COLOR=1 ansible-playbook \
    -i "$CLONE_DIR/ansible/inventory.yml" \
    "$CLONE_DIR/ansible/playbook.yml" \
    --extra-vars "setup_user=$REAL_USER repo_branch=$BRANCH" \
    2>&1 | tee -a "$LOG_FILE"

# --- 5. Aufraeumen ---
rm -rf "$CLONE_DIR"
rm -f "$LOG_FILE"
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

echo "[+] Setup abgeschlossen. VM ist bereit."
