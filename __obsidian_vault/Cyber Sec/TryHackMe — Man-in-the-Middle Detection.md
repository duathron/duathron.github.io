 
**Plattform:** TryHackMe  
**Pfad:** SOC Level 1 → Network Security Monitoring  
**Schwierigkeit:** Easy  
**Geschätzte Zeit:** 60 Minuten  
**URL:** https://tryhackme.com/room/mitmdetection  
> Lernziel: Verstehen, was ein MITM-Angriff ist und wie man die Spuren dieses Angriffs im Netzwerkverkehr identifiziert.
![Room Banner](https://tryhackme-images.s3.eu-west-1.amazonaws.com/room-icons/5e8dd9a4a45e18443162feab-1759866251635)
---
## Task 1 — Introduction
Man-in-the-Middle (MITM) Angriffe zählen zu den gefährlichsten Bedrohungen in der Netzwerksicherheit. Angreifer positionieren sich dabei zwischen zwei legitimen Kommunikationsendpunkten, um Datenverkehr abzufangen, zu manipulieren oder umzuleiten. Aus Blue-Team-Perspektive erfordert die Erkennung solcher Angriffe einen mehrschichtigen Ansatz aus Netzwerküberwachung, Zertifikatsvalidierung und Verhaltensanalyse.
![Room Illustration](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759866709706.png)
### Learning Objectives
- MITM-Angriffsvektoren und -techniken verstehen
- Indicators of Compromise (IoC) im Zusammenhang mit MITM-Angriffen erkennen
- Netzwerküberwachungstools für die Erkennung verdächtiger Verkehrsmuster einsetzen
- Incident-Response-Verfahren für MITM-Szenarien anwenden
### Voraussetzungen
- Wireshark: The Basics
- Network Security Essentials
- Networks Discovery Detection
---
## Task 2 — Lab Connection
### Szenario
Ein routinemäßiger Netzwerküberwachungsalarm bei **Acme Corp** zeigte ungewöhnliche Verkehrsmuster, die auf einen möglichen Man-in-the-Middle-Angriff im internen LAN hindeuten. Über mehrere Tage hat ein Angreifer stillschweigend Kommunikation abgefangen, Verbindungen umgeleitet und Benutzeranmeldedaten erfasst.
In diesem Raum schlüpfst du in die Rolle eines **SOC-Analysten**, der diesen Vorfall untersucht. Anhand von Paketaufzeichnungen und Logs wirst du Beweise für **drei verkettete MITM-Techniken** aufdecken:
1. **ARP Spoofing** (Netzwerkabfangung)
2. **DNS Spoofing** (Umleitung)
3. **SSL Stripping** (Credential-Erfassung)
### Lab-Zugang
Die Analyse erfolgt auf Basis der Netzwerkverkehrsdaten im `mitm`-Ordner auf dem Desktop. Äquivalente Logs sind im `mitm_network`-Ordner vorgehalten und in Splunk voreingespeist.
![Splunk Interface — Protokollübersicht mit DNS, HTTP, ARP und TLS](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759728313774.png)
---
## Task 3 — MITM Attacks: An Overview
### Was ist ein MITM-Angriff?
Ein Man-in-the-Middle-Angriff ist ein Cyberangriff, bei dem sich ein Angreifer heimlich in die Kommunikation zwischen zwei Parteien einklinkt — beispielsweise zwischen einem Benutzer und einem Dienst — ohne dass diese es wissen. Der Angreifer kann sensible Daten wie Anmeldeinformationen oder Kreditkartendaten stehlen oder bösartige Inhalte einschleusen.
![MITM Attack Diagram — Normal vs. MITM-Szenario](https://tryhackme-images.s3.amazonaws.com/room-icons/5e8dd9a4a45e18443162feab-1759866279169)
MITM-Angriffe bestehen im Allgemeinen aus zwei Hauptschritten:
- **Interception:** Der Angreifer schaltet sich in einen Kommunikationsstrom ein, indem er Schwachstellen in Netzwerkprotokollen (z. B. ARP, DNS) oder IP-Spoofing ausnutzt.
- **Manipulation/Decryption:** Der Angreifer versucht, die Kommunikation zu entschlüsseln oder zu modifizieren — etwa durch veränderte Website-Antworten oder gefälschte Login-Formulare.
### Häufige MITM-Angriffsvarianten
- **Packet Sniffing:** Erfassen unverschlüsselter Datenpakete, häufig in offenen WLAN-Netzen.
- **Session Hijacking:** Stehlen von Session-Tokens zur Identitätsübernahme.
- **SSL Stripping:** Downgrade von HTTPS auf HTTP zur Datenerfassung.
- **DNS Spoofing:** Umleitung von Webverkehr durch manipulierte DNS-Antworten.
- **IP Spoofing:** Gefälschte IP-Pakete, die von vertrauenswürdigen Systemen zu stammen scheinen.
- **Rogue Wi-Fi Access Point:** Erstellen gefälschter Netzwerke zum Abfangen von Benutzerverkehr.
### Real-World Beispiele
- 2017 erlitt **Equifax** einen massiven Datenverlust durch einen MITM-Angriff mit Offenlegung von über 100 Millionen Nutzerdaten.
- Hochkarätige Angriffe umfassten Code-Injektionen durch ISPs und staatliche Akteure, die Suchanfragen über SSL-Spoofing abfingen.
### MITM im Cyber Kill Chain Framework
MITM wird primär in der **Exploitation**- und **Installation**-Phase eingesetzt:
- **Als Exploitation-Technik:** Ausnutzen von Kernprotokoll-Schwachstellen (ARP, DNS) zur Übernahme des Kommunikationskanals.
- **Als Installation-Vektor:** Einschleusen bösartiger Payloads in legitimem Datenverkehr (Browser-Exploits, Malware-Dropper, RATs).
Das Erkennen eines MITM-Angriffs ist ein kritischer Befund — er zeigt an, dass sich ein Angreifer aktiv in den mittleren Phasen eines Einbruchs befindet.
---
## Task 4 — Detecting ARP Spoofing
### Was ist das ARP-Protokoll?
ARP (Address Resolution Protocol) ordnet IP-Adressen MAC-Adressen in einem lokalen Netzwerk zu. Ein Gerät sendet eine Broadcast-Anfrage: „Wer hat diese IP?" und das korrekte Gerät antwortet mit seiner MAC-Adresse.
### ARP Spoofing
Beim ARP-Spoofing sendet ein Angreifer gefälschte ARP-Antworten, um Geräte dazu zu bringen, die MAC-Adresse des Angreifers mit einer legitimen IP (üblicherweise dem Standard-Gateway) zu verknüpfen. Dies ermöglicht das Abfangen, Modifizieren oder Umleiten von Datenverkehr.
**Warum ARP-Spoofing funktioniert:** ARP hat keine Authentifizierung. Jedes Gerät kann unaufgeforderte `is-at`-Nachrichten senden. Beispiel:
```
192.16.10.100 is at 02:fe:BB:cd:55:55  ← Angreifer gibt vor, das Gateway zu sein
```
**Ergebnis:**
- Der ARP-Cache des Opfers wird vergiftet (ARP Cache Poisoning).
- Der gesamte für das Gateway bestimmte Datenverkehr fließt zuerst durch den Angreifer (MITM).
### Indikatoren des Angriffs
| Indikator | Beschreibung |
|---|---|
| Duplicate MAC-to-IP Mappings | Mehrere MAC-Adressen beanspruchen dieselbe IP-Adresse |
| Unsolicited ARP Replies | Hohe Anzahl von ARP-Antworten ohne passende Anfragen (Gratuitous ARP) |
| Abnormal ARP Traffic Volume | Hohe Anzahl von ARP-Paketen in kurzen Intervallen |
| Unusual Traffic Routing | Datenverkehr wird über die MAC des Angreifers umgeleitet |
| Gateway Redirection Patterns | Mehrere Ziel-MACs für dieselbe Gateway-IP |
| ARP Probe/Reply Loops | Viele Anfragen mit `Who has 192.168.1.x? Tell 192.168.1.y`-Mustern |
### Netzwerkinformationen (Untersuchungsfall)
| Rolle | IP | MAC | Hinweise |
|---|---|---|---|
| Gateway | 192.168.10.1 | — | Legitimer Router |
| Attacker | — | — | — |
| Victim | — | — | — |
| Domain | corp-login.acme-corp.local | — | — |
### Netzwerkverkehrsanalyse mit Wireshark
**Datei:** `network-traffic.pcap` im `mitm_traffic`-Ordner auf dem Desktop.
#### 1. ARP-Verkehr isolieren
```
Filter: arp
```
![Wireshark — Gesamter ARP-Verkehr (Requests & Replies)](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759721627827.png)
*Hinweis: CTRL + ALT + 1 drücken, um die angezeigte Zeit zu korrigieren.*
#### 2. ARP Requests analysieren
```
Filter: arp.opcode == 1
```
![Wireshark — ARP Requests von verschiedenen Hosts](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759721650230.png)
#### 3. ARP Responses analysieren
Forged ARP Poisoning nutzt typischerweise unaufgeforderte `is-at`-Antworten (Gratuitous/Unasked Replies). Diese sind starke Indikatoren.
```
Filter: arp.opcode == 2
```
![Wireshark — ARP Responses inkl. Gratuitous Replies](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759721672516.png)
Legitime Antworten korrespondieren mit kürzlich gesendeten `who-has`-Anfragen. Verdächtige Aktivität zeigt sich durch zahlreiche Antworten ohne sichtbare Anfragen oder wiederholte Werbung derselben IP von einer verdächtigen MAC-Adresse.
#### 4. Gratuitous ARP Responses filtern
Ein verdächtiger Host sendet viele unaufgeforderte (gratuitous) ARP-Antworten — besonders an mehrere Ziele. Wiederholte Gratuitous ARPs können darauf hinweisen, dass ein Angreifer seinen Vergiftungszustand aufrechterhält.
```
Filter: arp.isgratuitous
```
![Wireshark — Gratuitous ARP Responses](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759721798929.png)
#### 5. ARP-Verkehr des Gateways untersuchen
```
Filter: arp && arp.src.proto_ipv4 == 192.168.10.1 && eth.src == 02:aa:bb:cc:00:01
```
![Wireshark — ARP-Verkehr des legitimen Gateways](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759771248599.png)
#### 6. Gateway-IP auf mehrere MACs prüfen
```
Filter: arp.opcode == 2 && arp.src.proto_ipv4 == 192.168.10.1
```
![Wireshark — Mehrere MACs für die Gateway-IP 192.168.10.1](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759771696260.png)
#### 7. ARP-Spoofing-Bestätigung
```
Filter: arp.opcode == 2 && _ws.col.info contains "192.168.10.1 is at"
```
![Wireshark — Bestätigung des ARP-Spoofings (Gateway-IP auf Angreifer-MAC)](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759772377568.png)
#### 8. Verdächtige MAC-Adresse isolieren
```
Filter: arp.opcode == 2 && arp.src.proto_ipv4 == 192.168.10.1 && eth.src == 02:fe[REDACTED]
```
![Wireshark — Angreifer-MAC bestätigt ARP Spoofing](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759721746435.png)
#### 9. Duplicate IP-to-MAC Mappings prüfen
```
Filter: arp.duplicate-address-detected || arp.duplicate-address-frame
```
![Wireshark — Duplicate Address Detection bestätigt ARP Poisoning](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759841349525.png)
Dieses Ergebnis bestätigt, dass der Angreifer erfolgreich ARP-Spoofing durchgeführt und sich zwischen Opfer und Gateway positioniert hat.
### Fragen (Task 4)
1. Wie viele ARP-Pakete von der Gateway-MAC-Adresse wurden beobachtet?
2. Welche MAC-Adresse wurde vom Angreifer verwendet, um das Gateway zu imitieren?
3. Wie viele Gratuitous ARP Replies wurden für 192.168.10.1 beobachtet?
4. Wie viele eindeutige MAC-Adressen haben dieselbe IP (192.168.10.1) beansprucht?
5. Wie viele ARP-Spoofing-Pakete wurden insgesamt vom Angreifer beobachtet?
---
## Task 5 — Unmasking DNS Spoofing
### DNS-Protokoll vereinfacht erklärt
DNS funktioniert wie ein Telefonbuch: Statt Telefonnummern werden menschenlesbare Webadressen (wie `www.google.com`) in computerlesbare IP-Adressen übersetzt.
### DNS Spoofing (DNS Cache Poisoning)
DNS Spoofing liegt vor, wenn ein Angreifer dieses System korrumpiert und dem Computer des Opfers eine falsche „Telefonnummer" für eine Website gibt. Ablauf:
1. Das **Opfer** versucht, seine Bank unter `my-real-bank.com` zu besuchen.
2. Der **Angreifer** (bereits im lokalen Netz via ARP-Spoofing) fängt die DNS-Anfrage des Opfers ab.
3. Die **Täuschung:** Der Angreifer sendet eine gefälschte DNS-Antwort: „`my-real-bank.com` ist unter meiner IP: `ATTACKER_IP`"
4. Die **Abfangung:** Der Browser des Opfers verbindet sich direkt zum Server des Angreifers — einem perfekten Klon der echten Banking-Website.
![DNS Spoofing Diagram — Normaler vs. DNS-Spoofing-Ablauf](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759866941679.png)
### Netzwerkverkehrsanalyse mit Wireshark
#### 1. DNS-Verkehr isolieren
```
Filter: dns
```
![Wireshark — Gesamter DNS-Verkehr](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759722485876.png)
#### 2. Legitimen DNS-Verkehr filtern (Google DNS 8.8.8.8)
```
Filter: dns.flags.response == 1 && ip.src == 8.8.8.8
```
![Wireshark — Legitime DNS-Antworten von 8.8.8.8](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759722603327.png)
#### 3. DNS-Verkehr für die Zieldomain untersuchen
```
Filter: dns && dns.qry.name == "corp-login.acme-corp.local"
```
![Wireshark — DNS-Anfragen für corp-login.acme-corp.local](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759854528899.png)
#### 4. Legitime DNS-Antworten für die Zieldomain
```
Filter: dns.flags.response == 1 && ip.src == 8.8.8.8 && dns.qry.name == "corp-login.acme-corp.local"
```
![Wireshark — Legitime DNS-Antworten für corp-login.acme-corp.local](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759723160288.png)
#### 5. DNS-Antworten von anderen Quellen prüfen (Rogue DNS)
```
Filter: dns.flags.response == 1 && ip.src != 8.8.8.8
```
![Wireshark — Verdächtige DNS-Antworten von nicht-autorisierten Quellen](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759723059132.png)
#### 6. Alle DNS-Antworten analysieren
```
Filter: dns.flags.response == 1
```
![Wireshark — Alle DNS-Antworten (legitim und gefälscht)](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759723301205.png)
#### 7. Gefälschte DNS-Antworten des Angreifers isolieren
```
Filter: dns.flags.response == 1 && ip.src != 8.8.8.8 && dns.qry.name == "corp-login.acme-corp.local"
```
![Wireshark — Gefälschte DNS-Antworten des Angreifers (192.168.10.55)](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759722975158.png)
Dies zeigt, dass ein System im Netzwerk als Rogue-DNS-Server agiert und gefälschte DNS-Antworten sendet — ein klares Zeichen für DNS-Spoofing.
### Analyse-Zusammenfassung (Tasks 4 & 5)
- Ein erfolgreicher mehrstufiger MITM-Angriff: Der Angreifer vergiftete zunächst das ARP-Mapping für das Gateway (`192.168.10.1`).
- Anschließend sendete er gefälschte DNS-Antworten für `corp-login.acme-corp.local`, die das Opfer auf die IP des Angreifers umleiteten.
### Fragen (Task 5)
1. Wie viele DNS-Antworten wurden für die Domain `corp-login.acme-corp.local` beobachtet?
2. Wie viele DNS-Anfragen wurden von anderen IPs als `8.8.8.8` beobachtet?
3. Welche IP hat die gefälschte DNS-Antwort des Angreifers für die Domain zurückgegeben?
---
## Task 6 — Spotting SSL Stripping in Action
### Was ist SSL Stripping?
SSL Stripping ist eine MITM-Technik, bei der ein Angreifer den Datenverkehr abfängt und modifiziert, um die TLS-Verschlüsselung zwischen Client und Server zu entfernen oder zu verhindern. Der Client kommuniziert über HTTP (unverschlüsselt) während der Angreifer eine sichere HTTPS-Sitzung mit dem echten Server aufrechterhält.
![SSL Stripping Diagram — HTTPS wird zu HTTP degradiert](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759866992480.png)
### Wie SSL Stripping funktioniert
1. Das **Opfer** initiiert eine HTTPS-Anfrage an eine Website.
2. Der **Angreifer fängt die Anfrage ab** (z. B. via ARP-Spoofing oder Rogue Access Point).
3. Der **Angreifer verbindet sich über HTTPS** mit der Website, leitet aber die Antwort via HTTP an das Opfer weiter.
4. Das **Opfer interagiert unwissentlich über HTTP** und gibt dabei sensible Daten im Klartext preis.
### Indikatoren für SSL Stripping
- **Initial Request vs. Response:** Benutzer-Anfrage geht an HTTPS (Port 443), aber nachfolgende Pakete wechseln sofort zu unverschlüsseltem HTTP (Port 80) für dieselbe Domain.
- **Redirects/Link Rewriting:** Überwachung auf Redirects (HTTP-Statuscodes 301, 302), die HTTPS-Anfragen dauerhaft auf HTTP-Ressourcen umleiten.
- **Certificate Errors:** Anfänglicher TLS/SSL-Handshake schlägt fehl oder zeigt ein selbstsigniertes Zertifikat.
### Netzwerkverkehrsanalyse mit Wireshark
#### 1. SSL/TLS-Verkehr isolieren
```
Filter: tls || ssl
```
![Wireshark — TLS/SSL-Verkehrsübersicht](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759724393617.png)
#### 2. Verbindung des Opfers zum Angreifer (nach DNS-Spoofing)
Nach dem DNS-Spoofing wurde das Opfer auf die IP des Angreifers (`192.168.10.55`) geleitet. Zunächst gilt es zu überprüfen, ob TLS-Verkehr zwischen Opfer und Angreifer vorhanden ist:
```
Filter: dns.flags.response == 1 && ip.src == 192.168.10.55 && dns.qry.name == "corp-login.acme-corp.local"
```
![Wireshark — Bestätigung des DNS-Spoofings (Angreifer-IP 192.168.10.55)](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759724449015.png)
#### 3. TLS verschwindet — Verify TLS disappears
Eines der Hauptmerkmale von SSL Stripping ist, dass nach dem Spoofing kein TLS-Handshake mehr zum legitimen Server stattfindet:
```
Filter: http && ip.src == 192.168.10.10 && ip.dst == 192.168.10.55
```
![Wireshark — HTTP POST-Anfrage statt HTTPS (SSL Stripping bestätigt)](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759862810108.png)
Das Ergebnis zeigt deutlich, dass das Opfer sich nach dem SSL-Stripping mit dem Server verbunden hat und sich im Klartext eingeloggt hat (GET `/login` HTTP/1.1 und POST `/login` HTTP/1.1).
#### 4. Credentials im Klartext extrahieren
Durch Folgen des HTTP-Streams lassen sich die im Klartext übertragenen Anmeldedaten des Opfers identifizieren:
![Wireshark — Credential Capture via HTTP Stream Follow](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759724655694.png)
![Wireshark — Plaintext POST-Anfrage mit Benutzerdaten](https://tryhackme-images.s3.amazonaws.com/user-uploads/5e8dd9a4a45e18443162feab/room-content/5e8dd9a4a45e18443162feab-1759724796641.png)
Die Credentials des Opfers (Username und Passwort) sind im Klartext sichtbar — der Angriff war erfolgreich.
### Zusammenfassung des vollständigen Angriffsverlaufs
| Phase | Technik | Indikator |
|---|---|---|
| 1 | **ARP Spoofing (Cache Poisoning)** | Unaufgeforderte `is-at`-ARP-Antworten, die Gateway-IP beanspruchen |
| 2 | **DNS Spoofing (Forged DNS Responses)** | Opfer-DNS-Anfrage für `corp-login.acme-corp.local` → Angreifer antwortet mit eigener IP `192.168.10.55` |
| 3 | **SSL Stripping (TLS Downgrade / Credential Capture)** | Opfer verbindet sich über HTTP zum Angreifer; POST-Anfrage mit Credentials im Klartext |
### Fragen (Task 6)
1. Wie viele POST-Anfragen wurden für die Domain `corp-login.acme-corp.local` beobachtet?
2. Wie lautet das Passwort des Opfers, das im Klartext nach dem SSL-Stripping-Angriff gefunden wurde?
---
## Task 7 — Conclusion & Room Wrap-up
In diesem Raum wurden drei verkettete Man-in-the-Middle-Angriffstechniken in einem realen Szenario untersucht und ihre Spuren im Netzwerkverkehr analysiert.
### Schlüsselkonzepte
- **ARP Spoofing erkennen:** Durch das Auffinden von doppelten MAC-Adressen für verschiedene IPs im ARP-Cache (`arp -a`) oder in Wireshark.
- **DNS Spoofing aufdecken:** Durch das Identifizieren mehrerer, widersprüchlicher DNS-Antworten für dieselbe Domain.
- **SSL Stripping nachweisen:** Durch das Auffinden sensibler Daten (z. B. Passwörter), die im Klartext über HTTP an Websites übertragen werden, die eigentlich HTTPS verwenden sollten.
### Weiterführende Ressourcen
- [Data Exfiltration Detection](https://tryhackme.com/room/dataexfiltrationdetection) — untersucht und identifiziert Exfiltrationsversuche über mehrere Netzwerkkanäle.
---
## Zusammenfassung der Wireshark-Filter
| Task | Filter                                                       | Zweck                              |                              |                              |
| ---- | ------------------------------------------------------------ | ---------------------------------- | ---------------------------- | ---------------------------- |
| ARP  | `arp`                                                        | Gesamten ARP-Verkehr isolieren     |                              |                              |
| ARP  | `arp.opcode == 1`                                            | ARP Requests anzeigen              |                              |                              |
| ARP  | `arp.opcode == 2`                                            | ARP Responses anzeigen             |                              |                              |
| ARP  | `arp.isgratuitous`                                           | Gratuitous ARP filtern             |                              |                              |
| ARP  | `arp.opcode == 2 && arp.src.proto_ipv4 == 192.168.10.1`      | Gateway-IP auf mehrere MACs prüfen |                              |                              |
| ARP  | `arp.duplicate-address-detected \\                           | \\                                 | arp.duplicate-address-frame` | Duplicate IP-to-MAC Mappings |
| DNS  | `dns`                                                        | Gesamten DNS-Verkehr isolieren     |                              |                              |
| DNS  | `dns.flags.response == 1 && ip.src == 8.8.8.8`               | Legitime DNS-Antworten             |                              |                              |
| DNS  | `dns.flags.response == 1 && ip.src != 8.8.8.8`               | Verdächtige DNS-Antworten          |                              |                              |
| DNS  | `dns && dns.qry.name == "corp-login.acme-corp.local"`        | DNS-Verkehr für Zieldomain         |                              |                              |
| SSL  | `tls \\                                                      | \\                                 | ssl`                         | TLS/SSL-Verkehr isolieren    |
| SSL  | `http && ip.src == 192.168.10.10 && ip.dst == 192.168.10.55` | HTTP-Verbindung nach SSL Stripping |                              |                              |