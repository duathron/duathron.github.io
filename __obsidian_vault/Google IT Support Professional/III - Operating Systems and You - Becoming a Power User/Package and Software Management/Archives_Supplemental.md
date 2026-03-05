> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management
> **Type:** Supplemental Reading
> **Sources:**
> - [7-Zip Download – 7-zip.org](http://www.7-zip.org/download.html)
> - [Compress-Archive – Microsoft Docs (PowerShell)](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/compress-archive?view=powershell-5.0)
> - [tar – IBM Docs](https://www.ibm.com/docs/en/zvm/7.3?topic=osc-tar-manipulate-tar-archive-files-copy-back-up-file)

---

## 7-Zip

**7-Zip** is a free, open-source file archiver available for Windows and Linux. It supports a wide range of archive formats including `.7z`, `.zip`, `.tar`, `.rar`, `.gz`, and more.

- **Windows:** GUI application + command-line interface
- **Linux:** Package `p7zip-full`, command: `7z`

### 7-Zip CLI — Common Commands

| Command | Effect |
|---|---|
| `7z e <archive>` | Extract files (all to current directory) |
| `7z x <archive>` | Extract with full paths preserved |
| `7z a <archive> <files>` | Add files to an archive |
| `7z l <archive>` | List contents of an archive |
| `7z t <archive>` | Test archive integrity |

---

## Compress-Archive (PowerShell)

Available in **PowerShell 5.0+** via the `Microsoft.PowerShell.Archive` module.

### Syntax

```powershell
Compress-Archive -Path <source> -DestinationPath <output.zip>
```

### Key Parameters

| Parameter | Description |
|---|---|
| `-Path` | File(s) or folder to compress; supports wildcards |
| `-LiteralPath` | Like `-Path` but no wildcard interpretation |
| `-DestinationPath` | Path and filename for the output `.zip` |
| `-Update` | Adds new/changed files to an existing archive |
| `-Force` | Overwrites an existing archive |
| `-CompressionLevel` | `Fastest`, `Optimal` (default), or `NoCompression` |

### Notes

- Uses the .NET `System.IO.Compression.ZipArchive` API — **max file size 2GB**
- Hidden files and folders are **ignored** by default
- Companion cmdlet: `Expand-Archive` for extraction

---

## tar (Linux)

`tar` (Tape Archiver) is the standard Linux archiving tool, pre-installed on virtually all distributions. It supports both plain `.tar` archives and compressed variants (`.tar.gz`, `.tar.bz2`).

### Main Modes

| Flag | Mode |
|---|---|
| `-c` | **Create** a new archive |
| `-r` | **Append** files to the end of an existing archive |
| `-u` | **Update** — append only if file is new or modified |
| `-t` | **List** archive contents |
| `-x` | **Extract** files from an archive |

### Modifier Flags

| Flag | Effect |
|---|---|
| `-f <file>` | Specify archive filename (**required** in most cases) |
| `-v` | Verbose output — shows each file processed |
| `-z` | Use gzip compression (`.tar.gz`) |
| `-C <path>` | Change working directory before operation |
| `-m` | Do not restore modification timestamps on extract |

### Common Usage Examples

```bash
# Create a compressed archive
tar -czf backup.tar.gz my_folder/

# Extract a compressed archive
tar -xzf backup.tar.gz

# List contents without extracting
tar -tf archive.tar

# Append a file to an existing archive
tar -rf archive.tar newfile.txt
```

> ⚠️ `-u` (update) and `-z` (gzip) cannot be combined.

---

> 📎 See also: [[__obsidian_vault/Google IT Support Professional/III - Operating Systems and You - Becoming a Power User/Package and Software Management/Archives]]

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash #archives #packages #reference
