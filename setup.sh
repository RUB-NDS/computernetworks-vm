#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "[-] Fehler: Bitte mit 'sudo bash' ausfuehren."
    exit 1
fi

# ============================================================
# KONFIGURATION
# ============================================================
BRANCH="${KALI_SETUP_BRANCH:-main}"
REPO_URL="https://github.com/RUB-NDS/computernetworks-vm.git"
CLONE_DIR="/tmp/computernetworks-vm"
LOG_FILE="/var/log/kali-setup.log"
REAL_USER="${SUDO_USER:-kali}"

echo "[*] $(date '+%Y-%m-%d %H:%M:%S') Kali Setup startet (User: $REAL_USER)" | tee -a "$LOG_FILE"

# --- 1. Ansible und Git installieren ---
echo "[*] Installiere Ansible und Git..." | tee -a "$LOG_FILE"
apt-get -qq update
apt-get -qq install -y ansible git

# --- 2. Repository klonen ---
rm -rf "$CLONE_DIR"
echo "[*] Klone Repository (Branch: $BRANCH)..." | tee -a "$LOG_FILE"
git clone -b "$BRANCH" --depth 1 "$REPO_URL" "$CLONE_DIR"

# --- 3. Ansible Playbook ausfuehren ---
echo "[*] Starte Ansible Playbook..." | tee -a "$LOG_FILE"
ANSIBLE_FORCE_COLOR=1 ansible-playbook \
    -i "$CLONE_DIR/ansible/inventory.yml" \
    "$CLONE_DIR/ansible/playbook.yml" \
    --extra-vars "setup_user=$REAL_USER" \
    2>&1 | tee -a "$LOG_FILE"

# --- 4. Commit-Hash speichern (verhindert erneuten Lauf beim ersten Boot) ---
COMMIT_HASH=$(git -C "$CLONE_DIR" rev-parse HEAD)
mkdir -p /var/lib/kali-setup
echo "$COMMIT_HASH" > /var/lib/kali-setup/last-commit

# --- 5. Aufraeumen ---
rm -rf "$CLONE_DIR"
rm -f "$LOG_FILE"
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

echo "[+] Setup abgeschlossen. VM ist bereit."
