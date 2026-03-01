---
title: "TryHackMe — Confidential"
date: 2026-03-01 00:00:00 +0100
categories:
  - Writeups
  - TryHackMe
tags:
  - confidential
  - easy
published: true
image:
  path: /assets/img/posts/confidential/cover.png
  alt: "Confidential"
---

## Overview

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Room/Machine | Confidential |
| Difficulty | Easy |
| Tags | pdf, forensics, pdfimages, cyberchef, qr-code |

A group of self-declared "black hat hackers" left behind a confidential case file. Inside the PDF: a QR code — partially covered by a red triangle overlay. The mission: uncover the original QR code and read the flag.

This is a short forensic challenge with a single question. No network scanning, no exploitation — just a PDF and the right tool to take it apart. Completed in 22 minutes including AttackBox boot time.

---

## Theory

### PDF Layer Structure

A PDF can contain multiple embedded objects — text, images, vector graphics — layered on top of each other. What looks like a single image when opening the file might actually be several separate images composited together. Forensic tools can extract these layers individually, revealing content that's visually hidden by overlapping elements.

### Poppler Utils

`poppler-utils` is a collection of command-line tools for working with PDF files. I already knew `pdfinfo` from the [Intro to Digital Forensics](https://tryhackme.com/room/introtocyberforensics) room, which is how I guessed there might be related tools on the VM. The key tools:

- `pdfinfo` — displays PDF metadata (producer, creation date, page count, encryption status)
- `pdfimages` — extracts all embedded images from a PDF as separate files
- `pdftotext` — extracts text content

---

## Reconnaissance

### Initial File Inspection

The VM provides `Repdf.pdf` in `~/confidential/`. Opening the PDF shows a single page: a document with a QR code, partially obscured by a red warning triangle.

First step: check the metadata with `pdfinfo`:

```bash
pdfinfo Repdf.pdf
```

<img src="/assets/img/posts/confidential/pdfinfo.png" alt="pdfinfo output showing PDF metadata — Producer: cairo, 1 page, not encrypted" width="700">

The output shows a single-page PDF produced by cairo, not encrypted, no JavaScript, no forms. Nothing suspicious in the metadata itself — the interesting part is in the embedded images.

A quick `strings Repdf.pdf` scan (without filter) also returned nothing useful — no plaintext flag hidden in the file structure.

---

## Data Extraction & Recovery

### Discovering pdfimages via Tab Completion

Knowing that `pdfinfo` is part of the poppler toolset, typing `pdf` and pressing Tab in the terminal revealed the other available tools — including `pdfimages`. This was the key discovery: a tool specifically designed to extract individual images from a PDF.

### Extracting the Layers

```bash
pdfimages Repdf.pdf images
```

This extracts all embedded images with the prefix `images`. The result: three separate `.ppm` files.

<img src="/assets/img/posts/confidential/pdfimages.png" alt="Extracted images — the original PDF page, the clean QR code, and the red triangle overlay as separate files" width="700">

- `images-000.ppm` — the original page background including the QR code, without overlays
- `images-001.ppm` — the red warning triangle (coloured)
- `images-002.ppm` — the warning triangle (black and white)

The PDF composites these layers on top of each other — the triangles cover the QR code when viewed normally. `pdfimages` extracts them as separate files, and `images-000.ppm` contains the clean QR code.

### Decoding the QR Code

Opening `images-000.ppm` reveals the full QR code without any overlay. A quick screenshot of the QR code, then decoded in [CyberChef](https://gchq.github.io/CyberChef/) using **Parse QR Code**:

<img src="/assets/img/posts/confidential/cyberchef-qr.png" alt="CyberChef Parse QR Code operation decoding the extracted QR code to reveal the flag" width="700">

The output is the flag.

### Tools Used

- `pdfinfo` — PDF metadata inspection
- `pdfimages` — image layer extraction
- `strings` — quick plaintext scan (no results)
- **CyberChef** — QR code decoding

---

## Lessons Learned

**Use what's already there.** Knowing one tool from a package (`pdfinfo`) and pressing Tab led directly to the tool that solved the challenge (`pdfimages`). I use Tab completion actively, and in this case it surfaced exactly the right tool without having to search for anything.

**PDFs are containers, not flat images.** What looks like a single page can contain multiple layered objects. A redacted or obscured element in a PDF might just be another image placed on top — extractable with the right tool.

**Prior rooms build on each other.** The connection between this room and [Intro to Digital Forensics](https://tryhackme.com/room/introtocyberforensics) was the hint. `pdfinfo` from that room pointed to the poppler toolset, which contained the solution. TryHackMe's learning paths are structured this way deliberately.

---

## References

- [Poppler Utils Documentation](https://poppler.freedesktop.org/)
- [CyberChef — Parse QR Code](https://gchq.github.io/CyberChef/)
- [TryHackMe Room](https://tryhackme.com/room/confidential)
