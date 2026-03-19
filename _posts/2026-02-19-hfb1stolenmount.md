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
related_notes:
  - "[[Wireshark]]"
  - "[[Network Forensics]]"
  - "[[PCAP Analysis]]"
image:
  path: /assets/img/posts/hfb1stolenmount/cover.png
  alt: "Hack From the Back 1: Stolen Mount"
---

An intruder has infiltrated the network and targeted the NFS server where backup files are stored. A classified secret was accessed and stolen. The only evidence left behind is a packet capture (PCAP) file recorded during the incident. The mission: analyse the capture and discover the contents of the stolen data.

This is a purely forensic challenge — no exploitation, no shells. It's a **Network Traffic Analysis (NTA)** exercise: the entire room is solved by analysing captured traffic in Wireshark, recovering exfiltrated data, and decoding the stolen secret.

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Hack From the Back 1: Stolen Mount |
| Difficulty | Easy |
| Tags | wireshark, pcap, nfs, nta, network-forensics, cyberchef |

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

### CyberChef

[CyberChef](https://gchq.github.io/CyberChef/) is a web-based data analysis tool developed by GCHQ. It provides hundreds of operations that can be chained together in a drag-and-drop interface — encoding/decoding, hashing, compression, parsing, and format conversion. In this room it's used for QR code decoding, but in practice it's indispensable for CTFs and forensic analysis alike.

---

## Reconnaissance

### Initial Triage

The virtual machine provides `challenge.pcapng` on the desktop. After opening it in Wireshark, sorting by **Length** immediately highlights an anomaly: **Frame 286** stands out at **986 bytes** — significantly larger than the rest.

### Identifying the Payload

Inspecting Frame 286 reveals two things:

1. The string **`secret.PNG`** appears in the NFS data.
2. The payload starts with **`50 4b 03 04`** — the magic bytes for a **ZIP archive**. Despite the `.PNG` filename, the actual data is a ZIP.

<img src="/assets/img/posts/hfb1stolenmount/magic-bytes.png" alt="Wireshark hex pane showing ZIP magic bytes 50 4b 03 04" width="700">

> **Tip:** Magic bytes identify a file's format regardless of its extension. `50 4b` = ZIP, `89 50 4e 47` = PNG, `ff d8 ff` = JPEG.

---

## Enumeration

### Extracting the ZIP from the PCAP

With Frame 286 identified, expand the NFS tree down to **READ_PLUS → Contents → Content Type: Data → contents: \<DATA\>**, right-click → **Export Packet Bytes**, save with a `.zip` extension.

The exported file is a valid ZIP archive — but it's password protected.

### Finding the Password in the Traffic

**Directory listing via READDIR (opcode 26):** The NFS share contains `secret.PNG`, `hidden_stash.zip`, and `creds.txt`.

**File read via READ_PLUS (opcode 68):** Packet 214 reveals `creds.txt`:

```
Archive Password
90############################f2 (md5)
```

<img src="/assets/img/posts/hfb1stolenmount/creds-md5.png" alt="Packet 214 showing creds.txt contents with MD5 hash" width="700">

### Cracking the MD5 Hash

Submitting the hash to [CrackStation](https://crackstation.net/) instantly returns the plaintext. CrackStation uses precomputed lookup tables — MD5 of common words is effectively just obfuscation.

---

## Data Extraction & Recovery

### Step 1: Unlock the ZIP

```bash
unzip -P '[redacted]' secret.zip
```

The archive contains `secret.PNG` — a QR code image.

### Step 2: Decode the QR Code

1. Open [CyberChef](https://gchq.github.io/CyberChef/)
2. Drag `secret.PNG` into the input field
3. Add the **Parse QR Code** operation

The decoded output is the flag.

> **Why not scan with a phone?** Unknown QR codes could point to malicious URLs. CyberChef processes the image client-side.

### Tools Used

- **Wireshark** — PCAP analysis, packet inspection, payload extraction
- **CrackStation** — MD5 rainbow table lookup
- **CyberChef** — QR code decoding

---

## Lessons Learned

**Sort by size first.** File transfers produce larger packets than protocol handshakes. The single 986-byte packet immediately pointed to the target.

**Know your magic bytes.** The filename said `.PNG`, the hex said `50 4b 03 04`. File extensions can lie; magic bytes don't.

**Unencrypted protocols are forensic goldmines.** NFS transmits everything in cleartext — file contents, directory listings, and credentials.

**MD5 is not a security mechanism.** A hash reversible via lookup table adds obfuscation, not security.

**Tool mastery transfers across protocols.** NFS was unfamiliar going in, but the methodology — inspect packets, identify patterns, extract data — is identical for HTTP, FTP, or SMB.

---

## References

- [Wireshark Documentation — Export Packet Bytes](https://www.wireshark.org/docs/wsug_html_chunked/ChAdvExportObjects.html)
- [CyberChef — Parse QR Code](https://gchq.github.io/CyberChef/)
- [CrackStation — Hash Lookup](https://crackstation.net/)
- [NFS Protocol Overview — RFC 7530](https://www.rfc-editor.org/rfc/rfc7530)
- [List of File Signatures (Magic Bytes)](https://en.wikipedia.org/wiki/List_of_file_signatures)
- [TryHackMe Room](https://tryhackme.com/room/hfb1stolenmount)
