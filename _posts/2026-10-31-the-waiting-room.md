---
title: The Waiting Room
date: 2026-10-31 08:00:00 +0100
categories:
  - Writeups
  - TryHackMe
tags:
  - phishing
  - email-forensics
  - unicode-rlo
  - obfuscation
  - rc4
  - pcap-analysis
  - cyberchef
  - windows-forensics
image:
  path: /assets/img/posts/the-waiting-room/cover.png
---

## Introduction

The Waiting Room hands you three artifacts from a compromise at a company called Meridian Office Supplies: a raw phishing email (`vendor.eml`), a set of Sysmon logs converted from `.evtx`, and a network capture (`incident.pcap`). The job is to work out what the email actually delivered, trace it through the host logs to execution, and follow the trail all the way to data leaving the network. No single tool does this one. It's email headers, a JScript deobfuscation puzzle, a Unicode trick I'd never run into before, and a stream cipher implemented by hand in plain JavaScript.

## Theory

A few things came up that I had to look up or confirm before they made sense:

- **Right-to-Left Override (U+202E).** A Unicode control character that forces everything after it to render right-to-left. Drop it into a filename before a reversed extension and the real extension (`.hta`) displays as something else entirely (`.pdf`). I'd never run into this trick before; I only found out what it was by looking up the codepoint mid-room.
- **RC4.** A stream cipher: a key-scheduling pass that shuffles a 256-byte state array using the key, then a pseudo-random generation pass that XORs the keystream against the data. I didn't recognize the algorithm on sight. An AI assistant I asked for help with the obfuscated script identified it as RC4 once I described what `transform()` was doing.
- **Sysmon event chains.** Each process-create event carries its own `ProcessId` and the `ParentProcessId`/`ParentImage` of whatever spawned it, so you can walk a chain of execution backwards from any single event.

## Walkthrough

### Reading the phishing email

`cat vendor.eml` shows a message from "Luke Sullivan, Accounts | Meridian Office Supplies" (`accounts@meridian.thm`) asking to confirm an invoice for the Friday payment run. Attached to it, as a MIME part, is `Remittance.one` (`Content-Type: application/onenote`, base64-encoded):

<img src="/assets/img/posts/the-waiting-room/the-waiting-room_01.png" width="700" alt="vendor.eml shown in a terminal with cat, with a MIME part for Remittance.one as application/onenote, base64-encoded">

Running `shasum -a 256` on the attachment gives a hash, but at this point it means nothing yet. I didn't have anywhere to check it against.

### Peeling back the OneNote payload

