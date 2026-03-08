---
title: "ffuf"
tags: [ffuf, fuzzing, web, enumeration, tools, recon]
---

# ffuf – Fuzz Faster U Fool

Schneller Web-Fuzzer in Go. Ersetzt das `FUZZ`-Keyword in URL, Headern oder POST-Daten durch Einträge aus einer Wordlist und wertet die Antworten aus. Minimal zwei Pflichtparameter: `-w` (Wordlist) und `-u` (URL mit FUZZ-Keyword).

```bash
ffuf -w wordlist.txt -u http://target.com/FUZZ
```

> [!example] Tools — ffuf
> | Tool | Typ | Zweck |
> |------|-----|-------|
> | **ffuf** | CLI | Web-Fuzzer: Verzeichnisse, Subdomains, Parameter, Credentials |
> | **SecLists** | Wordlist-Sammlung | Vorgefertigte Wordlists für alle gängigen Fuzz-Szenarien |
> | **Burp Suite** | GUI/Proxy | Traffic-Inspektion; per `-x` oder `-replay-proxy` integrierbar |
> | **seq** | CLI (Linux) | Zahlenlisten für ID-Enumeration erzeugen (`seq 1 1000 > ids.txt`) |

---

## Flags – Übersicht

### ==Input==

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
| `-mode <modus>` | Multi-Wordlist-Modus: `clusterbomb` (alle Kombos), `pitchfork` (synchron) | `-mode clusterbomb` |
| `-request <datei>` | Raw HTTP-Request aus Datei laden (z.B. aus Burp) | `-request req.txt` |

### ==Matcher – was angezeigt wird==

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-mc <codes>` | Match auf HTTP-Statuscodes (Standard: 200,204,301,302,307,401,403). `all` für alles. | `-mc 200,301` oder `-mc all` |
| `-ms <größe>` | Match auf Response-Größe in Bytes | `-ms 1234` |
| `-ml <zeilen>` | Match auf Anzahl Zeilen in der Antwort | `-ml 20` |
| `-mw <wörter>` | Match auf Anzahl Wörter in der Antwort | `-mw 50` |
| `-mr <regex>` | Match auf Regex-Muster in der Antwort | `-mr "Welcome"` |

### ==Filter – was ausgeblendet wird==

Jeder Matcher hat ein Filter-Gegenstück. Filter schließen Treffer aus, Matcher schließen ein.

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-fc <codes>` | Filter auf HTTP-Statuscodes | `-fc 404,403` |
| `-fs <größe>` | Filter auf Response-Größe | `-fs 4242` |
| `-fl <zeilen>` | Filter auf Anzahl Zeilen | `-fl 10` |
| `-fw <wörter>` | Filter auf Anzahl Wörter | `-fw 3913` |
| `-fr <regex>` | Filter auf Regex-Muster | `-fr "error"` |
| `-ac` | Auto-Calibration: erkennt und filtert Standardantworten automatisch | `-ac` |

> [!tip] `-ac` Auto-Calibration
> Praktisch wenn die Standard-Response-Größe unbekannt ist. ffuf führt erst einige Kalibrierungs-Requests durch und filtert dann identische Antworten automatisch heraus.

### ==Output==

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-o <datei>` | Ergebnisse in Datei schreiben | `-o results.json` |
| `-of <format>` | Ausgabeformat: `json`, `html`, `md`, `csv`, `all` | `-of html` |
| `-c` | Farbige Ausgabe | `-c` |
| `-v` | Verbose – zeigt vollständige URL in Ergebnissen | `-v` |
| `-s` | Silent Mode – nur Treffer ausgeben, kein Banner | `-s` |

### ==Performance & Stealth==

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-t <n>` | Anzahl paralleler Threads (Standard: 40) | `-t 10` |
| `-rate <n>` | Requests pro Sekunde (Rate-Limiting) | `-rate 5` |
| `-p <sek>` | Delay zwischen Requests (Zahl oder Bereich) | `-p 0.5` oder `-p 0.1-2.0` |
| `-maxtime <sek>` | Maximale Laufzeit gesamt | `-maxtime 300` |
| `-maxtime-job <sek>` | Maximale Laufzeit pro Job (nützlich mit `-recursion`) | `-maxtime-job 60` |
| `-timeout <sek>` | HTTP-Request-Timeout (Standard: 10) | `-timeout 5` |

### ==Proxy & SSL==

| Flag | Beschreibung | Beispiel |
|------|-------------|---------|
| `-x <proxy>` | HTTP-Proxy (z.B. Burp Suite) | `-x http://127.0.0.1:8080` |
| `-k` | SSL-Zertifikatsprüfung deaktivieren (self-signed certs) | `-k` |
| `-replay-proxy <proxy>` | Nur Treffer über diesen Proxy leiten – ffuf läuft schnell, Burp sieht nur interessante Responses | `-replay-proxy http://127.0.0.1:8080` |

---

## Praxisbeispiele

### ==Directory & File Enumeration==

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
```

### ==Subdomain / VHost Enumeration==

```bash
# Subdomain-Fuzzing via DNS
ffuf -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
     -u http://FUZZ.target.com -mc 200

