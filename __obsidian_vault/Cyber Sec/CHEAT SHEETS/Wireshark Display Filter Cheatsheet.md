---
tags: [wireshark, networking, tools, troubleshooting, cli-tools, reference, soc]
---

> Referenz für Display Filter in [[Wireshark]] — optimiert für [[SOC Analyst L1]] Analyse, Incident Response und CTF-Szenarien.

## Grundlegende Syntax

| Operator | Bedeutung | Beispiel |
|----------|-----------|----------|
| `==` | gleich | `ip.addr == 10.0.0.1` |
| `!=` | ungleich | `tcp.port != 80` |
| `>` / `<` / `>=` / `<=` | Vergleich | `frame.len > 1000` |
| `contains` | enthält String | `http contains "password"` |
| `matches` | Regex | `http.request.uri matches "admin\|login"` |
| `in` | Werteliste | `tcp.port in {80, 443, 8080}` |
| `&&` / `and` | UND | `ip.src == 10.0.0.1 && tcp.port == 443` |
| `\|\|` / `or` | ODER | `dns \|\| dhcp` |
| `!` / `not` | NICHT | `!arp` |

---

## TCP

> Transmission Control Protocol — Basis der meisten Anwendungsprotokolle. Für SOC-Analysten zentral um Verbindungsaufbau, Anomalien und Angriffsmuster zu erkennen. Siehe auch [[TCP]].

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `tcp` | Gesamter TCP-Traffic | Basis-Überblick, Anteil am Gesamttraffic einschätzen |
| `tcp.port == 443` | Traffic auf Port 443 (HTTPS) | Identifikation verschlüsselter Verbindungen, unerwartete Dienste auf Standard-Ports |
| `tcp.port == 80` | Traffic auf Port 80 (HTTP) | Klartextverkehr — Credentials, Daten-Leaks, C2 über HTTP |
| `tcp.flags.syn == 1 && tcp.flags.ack == 0` | SYN-Pakete (Verbindungsanfragen) | Erkennung von Port-Scans (viele SYNs an verschiedene Ports = [[Nmap]] SYN-Scan) |
| `tcp.flags.rst == 1` | RST-Pakete (Verbindungsabbrüche) | Massenhaft RSTs deuten auf Scan-Antworten oder Firewall-Blocks hin |
| `tcp.flags.fin == 1` | FIN-Pakete (Verbindungsende) | Ungewöhnliche FIN-Patterns können auf FIN-Scans hinweisen |
| `tcp.analysis.retransmission` | Erneut gesendete Pakete | Netzwerkprobleme, Paketverlust, kann auch auf DDoS oder Überlastung hinweisen |
| `tcp.analysis.duplicate_ack` | Doppelte ACKs | Indikator für Paketverlust auf dem Übertragungsweg |
| `tcp.analysis.zero_window` | Zero Window Condition | Empfänger kann keine Daten mehr aufnehmen — Slowloris-Angriff oder Überlastung |
| `tcp.analysis.flags` | Alle TCP-Analyse-Flags | Schneller Überblick über alle erkannten Anomalien |
| `tcp.stream eq 0` | Einzelnen TCP-Stream verfolgen | Isoliert eine vollständige Konversation — essentiell für Follow-Stream-Analyse |
| `tcp.len > 0` | Nur Pakete mit Payload | Filtert Handshake/ACKs raus, zeigt nur Datentransfer |
| `tcp.port == 4444` | Gängiger Reverse-Shell-Port | Metasploit Default, Netcat-Shells — sofort verdächtig |
| `tcp.port in {4444, 5555, 1234, 9001}` | Typische Reverse-Shell-Ports | Bekannte Default-Ports für Reverse Shells in CTFs und realen Angriffen |

---

## UDP

