> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] -> Module 4: Filesystems

---

## Overview

Windows provides two ways to partition and format disks: the **Disk Management GUI** and the **DiskPart CLI**. Both accomplish the same tasks -- the CLI is preferred for scripting and remote administration.

> See also: [[Disk Partitioning and Filesystem Essentials]]

---

## Disk Management (GUI)

### Opening Disk Management

Right-click "This PC" -> Manage -> Disk Management (under Storage)

The console shows all disks, partitions, file system types, free/total capacity.

### Formatting a Partition

1. Right-click the target partition -> **Format**
2. Set **Volume label** (name for the drive)
3. Set **File system** (e.g. NTFS)
4. Choose **Allocation unit size** (cluster size -- default is fine in most cases)
5. Choose format type:

| Format Type | Behavior |
|---|---|
| **Quick Format** | Faster -- skips disk error/bad sector scan |
| **Full Format** | Slower -- scans disk for errors and bad sectors |

6. (Optional) Enable **file/folder compression** -- saves disk space but adds CPU overhead for decompression
7. Click OK -> confirm the data-erase warning

---

## DiskPart (CLI)

**DiskPart** is a terminal-based disk management tool. It can create, delete, format, merge, and expand partitions and volumes.

WARNING: DiskPart actions are **permanent**. Be careful not to accidentally wipe the wrong disk.

### Launch DiskPart

Open Command Prompt (cmd.exe) and type: diskpart

A new terminal window opens with the DISKPART> prompt.

### Step-by-Step: Format a USB Drive with NTFS

list disk
  -> Lists all connected disks. Identify the USB drive by its size.

select disk 1
  -> Select the target disk (replace 1 with the correct number).

clean
  -> Removes all partition and volume formatting from the disk.

create partition primary
  -> Creates a new blank partition.

select partition 1
  -> Select the newly created partition.

active
  -> Marks the partition as active (bootable).

format fs=ntfs label=my-thumb-drive quick
  -> Formats the partition with NTFS, assigns a label, uses quick mode.

---

## DiskPart Key Commands Reference

| Command | Purpose |
|---|---|
| list disk | Show all connected disks |
| select disk # | Target a specific disk |
| clean | Wipe all partition/volume data |
| create partition primary | Create a new primary partition |
| select partition # | Target a specific partition |
| active | Mark partition as active |
| format fs=ntfs label=NAME quick | Format with NTFS (quick mode) |
| format fs=fat32 label=NAME quick | Format with FAT32 |
| assign | Assign a drive letter |
| exit | Exit DiskPart |

---

## Mounting

Windows **automatically mounts** formatted drives when they are connected -- they appear immediately under drive letters in File Explorer.

To unmount (safely eject): right-click the drive in File Explorer -> Eject.

---

**Tags:** #google-it-support #operating-systems #windows #filesystems #storage #diskpart #ntfs #cli
