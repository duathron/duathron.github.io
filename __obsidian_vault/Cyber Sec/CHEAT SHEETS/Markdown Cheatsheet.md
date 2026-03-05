# [Markdown] Cheat Sheet

## für [Jekyll] / [Chirpy] [Blogposts]

---

## Überschriften

```markdown
# H1 – Seitentitel (nur einmal pro Post)
## H2 – Hauptabschnitt
### H3 – Unterabschnitt
#### H4 – Detail
```

---

## Text formatieren

```markdown
**fett**
*kursiv*
~~durchgestrichen~~
`inline code`
```

**fett** | _kursiv_ | ~~durchgestrichen~~ | `inline code`

---

## Listen

```markdown
- Punkt 1
- Punkt 2
  - Unterpunkt

1. Erster Schritt
2. Zweiter Schritt
3. Dritter Schritt
```

---

## Links

```markdown
[Linktext](https://url.com)
[TryHackMe](https://tryhackme.com)
```

---

## Bilder

```markdown
![Alt Text](/assets/img/posts/ROOMNAME/bild.png)
_Bildunterschrift erscheint in Chirpy automatisch_
```

---

## Code Blöcke

````markdown
```bash
nmap -sC -sV 10.10.10.10
```

```python
print("Hello World")
```

```text
Plaintext output hier
```
````

Unterstützte Sprachen u.a.: `bash`, `python`, `javascript`, `html`, `css`, `sql`, `text`, `yaml`, `json`

---

## Tabellen

```markdown
| Spalte 1 | Spalte 2 | Spalte 3 |
|----------|----------|----------|
| Wert 1   | Wert 2   | Wert 3   |
| Wert 4   | Wert 5   | Wert 6   |
```

|Spalte 1|Spalte 2|Spalte 3|
|---|---|---|
|Wert 1|Wert 2|Wert 3|

---

## Zitat / Blockquote

```markdown
> Dies ist ein Zitat oder eine wichtige Notiz.
```

> Dies ist ein Zitat oder eine wichtige Notiz.

---

## Horizontale Linie

```markdown
---
```

---

## Chirpy-spezifische Extras

### Hinweisboxen (Prompts)

```markdown
> Dies ist eine Info.
{: .prompt-info }

> Achtung, wichtig!
{: .prompt-warning }

> Gefahr / Fehler.
{: .prompt-danger }

> Tipp.
{: .prompt-tip }
```

### Fußnoten

```markdown
Hier ist ein Text mit Fußnote.[^1]

[^1]: Das ist die Fußnote am Ende des Posts.
```

### Aufgabenliste (Checklist)

```markdown
- [x] Erledigt
- [ ] Noch offen
- [ ] Noch offen
```

---

## Front Matter Referenz

```yaml
---
title: "Titel des Posts"
date: 2026-02-18 12:00:00 +0100
categories: [CTF, TryHackMe]
tags: [linux, web, privesc]
image:
  path: /assets/img/posts/roomname/cover.jpg
  alt: "Alt Text"
pin: true        # Post oben anheften
toc: true        # Table of Contents anzeigen
comments: true   # Kommentare aktivieren
---
```

---

## Schnellreferenz Sonderzeichen escapen

Wenn Markdown-Zeichen als Text erscheinen sollen:

```markdown
\* \_ \` \# \[ \] \{ \}
```


<img src="/_assets/img/posts/idor/burp-request.png" alt="Burp Request" width="700">