> User Datagram Protocol — verbindungslos, kein Handshake. Wird für DNS, DHCP, VoIP genutzt. Schwerer zu analysieren weil kein Connection State existiert. Siehe auch [[UDP]].

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `udp` | Gesamter UDP-Traffic | Basis-Überblick |
| `udp.port == 53` | DNS-Traffic | Siehe DNS-Sektion — häufig für Tunneling missbraucht |
| `udp.port == 67 \|\| udp.port == 68` | DHCP-Traffic | DHCP-Spoofing-Erkennung, Rogue DHCP Servers |
| `udp.port == 161 \|\| udp.port == 162` | SNMP-Traffic (Get/Trap) | SNMP-Enumeration erkennen, oft mit Default-Community-Strings `public`/`private` |
| `udp.port == 514` | Syslog | Log-Exfiltration oder Log-Manipulation |
| `udp.port == 69` | TFTP-Traffic | Trivial FTP hat keine Authentifizierung — Firmware-Theft, Config-Download |
| `udp.port == 123` | NTP-Traffic | NTP-Amplification-DDoS, NTP-Poisoning für Kerberos-Angriffe |
| `udp.port == 1900` | SSDP/UPnP | UPnP-Enumeration, SSDP-Amplification-Angriffe |
| `udp.length > 512` | Ungewöhnlich große UDP-Pakete | Mögliche Exfiltration oder DNS-Amplification |
| `udp.length == 0` | Leere UDP-Pakete | Port-Scanning (UDP-Scan sendet leere Pakete) |
| `udp.srcport > 49152` | Ephemeral Source Ports | Normaler Client-Traffic — Abweichungen deuten auf Spoofing hin |

---

## IP / IPv4 / IPv6

> Netzwerkschicht — Quell- und Zieladressen identifizieren. Grundlage jeder Traffic-Analyse. Siehe auch [[IP Address]], [[IPv6 Addressing and Subnetting]], [[CIDR]], [[NAT]].

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `ip.addr == 10.0.0.1` | Traffic von/zu einer IP | Host-spezifische Analyse, Verdächtigen Host isolieren |
| `ip.src == 10.0.0.1` | Nur Traffic von einer IP | Ausgehenden Traffic eines kompromittierten Hosts analysieren |
| `ip.dst == 10.0.0.1` | Nur Traffic zu einer IP | Eingehende Angriffe auf einen Host identifizieren |
| `ip.addr == 10.0.0.0/24` | Ganzes Subnetz filtern | Lateral Movement innerhalb eines Netzwerksegments erkennen |
| `!(ip.addr == 10.0.0.0/8)` | Externer Traffic (nicht RFC1918) | Kommunikation nach außen isolieren — C2, Exfiltration |
| `ip.src == ip.dst` | Quell-IP gleich Ziel-IP | **Land Attack** — Spoofed-Pakete an sich selbst, DoS-Technik |
| `ip.ttl < 10` | Niedriger TTL-Wert | Traceroute-Erkennung, manche Evasion-Techniken setzen niedrige [[TTL]] |
| `ip.ttl == 1` | TTL genau 1 | Traceroute erster Hop, oder Evasion-Versuch (Paket stirbt vor IDS) |
| `ip.flags.mf == 1` | Fragmentierte Pakete | IP-Fragmentation-Angriffe, IDS-Evasion |
| `ip.dsfield.dscp != 0` | Ungewöhnliches DSCP-Feld | Covert Channel über IP-Header-Felder, Traffic-Klassifizierung manipuliert |
| `ipv6` | Gesamter IPv6-Traffic | IPv6-Tunnel als Bypass, oft in Netzwerken nicht überwacht |
| `ip.checksum_bad.expert` | Fehlerhafte IP-Checksumme | Manipulierte Pakete, Crafted Packets von Angriffs-Tools |

---

## ICMP

