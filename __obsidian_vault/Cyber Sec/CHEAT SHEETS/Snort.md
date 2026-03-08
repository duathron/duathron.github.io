---
title: "Snort"
tags: [snort, ids, ips, nids, nips, network-forensics, soc, tools]
---

# Snort

Snort ist ein Open-Source Network Intrusion Detection and Prevention System (NIDS/NIPS), entwickelt von Martin Roesch und gepflegt vom Cisco Talos Team. Es analysiert Netzwerktraffic in Echtzeit anhand regelbasierter Erkennung und kann Pakete, die definierten Signaturen entsprechen, entweder loggen, alarmieren oder blockieren.

Snort läuft in drei grundlegenden Betriebsmodi: Sniffer, Packet Logger und IDS/IPS.

> [!example] Tools — Snort
> | Tool | Typ | Zweck |
> |------|-----|-------|
> | **snort** | CLI (Dienst + Treiber) | IDS/IPS-Engine, Sniffer, Packet Logger, PCAP-Analyse |
> | **Wireshark** | GUI | Snort-Binärlogs (`.pcap`/`.log`) öffnen und inspizieren |
> | **local.rules** | Textdatei | Eigene Erkennungsregeln schreiben und testen |
> | **snort.conf** | Konfigurationsdatei | Globale Snort-Konfiguration, Regelsets einbinden |

---

## Betriebsmodi

### ==Mode 1: Sniffer Mode==

Liest Pakete live vom Interface und gibt sie auf der Konsole aus. Kein Logging, keine Regelprüfung – reine Paketanzeige.

```bash
sudo snort -v             # nur IP/TCP/UDP/ICMP-Header
sudo snort -vd            # Header + Payload (ASCII)
sudo snort -vde           # Header + Payload + Data-Link-Layer (Layer 2)
sudo snort -X             # rohe Paketdaten als Hex-Dump ab Link Layer
```

Typischer Anwendungsfall: schnelle Überprüfung, ob Traffic überhaupt ankommt.

### ==Mode 2: Packet Logger Mode==

Schreibt Pakete auf die Festplatte. Snort erkennt automatisch, dass es in diesen Modus wechseln soll, sobald `-l` angegeben wird.

```bash
sudo snort -dev -l ./log
sudo snort -dev -l ./log -h 192.168.1.0/24   # nur Traffic des Home-Netzes
sudo snort -dev -l ./log -b                   # binäres tcpdump-Format (schneller)
sudo snort -r snort.log.xxxxxxxx              # gespeichertes Log einlesen
sudo snort -r snort.log.xxxxxxxx -n 10        # nur erste 10 Pakete lesen
```

Logs werden standardmäßig in `/var/log/snort/` abgelegt, sortiert nach IP-Verzeichnissen. Mit `-b` wird eine einzige Binärdatei erzeugt, die auch Wireshark lesen kann.

### ==Mode 3: IDS/IPS Mode==

Wendet Regeln auf den Traffic an. Erfordert zwingend `-c` mit einem Konfigurationsfile.

```bash
sudo snort -c /etc/snort/snort.conf -l .
sudo snort -c /etc/snort/snort.conf -A console
sudo snort -c /etc/snort/snort.conf -A full -l .
sudo snort -c /etc/snort/snort.conf -i eth0      # auf Live-Interface
```

IPS (aktives Blockieren) erfordert zusätzlich DAQ inline mode, in TryHackMe-Kontext mit `-Q` aktiviert.

### ==Mode 4: PCAP Investigation==

Analyse von gespeicherten Captures ohne Live-Interface.

```bash
sudo snort -c /etc/snort/snort.conf -r datei.pcap -A full -l .
sudo snort --pcap-single=datei.pcap -c /etc/snort/snort.conf
sudo snort --pcap-list="datei1.pcap datei2.pcap" -c /etc/snort/snort.conf
```

---

## Wichtige Flags

### ==Grundlegende Parameter==

