---
title: "TryHackMe — Hack From the Back 1: Stolen Mount"
date: 2026-02-15 18:44:13 +0100
categories:
  - Writeups
  - TryHackMe
tags:
  - hfb1stolenmount
  - easy
published: true
image:
  path: /assets/img/posts/hfb1stolenmount/cover.png
  alt: "Hack From the Back 1: Stolen Mount"
---

## Overview

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Hack From the Back 1: Stolen Mount |
| Difficulty | Easy |
| Tags | wireshark, pcap, nfs, nta, network-forensics, cyberchef |

An intruder has infiltrated the network and targeted the NFS server where backup files are stored. A classified secret was accessed and stolen. The only evidence left behind is a packet capture (PCAP) file recorded during the incident. The mission: analyse the capture and discover the contents of the stolen data.

This is a purely forensic challenge — no exploitation, no shells. It's a **Network Traffic Analysis (NTA)** exercise: the entire room is solved by analysing captured traffic in Wireshark, recovering exfiltrated data, and decoding the stolen secret.

---

## Theory

### What is NFS?

NFS (Network File System) is a protocol that allows a system to share directories and files with others over a network. It operates over TCP/UDP (typically port 2049) and is commonly used in Unix/Linux environments for centralised file storage. In a forensic context, NFS traffic captured in a PCAP can reveal exactly which files were accessed, read, or transferred — making it a valuable source of evidence when investigating data exfiltration.

### Why PCAP Analysis Matters

A PCAP (Packet Capture) file is a recording of network traffic. Tools like Wireshark allow analysts to reconstruct exactly what happened on a network: which hosts communicated, what protocols were used, and — crucially — what data was transferred. For unencrypted protocols like NFS, the actual file contents are visible in the captured packets.

This room builds directly on skills developed in three preparatory TryHackMe rooms:

- [Wireshark: The Basics](https://tryhackme.com/room/wiresharkthebasics) — interface navigation, packet inspection, display filters
- [Wireshark: Packet Operations](https://tryhackme.com/room/wiresharkpacketoperations) — filtering techniques, following streams, exporting data
- [Wireshark: Traffic Analysis](https://tryhackme.com/room/wiresharktrafficanalysis) — protocol-specific analysis, identifying anomalies, reconstructing events

Completing these rooms first provided the foundation for working confidently with an unfamiliar protocol like NFS. The techniques are the same — only the protocol changes.

### CyberChef

[CyberChef](https://gchq.github.io/CyberChef/) is a web-based data analysis tool developed by GCHQ, often described as the "Swiss Army Knife" for data transformation. It provides hundreds of operations that can be chained together in a drag-and-drop interface — encoding/decoding (Base64, hex, URL, HTML), encryption/decryption, hashing, compression, parsing, and format conversion, to name a few. In this room, it's only used for QR code decoding, but in practice it's an indispensable tool for CTFs and forensic analysis alike: decoding obfuscated strings, converting between formats, extracting data from encoded payloads, or reversing multi-layered encoding schemes — all without leaving the browser and without sending data to external servers.

---

## Reconnaissance

### Initial Triage

The virtual machine provides `challenge.pcapng` on the desktop. After opening it in Wireshark, sorting the packet list by **Length** (click the Length column header) immediately highlights an anomaly: **Frame 286** stands out at **986 bytes** — significantly larger than the rest. Large packets in NFS traffic typically indicate actual file content being transferred, as opposed to metadata operations like directory listings or lookups.

### Identifying the Payload

Inspecting Frame 286 reveals two things:

1. The string **`secret.PNG`** appears in the NFS data, identifying the filename being transferred.
2. The payload starts with the hex bytes **`50 4b 03 04`** — the magic bytes for a **ZIP archive** (`PK\x03\x04`). Despite the `.PNG` filename appearing in the NFS metadata, the actual data being transferred is a ZIP file containing that PNG.

<img src="/assets/img/posts/hfb1stolenmount/magic-bytes.png" alt="Wireshark hex pane showing ZIP magic bytes 50 4b 03 04" width="700">

> **Tip:** Magic bytes are the first few bytes of a file that identify its format, regardless of the file extension. Recognising common signatures — `50 4b` for ZIP, `89 50 4e 47` for PNG, `ff d8 ff` for JPEG — is a fundamental forensic skill. Wireshark shows the raw hex in the packet bytes pane at the bottom.

---

## Enumeration

### Extracting the ZIP from the PCAP

With the payload identified in **Frame 286**, extraction is straightforward. The packet structure is:

```
Frame 286 (986 bytes)
└── TCP payload (932 bytes)
    └── Remote Procedure Call, Type: Reply
        └── Network File System, Ops(3): SEQUENCE PUTFH READ_PLUS
            └── Opcode: READ_PLUS (68)
                └── Contents
                    └── Content Type: Data (0)
                        └── contents: <DATA>   ← right-click here
```

1. In the packet details pane, expand the NFS tree down to **READ_PLUS → Contents → Content Type: Data → contents: \<DATA\>**
2. Right-click on `contents: <DATA>` → **Export Packet Bytes**
3. Save to disk with a `.zip` extension

The exported file is a valid ZIP archive. However, attempting to extract its contents (`secret.PNG`) prompts for a password.

### Finding the Password in the Traffic

Since the file is password-protected, the next step is checking whether the password exists somewhere else in the capture. NFS is unencrypted — if the attacker accessed a credentials file, it would be in the traffic.

**Directory listing via READDIR (opcode 26):** Filtering for NFS READDIR operations reveals the contents of the NFS share. The directory listing shows several files, including:

- `secret.PNG` (the file we already extracted, wrapped in a ZIP)
- `hidden_stash.zip`
- `creds.txt`

The existence of `creds.txt` on the same share is promising.

**File read via READ_PLUS (opcode 68):** Filtering for NFS READ_PLUS operations and inspecting **packet 214** reveals the contents of `creds.txt`:

```
Archive Password
90eb7723a657b6597100aafef171d9f2 (md5)
```

<img src="/assets/img/posts/hfb1stolenmount/creds-md5.png" alt="Packet 214 showing creds.txt contents with MD5 hash" width="700">

The password is not stored in plaintext — it's an MD5 hash.

### Cracking the MD5 Hash

MD5 hashes of simple strings are trivially reversible via rainbow table lookup. Submitting the hash `90eb7723a657b6597100aafef171d9f2` to [CrackStation](https://crackstation.net/) instantly returns the plaintext: **`avengers`**.

> **Note:** This is not "cracking" in the brute-force sense. CrackStation uses precomputed lookup tables. MD5 hashes of common words and short strings are effectively just obfuscation, not real protection — exactly the same lesson as with hashed IDs in IDOR vulnerabilities.

---

## Data Extraction & Recovery

### Step 1: Unlock the ZIP Archive

With the recovered password, extract the ZIP:

```bash
unzip -P 'avengers' secret.zip
```

The archive contains a single file: `secret.PNG` — an image of a QR code.

### Step 2: Decode the QR Code

Rather than scanning the QR code with a phone, decode it safely using **CyberChef**:

1. Open [CyberChef](https://gchq.github.io/CyberChef/)
2. Drag the `secret.PNG` file into the input field
3. Add the **Parse QR Code** operation

The decoded output is the flag.

> **Why not scan with a phone?** Unknown QR codes could point to malicious URLs or leak your IP. CyberChef processes the image entirely client-side — no external requests.

### Tools Used

The entire challenge was completed with three tools:

- **Wireshark** — PCAP analysis, packet inspection, payload extraction
- **CrackStation** — MD5 rainbow table lookup
- **CyberChef** — QR code decoding

No specialised security tools or command-line utilities were required beyond `unzip`.

---

## Lessons Learned

**Sort by size first.** When analysing a PCAP, sorting by packet length is a quick way to find the interesting data. File transfers produce larger packets than protocol handshakes and metadata operations. In this case, the single 986-byte packet immediately pointed to the extracted file.

**Know your magic bytes.** The filename said `.PNG`, but the hex said `50 4b 03 04` — a ZIP file. File extensions can be misleading; magic bytes don't lie. Recognising common file signatures is a small investment that pays off repeatedly in forensic analysis.

**Unencrypted protocols are forensic goldmines.** NFS transmits everything in cleartext. File contents, directory listings, and in this case a credentials file — all visible to anyone capturing the traffic. This is exactly why encrypted alternatives (like NFSv4 with Kerberos) exist, and why network monitoring matters.

**MD5 is not a security mechanism.** A hash that can be reversed instantly via lookup table adds obfuscation, not security. The same principle applies whether it's a password hash or an obfuscated ID — if the input space is small or predictable, hashing provides no real protection.

**Tool mastery transfers across protocols.** NFS was an unfamiliar protocol going in, but the methodology — inspect packets, identify patterns, extract data — is identical to what works for HTTP, FTP, or SMB. Investing time in learning Wireshark deeply opens doors to many different protocols without needing to learn each one from scratch.

---

## References

- [Wireshark Documentation — Export Packet Bytes](https://www.wireshark.org/docs/wsug_html_chunked/ChAdvExportObjects.html)
- [CyberChef — Parse QR Code](https://gchq.github.io/CyberChef/)
- [CrackStation — Hash Lookup](https://crackstation.net/)
- [NFS Protocol Overview — RFC 7530](https://www.rfc-editor.org/rfc/rfc7530)
- [List of File Signatures (Magic Bytes)](https://en.wikipedia.org/wiki/List_of_file_signatures)
- [TryHackMe Room](https://tryhackme.com/room/hfb1stolenmount)