> Internet Control Message Protocol — Diagnostik (Ping, Traceroute). Wird häufig für verdeckte Kommunikation missbraucht. Siehe auch [[ICMP]], [[Ping - ICMP]], [[Traceroute]].

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `icmp` | Gesamter ICMP-Traffic | Basis-Überblick, Ping-Sweeps erkennen |
| `icmp.type == 8` | Echo Request (Ping) | Massenhaft = Host Discovery / Ping Sweep |
| `icmp.type == 0` | Echo Reply | Antworten auf Ping — welche Hosts sind aktiv? |
| `icmp.type == 3` | Destination Unreachable | Port-Scan-Antworten (Type 3, Code 3 = Port geschlossen) |
| `icmp.type == 3 && icmp.code == 3` | Port Unreachable | Direkte Antwort auf UDP-Scan — geschlossener Port bestätigt |
| `icmp.type == 3 && icmp.code == 13` | Communication Administratively Filtered | Firewall hat den Zugriff blockiert — Firewall-Mapping durch Angreifer |
| `icmp.type == 11` | Time Exceeded | Traceroute-Pakete erkennen |
| `icmp.type == 5` | Redirect | **ICMP Redirect Attack** — Angreifer manipuliert Routing-Tabelle des Opfers |
| `icmp && data.len > 48` | ICMP mit ungewöhnlich großem Payload | **ICMP Tunneling** — Datenexfiltration über Ping-Pakete (Tools: ptunnel, icmptunnel) |
| `icmp && frame.len > 1000` | Übergroße ICMP-Pakete | **Ping of Death** Varianten, oder Exfiltration großer Datenmengen |
| `icmp && !(icmp.type == 8 \|\| icmp.type == 0)` | ICMP ohne Ping | Ungewöhnliche ICMP-Typen können auf Evasion hindeuten |
| `icmp.ident` | ICMP Identifier-Feld | Konstante Identifier über viele Pakete = Tunneling-Tool-Signatur |

---

## DNS

> Domain Name System — Namensauflösung. Einer der meistmissbrauchten Kanäle für Tunneling und Exfiltration. Siehe auch [[DNS]], [[DNS Resolution Tools]], [[DNS Record Types]], [[Public DNS Servers]], [[DNS Registration and Expiration]].

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `dns` | Gesamter DNS-Traffic | Basis-Überblick |
| `dns.flags.response == 0` | Nur DNS-Queries | Welche Domains werden angefragt? |
| `dns.flags.response == 1` | Nur DNS-Responses | Welche Antworten kommen zurück? |
| `dns.qry.name contains "evil"` | Queries mit bestimmtem String | Bekannte C2-Domains, DGA-Patterns suchen |
| `dns.qry.type == 1` | A-Records | Standard IPv4-Auflösung |
| `dns.qry.type == 28` | AAAA-Records | IPv6-Auflösung — manchmal für Tunneling genutzt |
| `dns.qry.type == 16` | TXT-Records | **Häufig für DNS Tunneling** — dnscat2, iodine nutzen TXT-Records für Datenübertragung |
| `dns.qry.type == 15` | MX-Records | Mail-Server-Enumeration |
| `dns.qry.name.len > 50` | Lange DNS-Queries | **DNS Tunneling Indikator** — kodierte Daten im Subdomain-Feld |
| `dns.flags.rcode != 0` | DNS-Fehler (NXDOMAIN etc.) | Massenhaft NXDOMAIN = DGA (Domain Generation Algorithm) eines Botnets |
| `dns && !(dns.qry.name contains ".local")` | DNS ohne lokale Queries | mDNS-Rauschen filtern |
| `dns.resp.len > 512` | Große DNS-Antworten | DNS-Amplification-Angriff oder Tunneling |

---

## HTTP