| Flag | Beschreibung | Anwendungsfall |
|------|-------------|----------------|
| `-v` | Verbose – zeigt Paket-Header auf der Konsole | Sniffer Mode, schnelle Inspektion |
| `-d` | Data – zeigt Payload zusätzlich zu den Headern | Paketinhalte prüfen |
| `-e` | Data-Link-Header – zeigt Layer-2-Informationen (MAC-Adressen) | Netzwerkebene analysieren |
| `-X` | Hex-Dump des gesamten Pakets ab Link Layer | Rohdatenanalyse |
| `-i <interface>` | Netzwerkinterface angeben | Live-Analyse: `-i eth0` |
| `-V` | Versionsnummer anzeigen und beenden | Build-Nummer prüfen |
| `-T` | Konfigurationsfile testen ohne Snort zu starten | Config validieren vor Einsatz |
| `-?` | Hilfe anzeigen | |

### ==Input / Output==

| Flag         | Beschreibung                                  | Anwendungsfall                                       |
| ------------ | --------------------------------------------- | ---------------------------------------------------- |
| `-c <file>`  | Konfigurationsfile angeben                    | Pflicht für IDS/IPS Mode: `-c /etc/snort/snort.conf` |
| `-r <file>`  | PCAP/Log-File einlesen (Playback Mode)        | Offline-Analyse: `-r snort.log.xxxxxxxx`             |
| `-l <dir>`   | Log-Verzeichnis angeben                       | Logs in aktuelles Verzeichnis: `-l .`                |
| `-b`         | Logs im binären tcpdump-Format speichern      | Performanter, Wireshark-kompatibel                   |
| `-K <mode>`  | Logging-Modus: `ascii`, `pcap`, `none`        | `-K none` deaktiviert Logging                        |
| `-n <zahl>`  | Maximale Paketanzahl angeben, dann stoppen    | Gezielter Blick: `-n 65`                             |
| `-L <datei>` | Binäres Log unter definiertem Namen speichern | Kontrolle über Dateinamen                            |

### ==Alert-Modi (`-A`)==

| Flag | Beschreibung | Anwendungsfall |
|------|-------------|----------------|
| `-A console` | Alerts auf der Konsole ausgeben (Echtzeit) | Debugging, Tests |
| `-A fast` | Kurzes Format: Timestamp, Alert-ID, IPs, Ports | Performant, Production-Logging |
| `-A full` | Vollständiges Format inkl. Paketdetails | Detailanalyse, forensische Auswertung |
| `-A cmg` | Kombiniertes Format: fast + hex/text Payload | CTFs, Paketinhalt direkt im Alert |
| `-A none` | Keine Alerts ausgeben (nur loggen) | Stilles Logging |

Typische Kombination für PCAP-Analyse im Room:

```bash
sudo snort -c local.rules -r datei.pcap -A full -l .
```

### ==Netzwerk-Parameter==

| Flag | Beschreibung | Anwendungsfall |
|------|-------------|----------------|
| `-h <netz>` | Home-Netzwerk definieren | `-h 192.168.1.0/24` – nur relevanten Traffic loggen |
| `-s` | Alerts an Syslog senden | Production-Deployment |
| `-D` | Daemon Mode (Hintergrundprozess) | Produktivbetrieb |
| `-Q` | Inline/IPS Mode (DAQ) | Aktives Blockieren |
| `-q` | Quiet Mode – kein Banner, keine Statistiken | Saubere Ausgabe |
| `-N` | Kein Packet Logging | Nur Alerts, kein Schreiben auf Disk |

---

## Regelstruktur

Eine Snort-Regel besteht aus **Header** und **Options**:

```
action protocol src_ip src_port direction dst_ip dst_port (options)
```

Beispiel:

```
alert tcp any any -> any 80 (msg:"HTTP Traffic"; sid:1000001; rev:1;)
```

### ==Header-Felder==

| Feld | Beschreibung | Beispiele |
|------|-------------|----------|
| Action | Was Snort mit dem Paket macht | `alert`, `log`, `drop`, `reject`, `pass` |
| Protocol | Protokoll | `tcp`, `udp`, `icmp`, `ip` |
| Src/Dst IP | Einzel-IP, CIDR, Negation, Variable | `any`, `192.168.1.0/24`, `!10.0.0.1`, `$HOME_NET` |
| Port | Einzel-Port, Bereich, Negation | `any`, `80`, `1:1024`, `!22` |
| Direction | Richtungsoperator | `->` (einseitig), `<>` (bidirektional) |

