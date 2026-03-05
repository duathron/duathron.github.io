> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 4: Filesystems

---

## Overview

In Linux, disk partitioning is done with the `parted` tool, which supports both **MBR** and **GPT** partition tables. After partitioning, the file system is created with `mkfs`.

> ⚠️ Always be careful to select the correct disk in `parted` — changes are applied immediately and can cause data loss.

> 📎 See also: [[Disk Partitioning and Filesystem Essentials]] | [[Mounting and Unmounting Filesystems (Linux)]]

---

## Viewing Connected Disks

Use `parted -l` (list mode) to see all connected disks and their partitions:

```bash
sudo parted -l
```

### Reading parted -l Output

| Field | Meaning |
|---|---|
| **Partition table** | gpt or msdos (MBR) |
| **Number** | Partition number (e.g. 1 → `/dev/sda1`) |
| **Start / End** | Where the partition begins and ends on disk |
| **Size** | Partition size |
| **File system** | Formatted file system type |
| **Name** | Partition name/label |
| **Flags** | e.g. boot, esp |

### Identifying Disks

| Device | Meaning |
|---|---|
| `/dev/sda` | First detected mass storage device |
| `/dev/sdb` | Second detected mass storage device |
| `/dev/sda1` | First partition on sda |
| `/dev/sdb1` | First partition on sdb |

---

## Interactive Mode: `parted /dev/sdb`

Launch interactive mode to work on a specific disk:

```bash
sudo parted /dev/sdb
```

Prompt changes to `(parted)`. Type `quit` to exit back to the shell.

### Key Interactive Commands

| Command | Purpose |
|---|---|
| `print` | Show current disk info and partition table |
| `mklabel gpt` | Create a GPT partition table (wipes existing table) |
| `mklabel msdos` | Create an MBR partition table |
| `mkpart primary ext4 1MiB 5GiB` | Create a partition (see below) |
| `quit` | Exit interactive mode |

### mkpart Syntax

```
mkpart <type> <filesystem> <start> <end>
```

| Field | Notes |
|---|---|
| **type** | `primary` for GPT (MBR uses primary/extended/logical) |
| **filesystem** | Hint only — actual formatting is done with `mkfs` |
| **start / end** | Use MiB/GiB for precise measurements (see note below) |

> **MiB vs. MB:** Use **mebibytes (MiB)** and **gibibytes (GiB)** for exact storage measurements. 1 KiB = 1024 bytes; 1 KB = 1000 bytes. Precise units avoid wasted space.

**Example — create a 5 GiB partition:**

```bash
(parted) mkpart primary ext4 1MiB 5GiB
```

---

## Formatting the Partition: `mkfs`

After creating a partition with `parted`, format it with a file system using `mkfs`:

```bash
sudo mkfs -t ext4 /dev/sdb1
```

| Flag | Purpose |
|---|---|
| `-t` | Specify file system type (e.g. `ext4`, `ntfs`, `fat32`) |

> `mkfs` is a separate step from `parted` — the file system type specified in `mkpart` is just a label hint, not the actual formatting.

---

**Tags:** #google-it-support #operating-systems #linux #filesystems #storage #partitions #parted #cli #bash
