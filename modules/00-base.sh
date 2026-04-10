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

echo "[00-base] Fertig."