> [!warning] Kein `<-` Operator
> Snort unterstützt keinen `<-` Richtungsoperator. Stattdessen Quell- und Zielseite tauschen oder `<>` (bidirektional) verwenden.

### ==Rule-Options: General==

Metainformationen und Identifikation der Regel:

| Option | Beschreibung | Beispiel |
|--------|-------------|---------|
| `msg:"..."` | Beschreibungstext im Alert | `msg:"FTP Login Detected"` |
| `sid:` | Eindeutige Regel-ID. Eigene Regeln: ab 1.000.000 | `sid:1000001` |
| `rev:` | Revisionsnummer – muss nach jeder Regeländerung erhöht werden | `rev:1` |
| `reference:` | Verweist auf externe Quellen (CVE, URL etc.) | `reference:cve,2021-44228` |
| `classtype:` | Klassifizierung des Angriffs (definiert in classification.config) | `classtype:attempted-admin` |
| `priority:` | Priorität 1 (hoch) bis 10 (niedrig); überschreibt classtype-Default | `priority:1` |

### ==Rule-Options: Payload==

Durchsuchen des Paketinhalts:

| Option | Beschreibung | Beispiel |
|--------|-------------|---------|
| `content:"..."` | Sucht nach ASCII-String im Payload | `content:"GET"` |
| `content:"\|xx xx\|"` | Sucht nach Hex-Bytes im Payload | `content:"\|89 50 4E 47\|"` (PNG Magic Bytes) |
| `nocase` | Groß-/Kleinschreibung ignorieren (Modifier zu `content`) | `content:"get"; nocase;` |
| `offset:` | Startposition der Suche vom Beginn des Payloads (Bytes) | `content:"ABC"; offset:4;` |
| `depth:` | Maximale Suchtiefe vom Startpunkt aus (Bytes) | `content:"ABC"; depth:10;` |
| `distance:` | Startposition relativ zum Ende des vorherigen `content`-Treffers | `content:"ABC"; content:"DEF"; distance:0;` |
| `within:` | Maximale Distanz zum Ende des vorherigen `content`-Treffers | `content:"ABC"; content:"DEF"; within:20;` |
| `pcre:` | Perl Compatible Regular Expressions für flexible Mustererkennung | `pcre:"/union\s+select/i";` |

> [!tip] Merkhilfe: offset/depth vs. distance/within
> `offset` und `depth` beziehen sich auf den **Anfang des Payloads** (absolut). `distance` und `within` beziehen sich auf das **Ende des vorherigen `content`-Treffers** (relativ). Beide Paare können kombiniert werden, aber nicht untereinander gemischt.

### ==Rule-Options: Non-Payload==

Filterung auf Header-Ebene ohne Payload-Inspektion:

| Option | Beschreibung | Beispiel |
|--------|-------------|---------|
| `flags:` | TCP-Flags prüfen | `flags:S` (SYN), `flags:PA` (PSH+ACK), `flags:FIN` |
| `dsize:` | Paketgröße prüfen | `dsize:100<>200` (100–200 Bytes) |
| `id:` | IP-ID-Feld prüfen | `id:35369` |
| `flow:` | Verbindungsrichtung und -status | `flow:to_server,established` |
| `sameip` | Prüft, ob Quell-IP und Ziel-IP identisch sind. Kein Argument. Erkennt IP-Spoofing-Versuche. | `sameip;` |
| `ttl:` | IP Time-to-Live-Wert prüfen | `ttl:<3;` (Traceroute-Erkennung) |
| `threshold:` | Häufigkeitsbasierte Alerting-Schwelle | Rate-Limiting bei Brute Force |

Beispielregel mit `sameip`:
```
alert ip any any <> any any (msg:"Same Source and Destination IP"; sameip; sid:1000004; rev:1;)
```

> [!note] `sameip` und Protokoll-Einschränkung
> `sameip` mit Protokoll `ip` matcht alle Pakettypen. Soll nur TCP oder UDP gefiltert werden, muss für jedes Protokoll eine separate Regel geschrieben werden – Snort unterstützt kein Protokoll-OR in einem Header.

