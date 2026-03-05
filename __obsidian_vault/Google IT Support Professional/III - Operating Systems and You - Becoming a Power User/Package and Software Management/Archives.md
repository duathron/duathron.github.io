> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

An **archive** is one or more files compressed into a single file. Archives are used to bundle software source files, pictures, music, or any other content for easier storage and distribution.

Installing software directly from a source archive is called **installing from source**.

### Common Archive Types

| Extension | Format |
|---|---|
| `.tar` | Tape Archive — common on Linux |
| `.zip` | ZIP — common on Windows, cross-platform |
| `.rar` | RAR — proprietary compression format |

> Different archive types may require different tools or commands to extract.

---

## Windows – 7-Zip (GUI)

**7-Zip** is a popular open-source tool for archiving and extracting many formats (`.zip`, `.rar`, `.tar`, and more).

### Extract an archive

Right-click the archive → **7-Zip** → **Extract Here**

### Create an archive

1. Place files in a folder
2. Right-click the folder → **7-Zip** → **Add to archive**
3. Select format and confirm

---

## Windows – PowerShell (CLI)

Requires **PowerShell 5.0 or greater**.

### Compress (create archive)

```powershell
Compress-Archive -Path "C:\Desktop\Cool Files" -DestinationPath "C:\Desktop\CoolArchive.zip"
```

### Extract (expand archive)

```powershell
Expand-Archive -Path "C:\Desktop\CoolArchive.zip" -DestinationPath "C:\Desktop\Extracted"
```

### Common Parameters

| Parameter | Effect |
|---|---|
| `-Path` | Source files or folder to compress |
| `-DestinationPath` | Output archive file path |
| `-Update` | Add new files to an existing archive |
| `-Force` | Overwrite an existing archive |
| `-CompressionLevel` | `Fastest`, `Optimal`, or `NoCompression` |

> ⚠️ `Compress-Archive` ignores hidden files and folders by default.

---

## Linux – 7-Zip (CLI)

The Linux version of 7-Zip is the package **p7zip-full**. Command: `7z`

### Extract an archive

```bash
7z e <archive_file>
```

The `e` flag stands for **extract**.

---

## Linux – tar (CLI)

`tar` (Tape Archiver) is pre-installed on most Linux distributions and is the standard tool for `.tar` archives.

### Common Flags

| Flag | Purpose |
|---|---|
| `-c` | **Create** a new archive |
| `-x` | **Extract** files from an archive |
| `-t` | **List** contents of an archive (table of contents) |
| `-f` | Specify the archive **filename** (required) |
| `-v` | **Verbose** — show files being processed |
| `-z` | Compress/decompress with **gzip** (`.tar.gz`) |

### Examples

```bash
# Extract a tar archive
tar -xf archive.tar

# Extract a gzip-compressed tar archive
tar -xzf archive.tar.gz

# Create a tar archive
tar -cf new_archive.tar my_folder/

# List contents without extracting
tar -tf archive.tar
```

---

> 📎 See also: [[Archives (Supplemental)]]

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash #archives #packages