> HyperText Transfer Protocol — Klartextprotokoll. Alle Daten sind lesbar — Credentials, Uploads, C2-Kommunikation. Siehe auch [[Testing Port Connectivity]].

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `http` | Gesamter HTTP-Traffic | Basis-Überblick |
| `http.request` | Nur HTTP-Requests | Welche Ressourcen werden angefragt? |
| `http.response` | Nur HTTP-Responses | Statuscodes, Server-Header analysieren |
| `http.request.method == "POST"` | POST-Requests | Login-Versuche, Datenuploads, Formular-Submissions |
| `http.request.method == "GET"` | GET-Requests | URL-Parameter können sensible Daten enthalten |
| `http.request.uri contains "admin"` | Admin-Pfade | Directory-Brute-Force erkennen (Gobuster, DirBuster) |
| `http.request.uri contains "wp-"` | WordPress-Pfade | WordPress-spezifische Enumeration und Angriffe |
| `http contains "password"` | Klartext-Passwörter | Credentials in HTTP-Formularen oder URLs |
| `http contains "SELECT" \|\| http contains "UNION"` | SQL-Injection-Patterns | SQLi-Versuche in GET/POST-Parametern |
| `http contains "<script>"` | XSS-Patterns | Cross-Site-Scripting-Versuche |
| `http.response.code == 200` | Erfolgreiche Requests | In Kombination mit Brute-Force-Filtern: welche Versuche waren erfolgreich? |
| `http.response.code == 401` | Unauthorized | Fehlgeschlagene Authentifizierungsversuche |
| `http.response.code == 403` | Forbidden | Zugriffsverweigerungen, WAF-Blocks |
| `http.response.code >= 400` | Alle Fehler | Überblick über fehlgeschlagene Anfragen |
| `http.user_agent contains "curl"` | Curl User-Agent | Automatisierte Tools, Skripte, C2-Beacons |
| `http.user_agent contains "python"` | Python User-Agent | Skript-basierte Angriffe, Exploit-Tools |
| `http.content_type contains "octet-stream"` | Binärdaten | Datei-Downloads, Malware-Delivery |
| `http.host` | Requests mit Host-Header | Welche Domains werden per HTTP kontaktiert? |

---

## TLS / HTTPS

> Transport Layer Security — verschlüsselt den gesamten Inhalt. Analyse beschränkt sich auf Handshake-Metadaten, es sei denn ein Pre-Master-Secret/Key ist verfügbar.

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `tls` | Gesamter TLS-Traffic | Basis-Überblick verschlüsselter Verbindungen |
| `tls.handshake` | Nur TLS-Handshakes | Verbindungsaufbau analysieren ohne Payload |
| `tls.handshake.type == 1` | Client Hello | Welche Hosts initiieren TLS-Verbindungen, SNI-Feld zeigt Zieldomain |
| `tls.handshake.type == 2` | Server Hello | Welche Cipher-Suite wurde gewählt? Schwache Cipher? |
| `tls.handshake.extensions.server_name` | SNI (Server Name Indication) | Zieldomain im Klartext — auch bei HTTPS sichtbar |
| `tls.handshake.extensions.server_name contains "evil"` | SNI mit bestimmter Domain | C2-Domains über HTTPS identifizieren |
| `tls.handshake.ciphersuite == 0x002f` | Bestimmte Cipher Suite | Schwache Verschlüsselung erkennen |
| `tls.record.version == 0x0301` | TLS 1.0 | Veraltete TLS-Version — Sicherheitsrisiko |
| `tls.alert_message` | TLS-Alerts | Handshake-Fehler, Certificate-Probleme |
| `x509af.issuer.rdnSequence` | Zertifikats-Aussteller | Self-signed Certs = verdächtig, Malware nutzt oft generierte Certs |

---

## DHCP

> Dynamic Host Configuration Protocol — automatische IP-Vergabe. Angriffe zielen auf IP-Übernahme und Traffic-Umleitung. Siehe auch [[DHCP]].

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `dhcp` | Gesamter DHCP-Traffic | Basis-Überblick |
| `dhcp.type == 1` | DHCP Discover | Neue Clients im Netzwerk identifizieren |
| `dhcp.type == 2` | DHCP Offer | Welche Server antworten? Rogue DHCP Server erkennen |
| `dhcp.type == 3` | DHCP Request | Client akzeptiert ein Offer — welches wurde gewählt? |
| `dhcp.type == 5` | DHCP ACK | Zugewiesene IPs und Konfiguration |
| `dhcp.type == 6` | DHCP NAK | Server lehnt ab — IP-Konflikt oder Konfigurationsproblem |
| `dhcp.type == 7` | DHCP Release | Client gibt IP frei — ungewöhnlich viele Releases = Starvation-Angriff |
| `dhcp.option.dhcp_server_id` | DHCP Server ID | Mehrere Server-IDs = Rogue DHCP Server |
| `dhcp.hw.mac_addr` | Client [[MAC Address]] | Unbekannte MAC-Adressen im Netzwerk identifizieren |
| `dhcp.option.hostname` | Client-Hostname | Geräteidentifikation, unerwartete Hostnamen = Rogue Device |
| `dhcp.option.domain_name_server` | Zugewiesener DNS-Server | Rogue DHCP kann eigenen DNS-Server pushen → DNS-Hijacking |
| `dhcp.option.router` | Zugewiesenes Default Gateway | Rogue DHCP kann Gateway umleiten → MitM |