### ==TCP-Flag-Zeichen==

| Zeichen | Flag |
|---------|------|
| `S` | SYN |
| `A` | ACK |
| `P` | PSH |
| `F` | FIN |
| `R` | RST |
| `U` | URG |

Kombinierbar: `flags:PA` → PSH + ACK gleichzeitig gesetzt.

---

## BPF-Filter

BPF (Berkeley Packet Filter) ist eine Filtersprache, die von tcpdump stammt und von allen pcap-basierten Tools – darunter Wireshark, tcpdump und Snort – unterstützt wird. In Snort werden BPF-Filter als letztes Argument auf der Kommandozeile übergeben, ohne Flag, in einfachen Anführungszeichen. Sie arbeiten auf einer niedrigeren Ebene als Snort-Regeln: Pakete, die vom BPF-Filter ausgeschlossen werden, erreichen die Regelengine erst gar nicht.

BPF-Filter sind kein Ersatz für Snort-Regeln. Sie reduzieren das Rauschen oder grenzen den Analyse-Scope ein, bevor die Regelprüfung greift.

### ==Syntax-Grundlagen==

BPF-Ausdrücke bestehen aus **Primitiven** (einzelne Bedingung) und **Operatoren** (`and`, `or`, `not`). Klammern gruppieren Ausdrücke, müssen aber ggf. mit `\` escaped werden.

```bash
# Grundsyntax
sudo snort -r snort.log.xxxxxxxx 'AUSDRUCK'
sudo snort -c snort.conf -i eth0 'AUSDRUCK'
```

### ==Filter-Primitive==

| Primitiv | Beschreibung | Beispiel |
|----------|-------------|---------|
| `host <ip>` | Pakete mit dieser IP als Quelle oder Ziel | `host 192.168.1.10` |
| `src host <ip>` | Nur Pakete mit dieser Quell-IP | `src host 10.0.0.1` |
| `dst host <ip>` | Nur Pakete mit dieser Ziel-IP | `dst host 10.0.0.2` |
| `net <netz>` | Pakete innerhalb eines Netzes | `net 192.168.1.0/24` |
| `src net <netz>` | Pakete aus einem Quellnetz | `src net 10.0.0.0/8` |
| `port <port>` | Pakete mit diesem Port (Quelle oder Ziel) | `port 80` |
| `src port <port>` | Pakete von diesem Quellport | `src port 443` |
| `dst port <port>` | Pakete an diesen Zielport | `dst port 22` |
| `portrange <x>-<y>` | Pakete in einem Portbereich | `portrange 1024-65535` |
| `tcp` | Nur TCP-Traffic | `tcp` |
| `udp` | Nur UDP-Traffic | `udp` |
| `icmp` | Nur ICMP-Traffic | `icmp` |
| `ip` | Nur IP-Pakete (kein ARP etc.) | `ip` |

### ==Operatoren und Kombinationen==

```bash
# AND – beide Bedingungen müssen zutreffen
sudo snort -r snort.log.xxxxxxxx 'tcp and port 22'
sudo snort -r snort.log.xxxxxxxx 'host 10.10.10.5 and port 80'

# OR – mindestens eine Bedingung muss zutreffen
sudo snort -r snort.log.xxxxxxxx 'tcp or udp'
sudo snort -r snort.log.xxxxxxxx 'port 80 or port 443'

# NOT – Bedingung ausschließen
sudo snort -r snort.log.xxxxxxxx 'not icmp'
sudo snort -r snort.log.xxxxxxxx 'not host 192.168.1.1'

# Kombiniert mit Klammern
sudo snort -r snort.log.xxxxxxxx 'tcp and (port 80 or port 443)'
sudo snort -r snort.log.xxxxxxxx 'not (host 192.168.1.105 and udp and port 514)'
```

> [!warning] `tcp and icmp` ist ungültig
> Ein Paket kann nicht gleichzeitig TCP und ICMP sein — Snort gibt eine Fehlermeldung aus. `tcp or icmp` verwenden.

### ==Praxismuster==

```bash
# Nur SSH-Traffic aus dem Log lesen
sudo snort -r snort.log.xxxxxxxx 'tcp and port 22'

