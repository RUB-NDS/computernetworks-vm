#!/usr/bin/env bash
set -euo pipefail

echo "[00-base] Setze Root-Passwort und Shell..."
echo "root:${ROOT_PASSWORD:-toor}" | chpasswd
echo "${SUDO_USER:-kali}:${USER_PASSWORD:-kali}" | chpasswd
chsh -s /usr/bin/zsh "${SUDO_USER:-kali}"


echo "[00-base] Aktualisiere Paketquellen und installiere Basispakete..."
apt-get -qq update
apt-get -qq upgrade -y
apt-get -qq dist-upgrade -y

apt-get -qq install -y --no-install-recommends \
    ca-certificates curl gnupg wget htop tree tmux fzf ripgrep tealdeer httpie fish zsh eza

# Shell-Aliases fuer kali-User
ZSHRC="/home/${SUDO_USER:-kali}/.zshrc"
if ! grep -q 'alias updates=' "$ZSHRC" 2>/dev/null; then
    cat >> "$ZSHRC" <<'ALIASES'

# Kali VM Aliases
alias updates="sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean"
alias cleanup="sudo rm -f ~/.zsh_history ~/.bash_history /root/.zsh_history /root/.bash_history /var/log/kali-setup.log /var/log/auth.log* /var/log/syslog* /var/log/messages* /var/log/kern.log* /var/log/daemon.log* /var/log/dpkg.log* /var/log/alternatives.log* /var/log/bootstrap.log && sudo rm -rf /var/log/apt/* && sudo journalctl --rotate --vacuum-time=1s 2>/dev/null; sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null; fc -p /dev/null; echo '[+] Cleanup abgeschlossen.'"
ALIASES
fi

# Wireshark zu XFCE Whisker-Menu-Favoriten hinzufuegen
WHISKER_DEFAULTS="/etc/xdg/xfce4/whiskermenu/defaults.rc"
WIRESHARK_DESKTOP=$(find /usr/share/applications -maxdepth 1 -name '*wireshark*' -not -name '*.disabled*' -printf '%f\n' 2>/dev/null | head -1)
if [[ -f "$WHISKER_DEFAULTS" && -n "$WIRESHARK_DESKTOP" ]] && ! grep -q "$WIRESHARK_DESKTOP" "$WHISKER_DEFAULTS" 2>/dev/null; then
    sed -i "s/^favorites=\(.*\)/favorites=\1,$WIRESHARK_DESKTOP/" "$WHISKER_DEFAULTS"
    echo "[00-base] $WIRESHARK_DESKTOP zu Whisker-Menu-Favoriten hinzugefuegt."
fi

echo "[00-base] Fertig."