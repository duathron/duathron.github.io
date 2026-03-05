<%*
const platform = await tp.system.prompt("Platform (TryHackMe/HackTheBox)");
const roomname = await tp.system.prompt("Room/Machine Name (lowercase-with-dashes)");
const title_room = await tp.system.prompt("Display Title (e.g. IDOR)");
const difficulty = await tp.system.prompt("Difficulty (Easy/Medium/Hard)");
const type = await tp.system.prompt("Type (web/network/linux/windows/crypto/misc)");
const date = tp.date.now("YYYY-MM-DD");
const filename = `${date}-${roomname}`;
await tp.file.rename(filename);
-%>
---
title: "<% platform %> – <% title_room %>"
date: <%tp.date.now("YYYY-MM-DD HH:mm:ss")%> +0100
categories: [Writeups, <% platform %>]
tags: [<% roomname %>, <% difficulty.toLowerCase() %>, <% type %>]
published: false
image:
  path: /assets/img/posts/<% roomname %>/cover.jpg
  alt: "<% title_room %>"
---

## Overview

| Field | Details |
|-------|---------|
| Platform | <% platform %> |
| Room/Machine | <% title_room %> |
| Difficulty | <% difficulty %> |
| Type | <% type %> |
| Tags | <% roomname %>, <% type %>, <% difficulty.toLowerCase() %> |

Brief summary of what this room/machine is about and what you'll learn.

---

## Theory

<!-- Für reine CTF-Machines ohne Theorie-Teil: diesen Block löschen -->

### What is [TOPIC]?

Kurze Erklärung des Angriffsvektors oder der Technik.

### Where does it appear?

Wo und in welcher Form tritt die Schwachstelle typischerweise auf?

### How is it disguised?

Gängige Verschleierungsmuster und warum sie keine echte Sicherheit bieten.

---

## Warm-up / Practice Exercise

<!-- Falls der Room eine einleitende Übungsaufgabe hat – sonst löschen -->

Kurze Beschreibung des Warm-up-Szenarios und was es demonstriert.

---

## Reconnaissance

<!-- Für Web-Rooms: Nmap-Block löschen, nur Manual Exploration behalten -->
<!-- Für Netzwerk/Linux/Windows: Nmap-Block behalten -->

### Nmap Scan

```bash
nmap -sC -sV -oN nmap/initial TARGET_IP
```

```
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH x.x
80/tcp open  http    Apache x.x
```

### Manual Exploration

Erste Schritte auf der Weboberfläche – was ist sichtbar, was fällt auf?

Für jede Seite **DevTools (F12)** öffnen und prüfen:

- **Elements / Source** – versteckte Links, Kommentare, hardcodierte Pfade
- **Network** – welche Requests werden gefeuert, was kommt zurück
- **Response Headers** – Metadaten-Leakage

---

## Enumeration

### [Fundstelle 1]

Was du gefunden hast und wie.

### [Fundstelle 2]

Was du gefunden hast und wie.

---

## Exploitation

### [Angriffsvektor]

Schritt-für-Schritt-Beschreibung.

```bash
# verwendete Befehle
```

### Tools Used

Welche Tools wurden eingesetzt und warum.

### Going Further

<!-- Optional: Was über den Room hinaus möglich wäre, z.B. Automatisierung -->

---

## Privilege Escalation

<!-- Nur für Maschinen mit lokalem Zugang relevant – sonst löschen -->

Wie du von User zu Root gekommen bist.

---

## Lessons Learned

**[Erkenntnis 1].** Ausführlichere Erklärung was das bedeutet und warum es wichtig ist.

**[Erkenntnis 2].** Ausführlichere Erklärung.

**[Erkenntnis 3].** Ausführlichere Erklärung.

---

## References

- [TryHackMe Room](https://tryhackme.com/room/<% roomname %>)