# Traffic eines bestimmten Angreifers isolieren
sudo snort -r snort.log.xxxxxxxx 'src host 10.10.245.36'

# Nur HTTP und HTTPS betrachten
sudo snort -r snort.log.xxxxxxxx 'tcp and (port 80 or port 443)'

# Bekannten internen Host beim Live-Sniffing ignorieren
sudo snort -c snort.conf -i eth0 'not host 192.168.1.1'

# BPF mit Snort-Regeln kombinieren
sudo snort -c local.rules -r datei.pcap -A full -l . 'tcp and port 21'
```

### ==BPF aus Datei laden (`-F`)==

```bash
sudo snort -c snort.conf -i eth0 -F /etc/snort/bpf.filter
```

### ==Unterschied BPF vs. Snort-Regeln==

| | BPF-Filter | Snort-Regeln |
|-|-----------|-------------|
| Ebene | Pre-Processing (pcap-Ebene) | Regelengine (nach Dekodierung) |
| Wirkung | Pakete werden gar nicht erst analysiert | Pakete werden analysiert und dann bewertet |
| Syntax | tcpdump-Syntax | Snort-eigene Regelsyntax |
| Anwendungsfall | Scope einschränken, Rauschen reduzieren | Konkrete Bedrohungserkennung |
| Kombination | Ja – beide können gleichzeitig verwendet werden | Ja |

---

## Wichtige Dateipfade

| Pfad | Inhalt |
|------|--------|
| `/etc/snort/snort.conf` | Hauptkonfiguration (4151 Regeln im THM-Raum) |
| `/etc/snort/rules/local.rules` | Lokale eigene Regeln |
| `/var/log/snort/` | Standard-Logverzeichnis |
| `/etc/snort/rules/` | Community- und Vendor-Regelsets |

---

## Praxismuster aus dem Raum

```bash
# Konfiguration testen
sudo snort -c /etc/snort/snort.conf -T

# Live-Traffic mit eigenen Regeln analysieren
sudo snort -c local.rules -i eth0 -A console -q

# PCAP gegen Regeln prüfen, Logs ins aktuelle Verzeichnis
sudo snort -c local.rules -r datei.pcap -A full -l .

# Log einlesen und bestimmte Pakete inspizieren
sudo snort -r snort.log.xxxxxxxx -n 10 -X

# BPF-Filter beim Einlesen anwenden
sudo snort -r snort.log.xxxxxxxx 'tcp and port 22'
```

> [!tip] Intermediate Logfiles
> Beim Arbeiten mit Zwischen-Logfiles: erst mit `-l .` ein Intermediate File erzeugen, dann mit `-r` darauf filtern. Direktes `-n 65` auf das PCAP liefert andere Ergebnisse, weil Snort erst liest, dann filtert.

---

## Snort-Architektur: Main Components

| Komponente | Funktion |
|-----------|---------|
| **Packet Decoder** | Erfasst und bereitet Pakete für die Vorverarbeitung auf |
| **Pre-processors** | Ordnet und modifiziert Pakete für die Detection Engine (z.B. Defragmentierung, Stream-Reassembly) |
| **Detection Engine** | Kernkomponente: analysiert und bewertet Pakete anhand der geladenen Regeln |
| **Logging and Alerting** | Generiert Log-Einträge und Alerts bei Regeltreffern |
| **Outputs and Plugins** | Integration mit externen Systemen (Syslog, MySQL) und zusätzliche Erkennungs-Plugins |

---

## Rule-Typen

| Typ | Kosten | Registrierung | Besonderheit |
|-----|--------|--------------|-------------|
| **Community Rules** | Kostenlos | Nicht erforderlich | GPLv2, öffentlich zugänglich |
| **Registered Rules** | Kostenlos | Registrierung erforderlich | Subscriber-Regeln mit 30 Tagen Verzögerung |
| **Subscriber Rules** | Kostenpflichtig (Abo) | Abo erforderlich | Hauptregelset, Updates 2x wöchentlich (Di + Do) |

---

## snort.conf – Wichtige Konfigurationsabschnitte

### ==Step 1: Netzwerkvariablen==

| Variable | Bedeutung | Beispiel |
|----------|----------|---------|
| `HOME_NET` | Das zu schützende Netzwerk | `'192.168.1.0/24'` oder `'any'` |
| `EXTERNAL_NET` | Externes Netz – typisch `!$HOME_NET` oder `any` | `'!$HOME_NET'` |
| `RULE_PATH` | Pfad zu den Regeldateien | `/etc/snort/rules` |
| `SO_RULE_PATH` | Pfad für Registered/Subscriber SO-Regeln | `$RULE_PATH/so_rules` |
| `PREPROC_RULE_PATH` | Pfad für Preprocessor-Regeln | `$RULE_PATH/plugin_rules` |

### ==Step 2: Decoder / DAQ-Modus==

| Einstellung | Bedeutung | Beispiel |
|------------|----------|---------|
| `#config daq` | DAQ-Modul auswählen | `afpacket` |
| `#config daq_mode` | Inline-Modus aktivieren | `inline` |
| `#config logdir` | Standard-Log-Pfad | `/var/logs/snort` |