---

## ARP

> Address Resolution Protocol — Zuordnung IP → [[MAC Address]]. Häufiger Angriffsvektor für MitM (Man-in-the-Middle) im lokalen Netz.

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `arp` | Gesamter ARP-Traffic | Basis-Überblick |
| `arp.opcode == 1` | ARP Requests | Wer fragt nach welcher IP? |
| `arp.opcode == 2` | ARP Replies | Wer antwortet — und stimmt die MAC-Zuordnung? |
| `arp.duplicate-address-detected` | Doppelte IP-Adressen | **ARP Spoofing/Poisoning** — eine MAC behauptet mehrere IPs zu haben |
| `arp.isgratuitous` | Gratuitous ARP | Unaufgeforderte ARP-Replies — Legitim bei IP-Änderung, verdächtig wenn massenhaft |
| `arp.src.proto_ipv4 == 0.0.0.0` | ARP Probe (Sender IP 0.0.0.0) | IP-Konfliktprüfung, oder ARP-Scan-Tool (z.B. arp-scan, netdiscover) |
| `arp.dst.hw_mac == ff:ff:ff:ff:ff:ff` | Broadcast ARP | Normal für Requests, bei Replies = Gratuitous/Spoofing |
| `arp.src.hw_mac != arp.dst.hw_mac` | Asymmetrische ARP | Anomale ARP-Pakete, möglicher Spoofing-Indikator |
| `arp && arp.opcode == 2 && ip.src == GATEWAY_IP` | ARP Reply für Gateway-IP | Mehrere MACs für Gateway-IP = **aktiver ARP Spoofing Angriff** |
| `arp.src.hw_mac contains 08:00:27` | ARP von VirtualBox-MAC (OUI) | VM im Netzwerk erkennen — kann auf Rogue Device hindeuten |

---

## FTP

> File Transfer Protocol — Klartext-Authentifizierung und Dateitransfer. Credentials und Dateien vollständig sichtbar.

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `ftp` | Gesamter FTP-Control-Traffic | Befehle und Antworten |
| `ftp-data` | FTP-Datentransfer | Übertragene Dateien — komplett im Klartext |
| `ftp.request.command == "USER"` | FTP-Benutzername | Credentials in Klartext extrahieren |
| `ftp.request.command == "PASS"` | FTP-Passwort | Credentials in Klartext extrahieren |
| `ftp.request.command == "RETR"` | Datei-Download | Welche Dateien werden heruntergeladen? Exfiltration |
| `ftp.request.command == "STOR"` | Datei-Upload | Malware-Upload, Webshell-Platzierung |
| `ftp.request.command == "LIST"` | Verzeichnislisting | Enumeration — Angreifer erkundet Dateistruktur |
| `ftp.request.command == "CWD"` | Verzeichniswechsel | Directory Traversal, Zielpfad des Angreifers verfolgen |
| `ftp.response.code == 230` | Login erfolgreich | Welche Credentials haben funktioniert? |
| `ftp.response.code == 530` | Login fehlgeschlagen | Brute-Force-Versuche erkennen |
| `ftp.response.code == 227` | Passive Mode Entering | Passive-FTP-Datenverbindung — Port für `ftp-data` identifizieren |

---

## SSH

