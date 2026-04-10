#!/usr/bin/env bash
set -euo pipefail

HOSTS_FILE="/etc/hosts"
COURSE="${COURSE_TITLE:-KALI COURSE}"
BLOCK_START="# --- ${COURSE^^} DOMAINS ---"
BLOCK_END="# --- END ${COURSE^^} ---"

echo "[60-hosts] Konfiguriere /etc/hosts fuer lokale Vorlesungs-Domains..."

DOCKER_BRIDGE_IP=$(ip -4 addr show docker0 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1)
if [[ -z "$DOCKER_BRIDGE_IP" ]]; then
    echo "[60-hosts] WARN: docker0-Interface nicht gefunden, verwende Fallback 172.17.0.1"
    DOCKER_BRIDGE_IP="172.17.0.1"
fi

DOCKER_DOMAIN="${COURSE_DOCKER_DOMAIN:-malicious.com}"

if [[ -n "${COURSE_DOMAINS_STRING:-}" ]]; then
    read -ra DOMAINS <<< "$COURSE_DOMAINS_STRING"
else
    DOMAINS=(attacker.com honest-sp.com honest-idp.com malicious.com)
fi

sed -i "/$BLOCK_START/,/$BLOCK_END/d" "$HOSTS_FILE"

{
    echo ""
    echo "$BLOCK_START"
    for domain in "${DOMAINS[@]}"; do
        # Dynamischer Abgleich statt hardcodiertem "malicious.com"
        if [[ "$domain" == "$DOCKER_DOMAIN" ]]; then
            echo "${DOCKER_BRIDGE_IP}  $domain"
        else
            echo "127.0.0.1         $domain"
        fi
    done
    echo "$BLOCK_END"
} >> "$HOSTS_FILE"

echo "[60-hosts] Fertig."