---
title: "CIA Triad"
tags: [fundamentals, theory, confidentiality, integrity, availability]
---

Die drei Grundprinzipien der Cybersicherheit, um die sich nahezu alle Konzepte drehen. Jeder Angriff und jede Schutzmaßnahme lässt sich einem oder mehreren dieser Pfeiler zuordnen.

## Confidentiality (Vertraulichkeit)

Sensible Daten dürfen nur von autorisierten Personen eingesehen werden. Verletzungen führen zu Datenlecks, Datenschutzverstößen oder finanziellem Schaden.

**Schutzmechanismen:** Verschlüsselung, Zugriffskontrollen, Authentifizierung

**Beispiele für Verletzungen:** Abfangen von Credentials in einem öffentlichen WLAN, Passwörter auf Klebezettel am Arbeitsplatz

## Integrity (Integrität)

Daten dürfen nur durch autorisierte Akteure verändert werden. Unautorisierte Modifikationen machen Daten unzuverlässig und können gefährliche Konsequenzen haben.

**Schutzmechanismen:** Hashing, digitale Signaturen, Checksums

**Beispiele für Verletzungen:** Manipulation einer Banküberweisung während der Übertragung, nachträgliches Ändern gespeicherter Datensätze

## Availability (Verfügbarkeit)

Daten und Dienste müssen für autorisierte Nutzer jederzeit erreichbar sein. Selbst ohne Datenverlust oder -manipulation kann ein Ausfall schwerwiegende Folgen haben.

**Schutzmechanismen:** Redundanz, Load Balancing, Traffic-Filter, Backup-Stromversorgung

**Beispiele für Verletzungen:** DDoS-Angriff legt eine Website lahm, kritische Dienste fallen durch Software-Installation aus

---

## Bezug zu anderen Themen

- [[2026-02-12-idor]] – IDOR verletzt primär **Confidentiality** (unautorisierter Zugriff auf fremde Daten) und ggf. **Integrity** (falls Schreibzugriff besteht). Broken Access Control (OWASP A01:2021) ist der übergeordnete Kategorisierungsrahmen.

---

## Referenzen

- [TryHackMe – Pre-Security / Cyber Security Introduction](https://tryhackme.com)
- [OWASP Top 10](https://owasp.org/Top10/)
