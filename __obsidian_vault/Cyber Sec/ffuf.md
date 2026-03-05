---
title: "ffuf"
tags: [ffuf, fuzzing, web, enumeration, tools, recon]
---

# ffuf – Fuzz Faster U Fool

Schneller Web-Fuzzer in Go. Ersetzt das `FUZZ`-Keyword in URL, Headern oder POST-Daten durch Einträge aus einer Wordlist und wertet die Antworten aus. Minimal zwei Pflichtparameter: `-w` (Wordlist) und `-u` (URL mit FUZZ-Keyword).

```bash
ffuf -w wordlist.txt -u http://target.com/FUZZ
```

---

## Flags – Übersicht

### Input

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-w <datei>` | Wordlist (Pflicht). Optionales Keyword nach Doppelpunkt. | `-w list.txt` oder `-w list.txt:KEYWORD` |
| `-u <url>` | Ziel-URL mit FUZZ-Keyword (Pflicht) | `-u http://target.com/FUZZ` |
| `-X <methode>` | HTTP-Methode (Standard: GET) | `-X POST` |
| `-d <data>` | POST-Daten | `-d 'user=admin&pass=FUZZ'` |
| `-H <header>` | HTTP-Header setzen. Mehrfach verwendbar. | `-H "Authorization: Bearer TOKEN"` |
| `-b <cookie>` | Cookie-Daten | `-b "session=abc123"` |
| `-r` | Redirects folgen | `-r` |
| `-recursion` | Gefundene Verzeichnisse rekursiv fuzzen (nur mit URL-Ende `/FUZZ`) | `-recursion` |
| `-recursion-depth <n>` | Maximale Rekursionstiefe | `-recursion-depth 2` |
| `-e <ext>` | Dateiendungen anhängen (kommagetrennt) | `-e .php,.html,.txt` |
| `-mode <modus>` | Multi-Wordlist-Modus: `clusterbomb` (alle Kombos), `pitchfork` (synchron), `sniper` | `-mode clusterbomb` |
| `-request <datei>` | Raw HTTP-Request aus Datei laden (z.B. aus Burp) | `-request req.txt` |

### Matcher – was angezeigt wird

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-mc <codes>` | Match auf HTTP-Statuscodes (Standard: 200,204,301,302,307,401,403). `all` für alles. | `-mc 200,301` oder `-mc all` |
| `-ms <größe>` | Match auf Response-Größe in Bytes | `-ms 1234` |
| `-ml <zeilen>` | Match auf Anzahl Zeilen in der Antwort | `-ml 20` |
| `-mw <wörter>` | Match auf Anzahl Wörter in der Antwort | `-mw 50` |
| `-mr <regex>` | Match auf Regex-Muster in der Antwort | `-mr "Welcome"` |

### Filter – was ausgeblendet wird

Jeder Matcher hat ein Filter-Gegenstück. Filter schließen Treffer aus, Matcher schließen ein.

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-fc <codes>` | Filter auf HTTP-Statuscodes | `-fc 404,403` |
| `-fs <größe>` | Filter auf Response-Größe | `-fs 4242` |
| `-fl <zeilen>` | Filter auf Anzahl Zeilen | `-fl 10` |
| `-fw <wörter>` | Filter auf Anzahl Wörter | `-fw 3913` |
| `-fr <regex>` | Filter auf Regex-Muster | `-fr "error"` |
| `-ac` | Auto-Calibration: erkennt und filtert Standardantworten automatisch | `-ac` |

> `-ac` ist praktisch wenn man die Standard-Response-Größe nicht kennt. Führt erst ein paar Kalibrierungs-Requests durch und filtert dann identische Antworten heraus.

### Output

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-o <datei>` | Ergebnisse in Datei schreiben | `-o results.json` |
| `-of <format>` | Ausgabeformat: `json`, `html`, `md`, `csv`, `all` (Standard: json) | `-of html` |
| `-c` | Farbige Ausgabe | `-c` |
| `-v` | Verbose – zeigt vollständige URL in Ergebnissen | `-v` |
| `-s` | Silent Mode – nur Treffer ausgeben, kein Banner | `-s` |

### Performance & Stealth

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-t <n>` | Anzahl paralleler Threads (Standard: 40) | `-t 10` |
| `-rate <n>` | Requests pro Sekunde (Rate-Limiting) | `-rate 5` |
| `-p <sek>` | Delay zwischen Requests (Zahl oder Bereich) | `-p 0.5` oder `-p 0.1-2.0` |
| `-maxtime <sek>` | Maximale Laufzeit gesamt | `-maxtime 300` |
| `-maxtime-job <sek>` | Maximale Laufzeit pro Job (nützlich mit `-recursion`) | `-maxtime-job 60` |
| `-timeout <sek>` | HTTP-Request-Timeout (Standard: 10) | `-timeout 5` |