> Secure Shell — verschlüsseltes Remote-Login. Payload ist verschlüsselt, aber Handshake und Metadaten sind analysierbar.

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `ssh` | Gesamter SSH-Traffic | Basis-Überblick |
| `tcp.port == 22` | SSH-Standardport | SSH auf nicht-Standard-Ports → `tcp.port == 2222` etc. |
| `ssh.protocol` | SSH-Versionstring | Veraltete SSH-Versionen erkennen (SSHv1 = kritisch) |
| `ssh.kex.algorithms` | Key-Exchange-Algorithmen | Schwache Krypto erkennen (diffie-hellman-group1-sha1 = unsicher) |
| `ssh.host_key.type` | Host-Key-Typ | DSA/RSA-1024 = veraltet, ed25519 = aktuell |
| `ssh.encrypted_packet` | Verschlüsselte SSH-Pakete | Payload-Analyse — Paketgrößen-Patterns können Aktivität verraten |
| `ssh && tcp.analysis.retransmission` | SSH mit Retransmissions | Instabile Verbindung oder Tunneling-Aktivität |
| `ssh && tcp.flags.syn == 1` | SSH-Verbindungsaufbauten | Viele SYNs auf Port 22 = Brute-Force-Angriff |
| `tcp.port == 22 && tcp.flags.rst == 1` | SSH-Verbindungsabweisungen | Fail2ban-Blocks, fehlgeschlagene Authentifizierung |
| `ssh && frame contains "SSH-2.0-"` | SSH-Banner | Tool-Identifikation — Paramiko, libssh, PuTTY haben eigene Banner |
| `tcp.port == 22 && tcp.window_size == 0` | SSH Zero-Window | Session hängt — kann auf SSH-Tunneling-Überlastung hindeuten |

---

## SMB

> Server Message Block — Windows-Filesharing. Häufiger Angriffsvektor für Lateral Movement und Ransomware-Verbreitung.

| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `smb \|\| smb2` | Gesamter SMB-Traffic | Basis-Überblick |
| `smb2.cmd == 5` | Tree Connect (Share-Zugriff) | Welche Shares werden angesprochen? Lateral Movement |
| `smb2.cmd == 3` | Session Setup | Authentifizierungsversuche |
| `smb2.cmd == 8` | Read Request | Datei-Lesezugriffe — Daten-Exfiltration über Shares |
| `smb2.cmd == 9` | Write Request | Datei-Schreibzugriffe — Malware-Drop, Ransomware-Verschlüsselung |
| `smb2.filename` | Dateizugriffe | Welche Dateien werden gelesen/geschrieben? |
| `smb2.filename contains ".exe"` | EXE-Transfers über SMB | Malware-Verbreitung im Netzwerk |
| `smb2.filename contains ".ps1"` | PowerShell-Skripte über SMB | Fileless Malware, Post-Exploitation-Skripte |
| `smb2.filename contains ".dll"` | DLL-Transfers über SMB | DLL-Sideloading, DLL-Hijacking |
| `smb2.nt_status != 0x00000000` | SMB-Fehler | Fehlgeschlagene Zugriffe, Permission-Denied |
| `smb2.nt_status == 0xc000006d` | Logon Failure | Brute-Force gegen SMB-Shares erkennen |
| `smb2.share_type == 1` | Disk Share Access | Zugriff auf Dateifreigaben — normaler und anormaler Zugriff unterscheiden |
| `ntlmssp.auth.username` | NTLM-Authentifizierungs-User | Welche Accounts nutzen NTLM? Credential-Relay-Angriffe |

---

## Weitere Protokolle

### Telnet
| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `telnet` | Gesamter Telnet-Traffic | Klartext-Login — sollte nie in produktiven Netzwerken vorkommen |
| `telnet && data.len > 0` | Telnet mit Payload | Befehle und Ausgaben im Klartext |
| `tcp.port == 23` | Telnet-Standardport | Auch auf Nicht-Standard-Ports prüfen (z.B. IoT-Geräte) |
| `telnet contains "login"` | Login-Prompt | Authentifizierungsvorgang identifizieren |
| `telnet contains "Password"` | Passwort-Prompt | Klartext-Credentials direkt sichtbar |
| `telnet contains "incorrect"` | Fehlgeschlagene Logins | Brute-Force auf Telnet — bei IoT/Botnet-Angriffen häufig (Mirai) |
| `telnet contains "#" \|\| telnet contains "$"` | Shell-Prompt | Erfolgreicher Login — Angreifer hat Shell-Zugriff |
| `telnet contains "root"` | Root-Zugriff | Privilegierter Zugriff über Klartext — kritisch |
| `telnet contains "wget" \|\| telnet contains "curl"` | Download-Befehle | Malware-Download nach erfolgreichem Telnet-Login |
| `telnet contains "busybox"` | BusyBox-Befehle | IoT-Botnet-Aktivität — Mirai und Varianten nutzen BusyBox |

