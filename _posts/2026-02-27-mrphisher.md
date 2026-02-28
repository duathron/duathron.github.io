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
---

## Overview

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Mr Phisher |
| Difficulty | Easy |
| Tags | phishing, macro, vba, xor, malware-analysis |

A suspicious email has arrived with a strange-looking attachment. The task: uncover the flag hidden inside it. The attachment is a `.docm` file — a macro-enabled Word document — one of the most common delivery mechanisms for malware in phishing campaigns.

This room introduces the analysis of malicious Office macros. No network scanning, no exploitation — just a document, a macro, and some basic reverse engineering.

---

## Theory

### Macro-Enabled Documents

Files with the `.docm` extension are Microsoft Word documents that can contain embedded macros — small programs written in VBA (Visual Basic for Applications). Macros are legitimate productivity tools, but attackers exploit them to execute malicious code on a victim's machine. The typical attack flow: a phishing email delivers a `.docm` attachment, the document displays a convincing prompt to "enable macros", and the victim complies — triggering the payload.

This is why modern Office applications disable macros by default and display security warnings. Analysing the macro without executing it is the safe approach — and exactly what this room requires.

### XOR Encoding

XOR (exclusive or) is a binary operation frequently used in malware for simple obfuscation. It's reversible (`A XOR B XOR B = A`), fast, and makes data unreadable at a glance without requiring complex encryption. In this room, the macro uses XOR with a sequential index as the key — my first encounter with this pattern, and a good introduction to how obfuscation works in practice.

---

## Reconnaissance

### Initial File Inspection

The virtual machine provides two files: `MrPhisher.docm` and a ZIP archive containing the same document. The VM has no internet connection and no specialised analysis tools installed — just a terminal and LibreOffice.

The first instinct was to check for low-hanging fruit using `strings` combined with `grep`:

```bash
strings MrPhisher.docm | grep -i "flag"
strings MrPhisher.docm | grep -i "THM"
```

Neither returned results. The file contained typical Office XML metadata and binary data, but no plaintext flag — the content is obfuscated, not stored in the clear.

### Hash Lookup via VirusTotal

To understand what's already known about this file, the SHA256 hash was calculated:

```bash
sha256sum MrPhisher.docm
```

