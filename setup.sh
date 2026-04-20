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
KEYBOARD="${2:-}"
REPO_URL="https://github.com/RUB-NDS/computernetworks-vm.git"
CLONE_DIR="/tmp/computernetworks-vm"
LOG_FILE="/var/log/kali-setup.log"
STATE_DIR="/var/lib/kali-setup"
REAL_USER="${SUDO_USER:-kali}"

echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║       Kali VM Setup – Computernetze      ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

# --- Tastaturlayout abfragen (falls nicht per Argument uebergeben) ---
if [[ -z "$KEYBOARD" ]]; then
    echo "  Verfuegbare Tastaturlayouts: de, us, gb, fr, es, it, ..."
    printf "  Tastaturlayout [de]: "
    read -r KEYBOARD < /dev/tty 2>/dev/null || true
    KEYBOARD="${KEYBOARD:-de}"
fi

echo ""
echo "[*] $(date '+%Y-%m-%d %H:%M:%S') Kali Setup startet (User: $REAL_USER, Tastatur: $KEYBOARD)" | tee -a "$LOG_FILE"

# --- Einstellung persistent speichern ---
mkdir -p "$STATE_DIR"
echo "$KEYBOARD" > "$STATE_DIR/keyboard_layout"

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
    --extra-vars "setup_user=$REAL_USER repo_branch=$BRANCH keyboard_layout=$KEYBOARD" \
    2>&1 | tee -a "$LOG_FILE"

# --- 5. Aufraeumen ---
rm -rf "$CLONE_DIR"
rm -f "$LOG_FILE"
rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

echo "[+] Setup abgeschlossen. VM ist bereit."