**Verfügbare DAQ-Module:**

| Modul | Modus | Einsatz |
|-------|-------|---------|
| `pcap` | Default (Sniffer) | Passive Analyse |
| `afpacket` | Inline (IPS) | Aktives Blockieren auf Linux |
| `ipq` | Inline via Netfilter | Linux, ersetzt snort_inline |
| `nfq` | Inline | Linux |
| `ipfw` | Inline | OpenBSD/FreeBSD |
| `dump` | Test | Inline- und Normalisierungs-Tests |

### ==Step 7: Regelsets einbinden==

| Tag | Bedeutung | Beispiel |
|----|----------|---------|
| `include $RULE_PATH/local.rules` | Lokale eigene Regeln (immer aktiv) | Standardpfad für selbst geschriebene Regeln |
| `#include $RULE_PATH/rulename` | Heruntergeladene Regelsets (auskommentiert = deaktiviert) | `#` entfernen zum Aktivieren |

> [!note] `#` ist der Kommentaroperator
> Eine Zeile mit `#` ist deaktiviert. Zum Aktivieren das `#` entfernen. Bestehende Konfigurationsdateien nie ersetzen – immer manuell editieren.

---

## IDS vs. IPS

| Modus | Funktion | Snort-Entsprechung |
|-------|---------|-------------------|
| NIDS | Erkennt Bedrohungen im Netzwerk (passiv) | Standard IDS Mode |
| HIDS | Erkennt Bedrohungen auf einem Host (passiv) | Host-basierter Einsatz |
| NIPS | Blockiert Bedrohungen im Netzwerk (aktiv) | Inline Mode mit `-Q` |
| HIPS | Blockiert Bedrohungen auf einem Host (aktiv) | Host-basierter Inline |

---

## Bezug zu anderen Themen

- [[2026-02-19-hfb1stolenmount]] – Netzwerkforensik mit Wireshark auf PCAP-Dateien, analoges Arbeiten mit gespeichertem Traffic
- [[2026-02-23-infinity-shell]] – Log-Analyse als Kerntechnik; Snort ergänzt als automatisierte Erkennungsschicht, was dort manuell mit `grep` gemacht wurde
- [[2026-02-27-mrphisher]] – Malware-Analyse; Snort-Regeln wären ein typisches Mittel, um Command-and-Control-Traffic oder Payload-Signaturen zu detektieren
- [[CIA-Triad]] – Snort adressiert primär **Availability** (Angriffe stoppen) und **Confidentiality** (Erkennen von Datenlecks)

---

## Referenzen

- [TryHackMe – Snort Room](https://tryhackme.com/room/snort)
- [Snort Official Documentation](https://docs.snort.org)
- [Snort 2.9 Manual (PDF)](https://snort-org-site.s3.amazonaws.com/production/document_files/files/000/000/249/original/snort_manual.pdf)
- [Snort Man Page](https://www.manpagez.com/man/8/snort/)