Searching the hash `51eab087b585482a1ea66a9f8623140557a217e01227622fb822b154c8edb86d` on [VirusTotal](https://www.virustotal.com/gui/file/51eab087b585482a1ea66a9f8623140557a217e01227622fb822b154c8edb86d/) showed extensive detection results — two engines flagging the file as malicious, with references to VBA macros and trojan downloaders. This confirmed the file used a suspicious macro and needs to be investigated further.

<img src="/assets/img/posts/mrphisher/vt-mrphisher.png" alt="VirusTotal flags the file as (potentially) malicious" width="700">

> **Note:** Checking file hashes against VirusTotal is a standard first step in malware triage. It's fast, non-invasive, and provides immediate context — detection rates, community comments, behavioural reports — without having to execute the file.

---

## Enumeration

### Locating the Macro

Opening the document in LibreOffice Writer shows nothing suspicious — just an image. The real content is hidden in the embedded macro. Navigating to **Tools → Macros → Edit Macros** opens the LibreOffice Basic IDE. Under the document's project tree:

```
MrPhisher.docm → Project → Modules → NewMacros → Format
```

<img src="/assets/img/posts/mrphisher/macro-editor.png" alt="LibreOffice Basic IDE showing the VBA macro under NewMacros" width="700">

The macro contains the following VBA code:

```vb
Rem Attribute VBA_ModuleType=VBAModule
Option VBASupport 1
Sub Format()
Dim a()
Dim b As String
a = Array(102, 109, 99, 100, 127, 100, 53, 62, 105, 57, 61, 106, 62, 62, 55, 110, 113, 114, 118, 39, 36, 118, 47, 35, 32, 125, 34, 46, 46, 124, 43, 124, 25, 71, 26, 71, 21, 88)
For i = 0 To UBound(a)
b = b & Chr(a(i) Xor i)
Next
End Sub
```

### Reading the Code

Even without VBA experience, the logic is readable — especially with a foundation in Python fundamentals. The structure maps almost directly: an array, a loop, an index, a function call. The syntax is different, but the concepts are the same.

1. An array `a` holds 38 decimal values
2. A loop iterates from index `0` to the last element
3. Each value is XORed with its index (`a(i) Xor i`)
4. The result is converted to a character via `Chr()` and appended to string `b`

The macro never displays or outputs `b` — it just builds the string silently. That alone is suspicious: why would a macro compute something and do nothing visible with it? Here, the decoded string is the flag. In a real malicious document, this is where the actual payload would be assembled.

The array of decimal values and the explicit `Xor` in the code are the giveaway: this is XOR encoding with a sequential key (the index itself).

---

## Data Extraction & Recovery

### Decoding with Python

Rather than running the macro (which LibreOffice blocks by default for security reasons), the logic can be replicated in Python. The translation is almost 1:1:

```python
a = [102, 109, 99, ...]          # The array from the VBA macro

''.join(                          # Join all characters into a string
    chr(v ^ i)                    # chr() = number → ASCII character, ^ = XOR
    for i, v in enumerate(a)      # enumerate returns (index, value) pairs
)                                 # i=0,v=102 / i=1,v=109 / i=2,v=99 ...
```

Step by step for the first three values:

| i | v | v XOR i | chr() |
|---|---|---------|-------|
| 0 | 102 | 102 XOR 0 = 102 | `f` |
| 1 | 109 | 109 XOR 1 = 108 | `l` |
| 2 | 99 | 99 XOR 2 = 97 | `a` |

The first three characters are `fla` — the beginning of `flag{...}`. This mirrors the VBA logic exactly:

- VBA: `Chr(a(i) Xor i)` → Python: `chr(v ^ i)`
- VBA: `b = b & ...` (string concat) → Python: `''.join(...)`
- VBA: `For i = 0 To UBound(a)` → Python: `enumerate(a)`

The full script, written with AI assistance:

```python
a = [102,109,99,100,127,100,53,62,105,57,61,106,62,62,55,110,
     113,114,118,39,36,118,47,35,32,125,34,46,46,124,43,124,
     25,71,26,71,21,88]
print(''.join(chr(v ^ i) for i, v in enumerate(a)))
```

The output is the flag.

### A Note on AI-Assisted Decoding

When using AI to write the Python script, Claude didn't just output the XOR result — it interpreted the hex string inside the braces as an MD5 hash and went a step further, presenting a "decoded" version: a leetspeak phrase that thematically fits the room's topic. The problem: that phrase doesn't actually produce the correct MD5 hash. No rainbow table can reverse this particular string either. What most likely happened is that Claude inferred the room's theme from its training data and confabulated a plausible-sounding plaintext — not computed, not looked up, just generated to sound right.

TryHackMe rejected this fabricated flag. The actual answer is the literal XOR output, hex string and all. The takeaway: AI can be confidently wrong in ways that are hard to spot, especially when the output is thematically coherent. Always verify independently.

### Tools Used

- **Terminal** (`strings`, `sha256sum`) — initial file inspection
- **VirusTotal** — hash-based threat intelligence lookup
- **LibreOffice** — document and macro inspection
- **Python** — XOR decoding

---

## Lessons Learned

**Start with the basics.** `strings` and a hash lookup cost seconds and immediately provide context. `strings` didn't reveal the flag here, but it's still the right first step — it often does. VirusTotal confirmed the file was malicious and worth investigating before opening it.

**Don't execute what you can read.** The macro's logic was simple enough to understand statically. Running it would have been unnecessary and — in a real scenario — potentially dangerous. Static analysis is always the safer starting point.

**XOR encoding is not encryption.** When the key is predictable (here: the array index, `0, 1, 2, ...`), XOR provides zero security. It's obfuscation designed to evade basic string-matching detection, not to resist analysis. This was my first time reversing XOR-encoded data — and once the pattern clicked, decoding it was straightforward. A good reminder that obfuscation and actual security are very different things.

**Verify AI output independently.** In this case, Claude hallucinated a plausible plaintext for the hex string inside the flag — one that didn't even match the hash. The output looked convincing enough to submit, and it cost a failed attempt. AI is useful for writing scripts, but its output is not ground truth. Always cross-check.

**VBA macros remain a real-world threat vector.** Despite being well-known, macro-based phishing attacks are still effective because they exploit user trust rather than technical vulnerabilities. Understanding how they work — even at this basic level — is directly relevant to SOC work, where phishing email analysis is a daily task.

---

## References

- [Microsoft — Macro Malware](https://www.microsoft.com/en-us/security/blog/2021/12/09/a-closer-look-at-qakbots-latest-building-blocks-and-how-to-knock-them-down/)
- [OWASP — Phishing](https://owasp.org/www-community/attacks/Phishing)
- [VirusTotal — File Analysis](https://www.virustotal.com/gui/file/51eab087b585482a1ea66a9f8623140557a217e01227622fb822b154c8edb86d/)
- [XOR Cipher — Wikipedia](https://en.wikipedia.org/wiki/XOR_cipher)
- [TryHackMe Room](https://tryhackme.com/room/mrphisher)
