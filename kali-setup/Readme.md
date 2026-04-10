# Kali Linux VM Setup

Dieses Skript richtet eure Kali-VM automatisch für die Vorlesung ein –
inklusive Apache mit TLS, Browser-Trust-Stores, Docker und VS Code.

---

## Installation

Öffnet ein Terminal und führt folgenden Befehl aus:

```bash
curl -fsSL https://raw.githubusercontent.com/RUB-NDS/computernetworks-vm/main/kali-setup/setup.sh | sudo bash
```

> **Hinweis:** Der Befehl benötigt Root-Rechte. Gebt euer Passwort ein,
> wenn ihr dazu aufgefordert werdet.

Das Setup läuft vollautomatisch und dauert je nach Internetverbindung
**5–15 Minuten**. Das vollständige Log wird unter
`/var/log/kali-setup.log` gespeichert.

Nach Abschluss des Setups einmal **ausloggen und neu einloggen** –
erst dann sind Gruppenrechte (Docker) und Spracheinstellungen vollständig aktiv.

---

## Checkliste: Setup verifizieren

Führt die folgenden Tests **nach dem Logout/Login** im Terminal durch, um sicherzustellen, dass alles funktioniert.

### 1. Webserver & TLS

**Apache läuft:**
```bash
systemctl is-active apache2
```
✅ Erwartete Ausgabe: `active`

**HTTPS lokal erreichbar:**
```bash
curl -s -o /dev/null -w "%{http_code}" https://localhost
```
✅ Erwartete Ausgabe: `200`

**TLS-Zertifikat ist gültig:**
```bash
curl -sv https://localhost 2>&1 | grep -E "issuer|subject|SSL"
```
✅ Erwartet: Zeilen mit `issuer: O=Computernetze` und `subject: CN=localhost`

**Root-CA im System-Trust-Store:**
```bash
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/computernetze/server.crt
```
✅ Erwartete Ausgabe: `/etc/ssl/computernetze/server.crt: OK`

### 2. Vorlesungs-Domains

**Domains sind auflösbar:**
```bash
for domain in attacker.com honest-sp.com honest-idp.com malicious.com; do
    echo "$domain -> $(getent hosts $domain | awk '{print $1}')"
done
```
✅ Erwartete Ausgabe:
`attacker.com -> 127.0.0.1`
`honest-sp.com -> 127.0.0.1`
`honest-idp.com -> 127.0.0.1`
`malicious.com -> 172.17.0.1` (oder ähnlich)

### 3. Docker & Tools

**Docker läuft ohne Sudo-Rechte:**
```bash
docker ps
```
✅ Erwartet: Eine Tabelle mit `CONTAINER ID`, `IMAGE`, etc. (Kein "permission denied" Fehler!)

**VS Code & Erweiterung sind installiert:**
```bash
code --list-extensions
```
✅ Erwartet: `humao.rest-client` taucht in der Liste auf.

### 4. Browser Trust-Stores

Öffnet **Google Chrome** und **Firefox** und ruft jeweils auf:
`https://localhost`

✅ Erwartet: **Keine** Sicherheitswarnung. Ein grünes/geschlossenes Schloss-Symbol in der Adressleiste.

---

## Fehlerbehebung

| Symptom | Lösung |
|---|---|
| `curl: (60) SSL certificate problem` | `sudo update-ca-certificates -f` ausführen |
| Chrome zeigt Zertifikatsfehler | Chrome komplett schließen und neu starten |
| `malicious.com` löst nicht auf `172.17.x.x` auf | `sudo systemctl start docker` und dann `sudo bash /tmp/kali-modules/60-hosts.sh` (oder das komplette Setup-Skript) nochmal ausführen |
| Apache nicht aktiv | `sudo systemctl restart apache2` und mit `journalctl -xe` prüfen |
| Befehl `docker` schlägt mit *permission denied* fehl | Logout und Login vergessen! Holt das jetzt nach. |

---

## Log einsehen
Falls ihr Probleme habt, schaut ins Logfile oder gebt dieses bei Fragen an eure Betreuer weiter:
```bash
cat /var/log/kali-setup.log
```