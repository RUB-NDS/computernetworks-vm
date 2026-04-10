#!/usr/bin/env bash
set -euo pipefail

CERT_DIR="${COURSE_CERT_DIR:-/etc/ssl/kali-course}"
CA_NAME="${COURSE_CA_NAME:-kali-course Root CA}"
ORG="${COURSE_ORG:-kali-course}"
CA_CERT="$CERT_DIR/ca.crt"
CA_KEY="$CERT_DIR/ca.key"
SRV_CERT="$CERT_DIR/server.crt"
SRV_KEY="$CERT_DIR/server.key"

# Wandelt den exportierten String wieder in ein Array um
if [[ -n "${COURSE_DOMAINS_STRING:-}" ]]; then
    read -ra DOMAINS <<< "$COURSE_DOMAINS_STRING"
else
    DOMAINS=(attacker.com honest-sp.com honest-idp.com malicious.com)
fi

echo "[10-apache-ssl] Konfiguriere Apache und PKI..."
apt-get -qq install -y apache2
mkdir -p "$CERT_DIR"

if [[ ! -f "$CA_CERT" || ! -f "$SRV_CERT" ]]; then
    echo "[10-apache-ssl] Erstelle Root-CA und Server-Zertifikate..."

    openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
        -keyout "$CA_KEY" -out "$CA_CERT" \
        -subj "/C=DE/ST=NRW/O=${ORG}/CN=${CA_NAME}" \
        -addext "basicConstraints=critical,CA:TRUE" 2>/dev/null

    # SAN-Einträge dynamisch aus DOMAINS-Array
    SAN_DNS=""
    for i in "${!DOMAINS[@]}"; do
        SAN_DNS+="DNS.$((i+2)) = ${DOMAINS[$i]}"$'\n'
    done

    cat > /tmp/openssl-san.cnf <<EOF
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no

[req_distinguished_name]
C  = DE
ST = NRW
O  = ${ORG}
CN = localhost

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
${SAN_DNS}IP.1  = 127.0.0.1
EOF

    openssl req -new -nodes -newkey rsa:2048 \
        -keyout "$SRV_KEY" -out /tmp/server.csr \
        -config /tmp/openssl-san.cnf 2>/dev/null

    cat > /tmp/openssl-ext.cnf <<EOF
basicConstraints = CA:FALSE
extendedKeyUsage = serverAuth
subjectAltName   = @alt_names

[alt_names]
DNS.1 = localhost
${SAN_DNS}IP.1  = 127.0.0.1
EOF

    openssl x509 -req -days 825 \
        -in /tmp/server.csr \
        -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
        -out "$SRV_CERT" \
        -extfile /tmp/openssl-ext.cnf 2>/dev/null

    chmod 644 "$CA_CERT" "$SRV_CERT"
    chmod 600 "$CA_KEY" "$SRV_KEY"
    rm /tmp/openssl-san.cnf /tmp/openssl-ext.cnf /tmp/server.csr "$CERT_DIR/ca.srl" || true
else
    echo "[10-apache-ssl] Zertifikate existieren bereits, überspringe Neugenerierung."
fi

echo "[10-apache-ssl] Schreibe Apache-Konfiguration..."
VHOST_CONF="/etc/apache2/sites-available/${COURSE_ID:-kali-course}-ssl.conf"
cat > "$VHOST_CONF" <<EOF
<IfModule mod_ssl.c>
    <VirtualHost _default_:443>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
        SSLEngine on
        SSLCertificateFile      $SRV_CERT
        SSLCertificateKeyFile   $SRV_KEY
        SSLCertificateChainFile $CA_CERT
    </VirtualHost>
</IfModule>
EOF

a2enmod ssl
a2dissite default-ssl || true
a2ensite "${COURSE_ID:-kali-course}-ssl"
systemctl enable apache2
systemctl restart apache2

echo "[10-apache-ssl] Fertig."