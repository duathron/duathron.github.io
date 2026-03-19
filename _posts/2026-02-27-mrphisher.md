---
title: "TryHackMe — Mr Phisher"
date: 2026-02-27 00:00:00 +0100
categories:
  - Writeups
  - TryHackMe
tags:
  - mrphisher
  - easy
published: true
image:
  path: /assets/img/posts/mrphisher/cover.png
  alt: "Mr Phisher"
related_notes: ["[[Phishing]]", "[[VBA Macros]]", "[[XOR]]", "[[Malware Analysis]]"]
---

A suspicious email has arrived with a strange-looking attachment. The task: uncover the flag hidden inside it. The attachment is a `.docm` file — a macro-enabled Word document — one of the most common delivery mechanisms for malware in phishing campaigns.

This room introduces the analysis of malicious Office macros. No network scanning, no exploitation — just a document, a macro, and some basic reverse engineering.

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Mr Phisher |
| Difficulty | Easy |
| Tags | phishing, macro, vba, xor, malware-analysis |

---

## Theory

### Macro-Enabled Documents

Files with the `.docm` extension are Microsoft Word documents that can contain embedded macros — small programs written in VBA (Visual Basic for Applications). Macros are legitimate productivity tools, but attackers exploit them to execute malicious code on a victim's machine. The typical attack flow: a phishing email delivers a `.docm` attachment, the document displays a convincing prompt to "enable macros", and the victim complies — triggering the payload.

This is why modern Office applications disable macros by default. Analysing the macro without executing it is the safe approach — and exactly what this room requires.

### XOR Encoding

XOR (exclusive or) is a binary operation frequently used in malware for simple obfuscation. It's reversible (`A XOR B XOR B = A`), fast, and makes data unreadable at a glance. In this room, the macro uses XOR with a sequential index as the key — my first encounter with this pattern.

---

## Reconnaissance

### Initial File Inspection

```bash
strings MrPhisher.docm | grep -i "flag"
strings MrPhisher.docm | grep -i "THM"
```

Neither returned results. The content is obfuscated, not stored in the clear.

### Hash Lookup via VirusTotal

```bash
sha256sum MrPhisher.docm
```

Searching the hash on [VirusTotal](https://www.virustotal.com/) confirmed the file was flagged as malicious — VBA macros, trojan downloaders.

<img src="/assets/img/posts/mrphisher/vt-mrphisher.png" alt="VirusTotal flags the file as malicious" width="700">

> Checking file hashes against VirusTotal is a standard first step in malware triage — fast, non-invasive, and provides immediate context without executing the file.

---

## Enumeration

### Locating the Macro

**Tools → Macros → Edit Macros** in LibreOffice opens the Basic IDE. Under the project tree: `MrPhisher.docm → Project → Modules → NewMacros → Format`.

<img src="/assets/img/posts/mrphisher/macro-editor.png" alt="LibreOffice Basic IDE showing the VBA macro" width="700">

```vb
Sub Format()
Dim a()
Dim b As String
a = Array(102, 109, 99, 100, 127, 100, 53, 62, 105, 57, 61, 106, 62, 62, 55, 110, 113, 114, 118, 39, 36, 118, 47, 35, 32, 125, 34, 46, 46, 124, 43, 124, 25, 71, 26, 71, 21, 88)
For i = 0 To UBound(a)
b = b & Chr(a(i) Xor i)
Next
End Sub
```

The logic: iterate over an array, XOR each value with its index, convert to a character, append to string `b`. The macro never outputs `b` — suspicious in itself.

---

## Data Extraction & Recovery

### Decoding with Python

```python
a = [102,109,99,100,127,100,53,62,105,57,61,106,62,62,55,110,
     113,114,118,39,36,118,47,35,32,125,34,46,46,124,43,124,
     25,71,26,71,21,88]
print(''.join(chr(v ^ i) for i, v in enumerate(a)))
```

Step by step for the first three values:

| i | v | v XOR i | chr() |
|---|---|---------|-------|
| 0 | 102 | 102 | `f` |
| 1 | 109 | 108 | `l` |
| 2 | 99 | 97 | `a` |

The output is the flag.

### A Note on AI-Assisted Decoding

When using AI to write the Python script, Claude didn't just output the XOR result — it interpreted the hex string inside the flag braces as an MD5 hash and presented a "decoded" leetspeak phrase that thematically fits the room. That phrase doesn't produce the correct MD5 hash. TryHackMe rejected it. The actual answer is the literal XOR output. AI can be confidently wrong in ways that are hard to spot when the output is thematically coherent. Always verify independently.

### Tools Used

- **Terminal** (`strings`, `sha256sum`) — initial file inspection
- **VirusTotal** — hash-based threat intelligence lookup
- **LibreOffice** — document and macro inspection
- **Python** — XOR decoding

---

## Lessons Learned

**Start with the basics.** `strings` and a hash lookup cost seconds. VirusTotal confirmed the file was worth investigating before opening it.

**Don't execute what you can read.** The macro's logic was readable statically. Running it would have been unnecessary and potentially dangerous.

**XOR encoding is not encryption.** When the key is the array index (0, 1, 2...), XOR provides zero security. Obfuscation and security are different things.

**Verify AI output independently.** Claude hallucinated a plausible plaintext that cost a failed submission. AI is useful for writing scripts, but its output is not ground truth.

**VBA macros remain a real-world threat vector.** Macro-based phishing attacks exploit user trust rather than technical vulnerabilities — directly relevant to SOC work.

---

## References

- [OWASP — Phishing](https://owasp.org/www-community/attacks/Phishing)
- [VirusTotal — File Analysis](https://www.virustotal.com/gui/file/51eab087b585482a1ea66a9f8623140557a217e01227622fb822b154c8edb86d/)
- [XOR Cipher — Wikipedia](https://en.wikipedia.org/wiki/XOR_cipher)
- [TryHackMe Room](https://tryhackme.com/room/mrphisher)