# VHost-Enumeration via Host-Header
ffuf -w /usr/share/seclists/Discovery/DNS/namelist.txt \
     -H "Host: FUZZ.target.com" \
     -u http://TARGET_IP \
     -fs 2395    # Standardgröße der Default-Response ausschließen
```

> [!tip] VHost-Fuzzing: immer `-fs` setzen
> Ohne `-fs` mit der Größe der Standardantwort zeigt ffuf für jede Subdomain denselben Treffer. Erst einmal ohne Filter laufen lassen, Größe ablesen, dann filtern.

### ==GET-Parameter Enumeration==

```bash
# Parameter-Namen finden
ffuf -w /usr/share/seclists/Discovery/Web-Content/burp-parameter-names.txt \
     -u "http://target.com/page.php?FUZZ=test" \
     -fs 4242

# Parameterwerte fuzzen (bekannter Parameter)
ffuf -w values.txt -u "http://target.com/page.php?id=FUZZ" -fc 401
```

### ==IDOR – ID-Enumeration==

```bash
# Zahlenliste erzeugen
seq 1 1000 > ids.txt

# GET-Parameter mit IDs fuzzen
ffuf -w ids.txt \
     -u "http://target.com/api/v1/customer?id=FUZZ" \
     -H "Cookie: session=YOUR_SESSION" \
     -mc 200 -c
```

### ==POST-Daten fuzzen==

```bash
# Login-Formular
ffuf -w /usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt \
     -u http://target.com/login \
     -X POST \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "username=admin&password=FUZZ" \
     -fc 401 -c

# JSON-POST
ffuf -w usernames.txt \
     -u http://target.com/api/user \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"username": "FUZZ", "password": "test"}' \
     -mr "welcome"
```

### ==Multi-Wordlist Fuzzing==

```bash
# Clusterbomb: alle Kombinationen
ffuf -w users.txt:USER -w passwords.txt:PASS \
     -u http://target.com/login -X POST \
     -d "user=USER&pass=PASS" -fc 401

# Pitchfork: synchron (Zeile 1+1, 2+2, ...)
ffuf -w users.txt:USER -w passwords.txt:PASS \
     -u http://target.com/login -X POST \
     -d "user=USER&pass=PASS" -mode pitchfork -fc 401
```

### ==Backup-Dateien & Extension-Fuzzing==

```bash
echo -e "bak\nold\ntmp\nbackup\n~\nswp\ncopy" > backup_ext.txt
ffuf -w backup_ext.txt -u http://target.com/config.php.FUZZ -mc 200
```

### ==HTTP-Methoden fuzzen==

```bash
echo -e "GET\nPOST\nPUT\nDELETE\nPATCH\nHEAD\nOPTIONS\nTRACE" > methods.txt
ffuf -w methods.txt -u http://target.com/api/users -X FUZZ -mc 200,201,204,405
```

---

## Typische Filter-Strategie

> [!info] Workflow: Rauschen reduzieren
> 1. Erst ohne Filter laufen lassen und die Standardantwort-Größe ablesen
> 2. Diese Größe mit `-fs <n>` ausfiltern
> 3. Alternativ `-ac` (Auto-Calibration) verwenden
> 4. Bekannte Fehlercodes mit `-fc 404,403` zusätzlich ausblenden
>
> ```bash
> # Schritt 1: Standardgröße ablesen
> ffuf -w namelist.txt -H "Host: FUZZ.target.com" -u http://TARGET -mc all
> # Schritt 2: Standardgröße filtern
> ffuf -w namelist.txt -H "Host: FUZZ.target.com" -u http://TARGET -fs 2395
> ```

---

## Stealth & Burp Integration

```bash
# Langsam und unauffällig
ffuf -w wordlist.txt -u http://target.com/FUZZ -t 5 -rate 2 -p 0.5

# User-Agent anpassen
ffuf -w wordlist.txt -u http://target.com/FUZZ \
     -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

# Vollständig durch Burp leiten
ffuf -w wordlist.txt -u http://target.com/FUZZ -x http://127.0.0.1:8080

# Nur Treffer durch Burp leiten (effizienter)
ffuf -w wordlist.txt -u http://target.com/FUZZ \
     -fc 404 -replay-proxy http://127.0.0.1:8080

# HTTPS mit self-signed Zertifikat
ffuf -w wordlist.txt -u https://target.com/FUZZ -k
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

SecLists installieren: `sudo apt install seclists`

---

## Bezug zu anderen Themen

- [[2026-02-12-idor]] – IDOR-Enumeration: ffuf zur Automatisierung der API-ID-Iteration (`?id=FUZZ`)
- [[2026-03-19-h4cked]] – Verzeichnissuche auf dem FTP-Webroot als möglicher ffuf-Anwendungsfall
- [[2026-02-23-infinity-shell]] – Webshell-Suche: ffuf hätte `images.php` über `-e .php` finden können

---

## Referenzen

- [ffuf GitHub Repository](https://github.com/ffuf/ffuf)
- [ffuf Wiki (offizielle Doku)](https://github.com/ffuf/ffuf/wiki)
- [ffuf.me – interaktive Übungsplattform](http://ffuf.me)
- [SecLists](https://github.com/danielmiessler/SecLists)
