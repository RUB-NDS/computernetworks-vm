# Kali Linux VM Setup

Dieses Setup richtet eure Kali-VM automatisch fuer die Vorlesung ein –
inklusive Apache mit TLS, Browser-Trust-Stores, Docker und VS Code.

Die Konfiguration erfolgt ueber ein **Ansible Playbook** mit einzelnen
Rollen fuer jede Komponente. Bei jedem Start der VM wird das Playbook
automatisch ausgefuehrt, sodass die VM immer aktuell ist.

---

## Installation

Oeffnet ein Terminal und fuehrt folgenden Befehl aus:

```bash
wget -qO- https://raw.githubusercontent.com/RUB-NDS/computernetworks-vm/feature/ansible-playbook/setup.sh \
  | sudo bash -s -- feature/ansible-playbook
```

Falls `wget` nicht verfuegbar ist, alternativ mit `curl`:
```bash
curl -fsSL https://raw.githubusercontent.com/RUB-NDS/computernetworks-vm/feature/ansible-playbook/setup.sh \
  | sudo bash -s -- feature/ansible-playbook
```

> **Hinweis:** Der Befehl benoetigt Root-Rechte. Gebt euer Passwort ein,
> wenn ihr dazu aufgefordert werdet.

Das Setup laeuft vollautomatisch und dauert je nach Internetverbindung
**5–15 Minuten**. Das vollstaendige Log wird unter
`/var/log/kali-setup.log` gespeichert.

Nach Abschluss des Setups einmal **ausloggen und neu einloggen** –
erst dann sind Gruppenrechte (Docker) und Spracheinstellungen vollstaendig aktiv.

---

## VM aktualisieren

Die VM aktualisiert sich bei jedem Neustart automatisch ueber einen
systemd-Service (`kali-setup-update`). Alternativ koennt ihr das Update
manuell ausloesen:

```bash
vm-update
```

Log des letzten Auto-Updates:
```bash
cat /var/log/kali-setup-update.log
```

---

## Checkliste: Setup verifizieren

Fuehrt die folgenden Tests **nach dem Logout/Login** im Terminal durch, um sicherzustellen, dass alles funktioniert.

### 1. Webserver & TLS

**Apache laeuft:**
```bash
systemctl is-active apache2
```
Erwartete Ausgabe: `active`

**HTTPS lokal erreichbar:**
```bash
curl -s -o /dev/null -w "%{http_code}" https://localhost
```
Erwartete Ausgabe: `200`

**TLS-Zertifikat ist gueltig:**
```bash
curl -sv https://localhost 2>&1 | grep -E "issuer|subject|SSL"
```
Erwartet: Zeilen mit `issuer: O=Computernetze` und `subject: CN=localhost`

**Root-CA im System-Trust-Store:**
```bash
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/computernetze/server.crt
```
Erwartete Ausgabe: `/etc/ssl/computernetze/server.crt: OK`

### 2. Vorlesungs-Domains

**Domains sind aufloesbar:**
```bash
for domain in attacker.com honest-sp.com honest-idp.com malicious.com; do
    echo "$domain -> $(getent hosts $domain | awk '{print $1}')"
done
```
Erwartete Ausgabe:
`attacker.com -> 127.0.0.1`
`honest-sp.com -> 127.0.0.1`
`honest-idp.com -> 127.0.0.1`
`malicious.com -> 172.17.0.1` (oder aehnlich)

### 3. Docker & Tools

**Docker laeuft ohne Sudo-Rechte:**
```bash
docker ps
```
Erwartet: Eine Tabelle mit `CONTAINER ID`, `IMAGE`, etc. (Kein "permission denied" Fehler!)

**VS Code & Erweiterung sind installiert:**
```bash
code --list-extensions
```
Erwartet: `humao.rest-client` taucht in der Liste auf.

### 4. Browser Trust-Stores

Oeffnet **Google Chrome** und **Firefox** und ruft jeweils auf:
`https://localhost`

Erwartet: **Keine** Sicherheitswarnung. Ein gruenes/geschlossenes Schloss-Symbol in der Adressleiste.

### 5. Auto-Update

**Systemd-Service ist aktiviert:**
```bash
systemctl is-enabled kali-setup-update
```
Erwartete Ausgabe: `enabled`

---

## Fehlerbehebung

| Symptom | Loesung |
|---|---|
| `curl: (60) SSL certificate problem` | `sudo update-ca-certificates -f` ausfuehren |
| Chrome zeigt Zertifikatsfehler | Chrome komplett schliessen und neu starten |
| `malicious.com` loest nicht auf `172.17.x.x` auf | `sudo systemctl start docker` und dann `vm-update` ausfuehren |
| Apache nicht aktiv | `sudo systemctl restart apache2` und mit `journalctl -xe` pruefen |
| Befehl `docker` schlaegt mit *permission denied* fehl | Logout und Login vergessen! Holt das jetzt nach. |
| Auto-Update schlaegt fehl | `cat /var/log/kali-setup-update.log` pruefen |

---

## Log einsehen
Falls ihr Probleme habt, schaut ins Logfile oder gebt dieses bei Fragen an eure Betreuer weiter:
```bash
# Initiales Setup
cat /var/log/kali-setup.log

# Auto-Update
cat /var/log/kali-setup-update.log
```