### Proxy & SSL

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-x <proxy>` | HTTP-Proxy (z.B. Burp Suite) | `-x http://127.0.0.1:8080` |
| `-k` | SSL-Zertifikatsprüfung deaktivieren (self-signed certs) | `-k` |
| `-replay-proxy <proxy>` | Nur Treffer über diesen Proxy weiterleiten – nützlich wenn man nicht den vollen Traffic durch Burp leiten will, sondern nur interessante Responses | `-replay-proxy http://127.0.0.1:8080` |

---

## Praxisbeispiele

### Directory & File Enumeration

```bash
# Verzeichnisse fuzzen
ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt \
     -u http://target.com/FUZZ

# Mit Dateiendungen
ffuf -w /usr/share/seclists/Discovery/Web-Content/raft-large-words.txt \
     -u http://target.com/FUZZ \
     -e .php,.html,.txt,.bak

# Rekursiv mit Tiefenbegrenzung
ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt \
     -u http://target.com/FUZZ \
     -recursion -recursion-depth 2

# Nur 200er anzeigen, sauber und gefärbt
ffuf -w wordlist.txt -u http://target.com/FUZZ -mc 200 -c
```

### Subdomain / VHost Enumeration

```bash
# Subdomain-Fuzzing via DNS
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
     -u http://FUZZ.target.com \
     -mc 200

# VHost-Enumeration via Host-Header
# Zuerst Standardgröße ermitteln, dann filtern:
ffuf -w /usr/share/seclists/Discovery/DNS/namelist.txt \
     -H "Host: FUZZ.target.com" \
     -u http://TARGET_IP \
     -fs 2395    # Standardgröße der Default-Response ausschließen
```

> Beim VHost-Fuzzing immer `-fs` mit der Größe der Standardantwort verwenden, sonst zeigt ffuf für jede Subdomain denselben Treffer. Standardgröße einmalig ohne Filter laufen lassen und ablesen.

### GET-Parameter Enumeration

```bash
# Parameter-Namen finden
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt \
     -u "http://target.com/page.php?FUZZ=test" \
     -fs 4242    # Standardgröße der Fehlantwort filtern

# Parameterwerte fuzzen (bekannter Parameter)
ffuf -w values.txt \
     -u "http://target.com/page.php?id=FUZZ" \
     -fc 401
```

### Backup-Dateien & Extension-Fuzzing

```bash
# Bekannte Datei – mögliche Backup-Endungen testen
echo -e "bak\nold\ntmp\nbackup\n~\nswp\ncopy" > backup_ext.txt
ffuf -w backup_ext.txt -u http://target.com/config.php.FUZZ -mc 200

# Extension einer bekannten Datei fuzzen
ffuf -w backup_ext.txt -u http://target.com/index.FUZZ -mc 200
```

### HTTP-Methoden fuzzen

```bash
# Welche Methoden akzeptiert ein Endpunkt?
echo -e "GET\nPOST\nPUT\nDELETE\nPATCH\nHEAD\nOPTIONS\nTRACE" > methods.txt
ffuf -w methods.txt -u http://target.com/api/users -X FUZZ -mc 200,201,204,405
```

### POST-Daten fuzzen

```bash
# Login-Formular (Passwort fuzzen)
ffuf -w /usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt \
     -u http://target.com/login \
     -X POST \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=admin&password=FUZZ" \
     -fc 401 -c

# JSON-POST fuzzen
ffuf -w usernames.txt \
     -u http://target.com/api/user \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"username": "FUZZ", "password": "test"}' \
     -mr "welcome"
```

### IDOR – ID-Enumeration

```bash
# Zahlenliste für sequentielle IDs erzeugen
seq 1 1000 > ids.txt

# GET-Parameter mit IDs fuzzen
ffuf -w ids.txt \
     -u "http://target.com/api/v1/customer?id=FUZZ" \
     -H "Cookie: session=YOUR_SESSION" \
     -mc 200 -c

# POST mit ID fuzzen
ffuf -w ids.txt \
     -u http://target.com/profile \
     -X POST \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "id=FUZZ" \
     -mc 200
```

### Multi-Wordlist Fuzzing