### SMTP
| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `smtp` | Gesamter SMTP-Traffic | E-Mail-Verkehr analysieren |
| `smtp.req.command == "AUTH"` | SMTP-Authentifizierung | Mail-Credentials im Klartext |
| `smtp.req.command == "MAIL"` | Absender-Adresse (MAIL FROM) | Spoofed Absender erkennen |
| `smtp.req.command == "RCPT"` | Empfänger-Adresse (RCPT TO) | Ziele von Phishing-Kampagnen identifizieren |
| `smtp.req.command == "DATA"` | E-Mail-Inhalt folgt | Payload-Start — danach kommt der eigentliche Mail-Body |
| `smtp contains "Subject:"` | E-Mail-Subjects | Phishing-Kampagnen erkennen, Social Engineering |
| `smtp contains ".exe" \|\| smtp contains ".zip"` | Verdächtige Anhänge | Malware-Verbreitung per E-Mail |
| `smtp contains "Content-Transfer-Encoding: base64"` | Base64-kodierte Anhänge | Encoded Payloads — kann Malware sein |
| `smtp.response.code == 550` | Recipient Rejected | E-Mail-Enumeration (Harvesting gültiger Adressen) |
| `smtp.response.code == 235` | Auth Successful | Erfolgreiche SMTP-Authentifizierung — kompromittierter Account? |

### Kerberos
| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `kerberos` | Gesamter Kerberos-Traffic | Windows AD-Authentifizierung |
| `kerberos.msg_type == 10` | AS-REQ (Authentication Service Request) | Initiale Anmeldeversuche — massenhaft = Password Spraying |
| `kerberos.msg_type == 11` | AS-REP | Erfolgreiche Vorauthentifizierung — AS-REP Roasting wenn Pre-Auth deaktiviert |
| `kerberos.msg_type == 12` | TGS-REQ (Ticket Granting Service) | Service-Ticket-Anfragen — massenhaft = **Kerberoasting** |
| `kerberos.msg_type == 13` | TGS-REP | Service-Ticket-Antworten — enthält verschlüsseltes Ticket für Offline-Crack |
| `kerberos.error_code` | Kerberos-Fehler | Brute-Force-Erkennung, Account-Lockouts |
| `kerberos.error_code == 6` | Client not found | Ungültiger Username — Enumeration-Versuch |
| `kerberos.error_code == 24` | Pre-auth failed | Falsches Passwort — Brute-Force/Password-Spraying |
| `kerberos.CNameString` | Authentifizierende User | Welche Accounts werden genutzt? Unübliche Service-Accounts? |
| `kerberos.SNameString contains "krbtgt"` | TGT-Anfragen | Golden Ticket Angriff nutzt krbtgt-Hash |
| `kerberos.cipher == 23` | RC4-HMAC Encryption | **Kerberoasting-Indikator** — RC4 wird bevorzugt weil leichter zu knacken |