Pulling the base64 blob from the email into CyberChef, stripping whitespace and null bytes, then decoding from base64 turns the wall of text into a `<script language="JScript">` block: an `entries` array of hex strings, a `value()` function that XORs each byte against `0x39` to decode them, and a `transform()` function that shuffles a 256-byte array using a key and then XORs that against the data (some kind of stream cipher, though at this point I didn't know which one). The whole thing builds an `ActiveXObject` HTTP request, downloads something, decrypts it, and writes it to disk:

<img src="/assets/img/posts/the-waiting-room/the-waiting-room_02.png" width="700" alt="CyberChef recipe with Remove null bytes, Remove whitespace, and From Base64 decoding the attachment into a JScript loader">

### Tracing the detonation in Sysmon

Converting the Sysmon `.evtx` to JSON and piping it through `jq` turns up the moment this actually runs: `ONENOTE.EXE` spawning with a `TargetFilename` of `C:\Users\m.smith\Downloads\PO-1048\Remittance_<something>fdp.hta`. Except that's not quite what it reads as on screen. The raw JSON shows reversed characters sitting right before the extension:

<img src="/assets/img/posts/the-waiting-room/the-waiting-room_03.png" width="700" alt="Sysmon event converted to JSON, showing ONENOTE.EXE with a TargetFilename containing reversed characters before the extension">

### The Right-to-Left Override trick

I was stuck on this for a while. The filename just looked broken. Going back through my own notes I found the character sitting right before the reversed part: `<0x202E>`. A quick search told me what it was: U+202E, Right-to-Left Override, a Unicode control character that flips the display direction of everything after it. So `Remittance_<U+202E>fdp.hta` renders on screen as `Remittance_ath.pdf`, a `.hta` file wearing a `.pdf` costume, purely through how the text gets displayed and not through any change to the actual file:

<img src="/assets/img/posts/the-waiting-room/the-waiting-room_04.png" width="700" alt="Grep output highlighting the U+202E Right-to-Left Override codepoint sitting before the reversed file extension">

### From .hta to .js

Following the process chain further, `mshta.exe` running that `.hta` leads to `cscript.exe //B //Nologo` executing `C:\Users\m.smith\AppData\Local\Meridian\receipt.js`, passed the argument `MR-6106-028`, the same invoice number from the original email:

<img src="/assets/img/posts/the-waiting-room/the-waiting-room_05.png" width="700" alt="Sysmon JSON showing cscript.exe launching receipt.js with the argument MR-6106-028, parent of a conhost.exe process, under user m.smith">

The email header had already given up the hosting domain for all of this: `portal.meridian.thm`.

### Checking VirusTotal

I'd gotten this far and still couldn't answer one of the room's questions. The hash I ran earlier just wasn't matching anything I'd tried. Then I realized I'd skipped the obvious step: actually checking it against VirusTotal. The SHA256 of `Remittance.one` came back flagged by several vendors as `trojan.rlotrick/camelot`, and a related file listed alongside it, `Remittance_ath.pdf`, was labeled `trojan.sload`. That second file's hash `[redacted]` was the actual answer I'd been missing, not the one I started with.

### Finding the exfiltrated data in the pcap

`incident.pcap` in Wireshark, under **File → Export Objects → HTTP**, lists three objects pulled from `portal.meridian.thm:8080`: a file named `remittance-v2.png`, and two objects both labeled `receipt`:

<img src="/assets/img/posts/the-waiting-room/the-waiting-room_06.png" width="700" alt="Wireshark Export HTTP Object List showing remittance-v2.png and two receipt objects from portal.meridian.thm:8080">

`file` on the exported `remittance-v2.png` just says "data." It's not an actual image, despite the extension. The receipt objects look like binary noise too. Given what the JScript loader does (download, decrypt, write), this looked like the same pattern again: a payload disguised with the wrong extension, probably encrypted on the wire.

### Decrypting receipt.js with a bit of AI help

The downloader script writes a `cacheToken` into the file it drops, and I didn't know JavaScript well enough to work out on my own what that value was or how it got used. I gave the script to DuckDuckGo's AI assistant (GPT6-Luna) and asked it to walk me through it. It explained the XOR string decoding, confirmed `transform()` was RC4's key-scheduling and keystream generation, and worked out the actual `cacheToken` value from the decoded strings. Asking a follow-up question about what algorithm `transform()` actually implemented is what got me a clear answer: RC4, with the `cacheToken` as the key.

### Decrypting the receipt with CyberChef

With the key in hand, CyberChef's RC4 recipe against the exported `receipt.bin`, key entered as hex, decrypts straight to a readable CSV:

<img src="/assets/img/posts/the-waiting-room/the-waiting-room_07.png" width="700" alt="CyberChef RC4 recipe decrypting receipt.bin with the cacheToken as a hex passphrase, output showing an invoice CSV">

```
invoice,vendor,due_date,amount,currency,account,status
MR-6106-028,Meridian Office Supplies,...,awaiting_approval
ST-8832,Stonebridge Couriers,...,scheduled
WR-4407,Westbrook Print,...,awaiting_approval
```

The SHA256 of that CSV content `[redacted]` was the room's final answer.

## Lessons Learned

- I'd never heard of the Right-to-Left Override trick before this room. I stared at that reversed filename for longer than I'd like to admit before I remembered my own earlier note about the stray codepoint sitting next to it, and only understood what I was looking at after searching for the codepoint itself.
- I got stuck on an unmatched hash for a while because I skipped VirusTotal entirely at first. Having the hash isn't the same as having checked it against anything.
- I don't know JavaScript well, and I used an AI assistant to help read through the obfuscated loader rather than pretending I worked it out line by line myself. That's genuinely how I got through it, RC4 included. I wouldn't have named the algorithm on my own.

## References

- [TryHackMe Room — The Waiting Room](https://tryhackme.com/room/thewaitingroom)
- [CyberChef](https://gchq.github.io/CyberChef/)
- [Wireshark](https://www.wireshark.org/)