```bash
# Clusterbomb: alle Kombinationen (Standard)
ffuf -w users.txt:USER -w passwords.txt:PASS \
     -u http://target.com/login \
     -X POST \
     -d "user=USER&pass=PASS" \
     -fc 401

# Pitchfork: synchron (Zeile 1 aus Liste A + Zeile 1 aus Liste B)
ffuf -w users.txt:USER -w passwords.txt:PASS \
     -u http://target.com/login \
     -X POST \
     -d "user=USER&pass=PASS" \
     -mode pitchfork \
     -fc 401
```

---

## Empfohlene Wordlists (SecLists)

| Zweck | Pfad |
|-------|------|
| Web-Content allgemein | `/usr/share/seclists/Discovery/Web-Content/common.txt` |
| Große Verzeichnisliste | `/usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt` |
| Parameternamen | `/usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt` |
| Subdomains (klein) | `/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt` |
| Subdomains (groß) | `/usr/share/seclists/Discovery/DNS/namelist.txt` |
| Passwörter | `/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt` |
| Passwörter (groß) | `/usr/share/wordlists/rockyou.txt` |

SecLists installieren: `sudo apt install seclists` (Kali) oder von [GitHub](https://github.com/danielmiessler/SecLists).

---

## Typische Filter-Strategie

Rauschen reduzieren ist der wichtigste Schritt – ohne Filter liefert ffuf bei großen Wordlists tausende bedeutungslose Treffer.

1. Erst ohne Filter laufen lassen und die Standardantwort-Größe ablesen
2. Diese Größe mit `-fs <n>` ausfiltern
3. Alternativ `-ac` (Auto-Calibration) verwenden
4. Bekannte Fehlercodes mit `-fc 404,403` ausblenden wenn nötig

```bash
# Workflow-Beispiel: VHost-Enumeration
# Schritt 1: Standardgröße ablesen (z.B. 2395 Bytes bei allen Antworten)
ffuf -w namelist.txt -H "Host: FUZZ.target.com" -u http://TARGET -mc all

# Schritt 2: Standardgröße filtern
ffuf -w namelist.txt -H "Host: FUZZ.target.com" -u http://TARGET -fs 2395
```

---

## Stealth & Proxy

ffuf ist standardmäßig sehr laut (40 Threads). Für weniger Auffälligkeit:

```bash
# Langsam und unauffällig
ffuf -w wordlist.txt -u http://target.com/FUZZ -t 5 -rate 2 -p 0.5

# Mit zufälligem Delay
ffuf -w wordlist.txt -u http://target.com/FUZZ -p 0.1-2.0

# User-Agent anpassen (Browser imitieren)
ffuf -w wordlist.txt -u http://target.com/FUZZ \
     -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
```

### Burp Suite Integration

Zwei Workflows:

**Vollständig durch Burp leiten** – alle Requests sichtbar im Proxy-Tab:
```bash
ffuf -w wordlist.txt -u http://target.com/FUZZ -x http://127.0.0.1:8080
```

**Nur Treffer durch Burp leiten** (`-replay-proxy`) – ffuf läuft schnell, nur interessante Responses werden zur manuellen Analyse an Burp weitergeleitet:
```bash
ffuf -w wordlist.txt -u http://target.com/FUZZ \
     -fc 404 \
     -replay-proxy http://127.0.0.1:8080
```

Der zweite Ansatz ist effizienter: ffuf arbeitet mit voller Geschwindigkeit, Burp sieht nur die relevanten Treffer.

### HTTPS mit self-signed Zertifikat

```bash
ffuf -w wordlist.txt -u https://target.com/FUZZ -k
```

---

## Bezug zu anderen Themen

- [[2026-02-12-idor]] – IDOR-Enumeration: ffuf zur Automatisierung der API-ID-Iteration (`?id=FUZZ`) einsetzen, was im IDOR-Raum noch manuell über den Browser gemacht wurde
- [[2026-03-20-h4cked]] – Verzeichnissuche auf dem FTP-Webroot als möglicher ffuf-Anwendungsfall nach initialem Zugang
- [[2026-02-23-infinity-shell]] – Webshell-Suche: ffuf hätte `images.php` als anomale Datei im `/img/`-Verzeichnis über File-Fuzzing mit `-e .php` finden können

---

## Referenzen

- [ffuf GitHub Repository](https://github.com/ffuf/ffuf)
- [ffuf Wiki (offizielle Doku)](https://github.com/ffuf/ffuf/wiki)
- [ffuf.me – interaktive Übungsplattform](http://ffuf.me)
- [SecLists](https://github.com/danielmiessler/SecLists)
- [Everything you need to know about FFUF – codingo](https://codingo.io/tools/ffuf/bounty/2020/09/17/everything-you-need-to-know-about-ffuf.html)