### LDAP
| Filter | Erklärung | SOC-Relevanz |
|--------|-----------|--------------|
| `ldap` | Gesamter LDAP-Traffic | Active Directory Enumeration |
| `ldap.protocolOp == 0` | Bind Request (Authentifizierung) | LDAP-Login-Versuche — Klartext wenn nicht LDAPS |
| `ldap.protocolOp == 1` | Bind Response | Erfolg/Misserfolg der Authentifizierung |
| `ldap.protocolOp == 3` | Search Request | AD-Abfragen — Enumeration von Usern, Gruppen, Computern |
| `ldap.filter` | LDAP-Suchanfragen | Welche AD-Objekte werden abgefragt (User, Groups, SPNs)? |
| `ldap.filter contains "objectClass=user"` | User-Enumeration | Angreifer sammelt AD-User-Liste |
| `ldap.filter contains "objectClass=computer"` | Computer-Enumeration | Angreifer mapped Netzwerk-Hosts über AD |
| `ldap.filter contains "servicePrincipalName"` | SPN-Enumeration | **Kerberoasting-Vorbereitung** — Angreifer sucht Service-Accounts |
| `ldap.filter contains "adminCount=1"` | Admin-Account-Suche | Angreifer identifiziert privilegierte Accounts |
| `ldap.baseObject contains "CN=Schema"` | Schema-Abfrage | AD-Schema-Enumeration — tiefe Reconnaissance |

---

## Bonus: Kombinierte Filter für SOC-Szenarien

### Reconnaissance erkennen
```
# Nmap SYN-Scan: Viele SYNs von einer Quelle an verschiedene Ports
tcp.flags.syn == 1 && tcp.flags.ack == 0 && ip.src == ATTACKER_IP

# Ping Sweep: ICMP Echo Requests an aufeinanderfolgende IPs
icmp.type == 8 && ip.src == ATTACKER_IP

# DNS Enumeration: Viele DNS-Queries von einer Quelle
dns.flags.response == 0 && ip.src == ATTACKER_IP
```

### Credential Theft
```
# Klartext-Credentials über FTP, HTTP, Telnet
ftp.request.command == "PASS" || http contains "password" || telnet

# NTLM-Hashes über SMB
ntlmssp.auth.username
```

### Exfiltration erkennen
```
# DNS Tunneling: Ungewöhnlich lange DNS-Queries + TXT-Records
dns.qry.name.len > 50 || dns.qry.type == 16

# ICMP Tunneling: Große ICMP-Pakete
icmp && data.len > 48

# Große ausgehende Transfers
tcp.len > 5000 && ip.src == INTERNAL_IP && !(ip.dst == 10.0.0.0/8)
```

### C2-Kommunikation
```
# HTTP-Beacons: Regelmäßige Requests mit ungewöhnlichem User-Agent
http.user_agent contains "python" || http.user_agent contains "curl"

# DNS-basiertes C2: Häufige Queries an ungewöhnliche Domains
dns.qry.type == 16 && dns.flags.response == 0

# Verdächtige Ports
tcp.port in {4444, 5555, 1234, 9001, 8888}
```

### Lateral Movement
```
# SMB-Zugriffe zwischen Workstations (unüblich)
smb2 && ip.src == WORKSTATION_IP && ip.dst == OTHER_WORKSTATION_IP

# Remote Execution via SMB
smb2.filename contains ".exe" || smb2.filename contains ".ps1"

# RDP von ungewöhnlichen Quellen
tcp.port == 3389 && ip.src != ADMIN_SUBNET
```

### ARP Spoofing / MitM
```
# Doppelte IP-Zuweisungen
arp.duplicate-address-detected

# Gratuitous ARP (unaufgeforderte ARP-Replies)
arp.opcode == 2 && arp.src.proto_ipv4 == GATEWAY_IP
```

---

## Nützliche Allgemeine Filter

| Filter | Erklärung |
|--------|-----------|
| `frame.time >= "2026-02-20 10:00:00"` | Zeitfenster filtern |
| `frame.len > 1500` | Überdurchschnittlich große Frames |
| `eth.addr == aa:bb:cc:dd:ee:ff` | Spezifische [[MAC Address]] |
| `!(arp \|\| dns \|\| dhcp)` | Hintergrund-Rauschen entfernen |
| `tcp.port == 80 \|\| tcp.port == 443` | Nur Webtraffic |
| `ip.geoip.country == "CN"` | Traffic nach Land (GeoIP-DB nötig) |

---

## Siehe auch

- [[Command Line Troubleshooting Tools]]
- [[Testing Port Connectivity]]
- [[The Bits and Bytes of Networking]]
- [[IPv6 and IPv4 Harmony]]
- [[Everything as a Service]]
