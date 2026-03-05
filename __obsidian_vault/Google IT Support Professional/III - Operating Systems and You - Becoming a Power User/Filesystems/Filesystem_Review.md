> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 4: Filesystems

---

## Overview

A **file system** is used to keep track of files and file storage on a disk. Without a file system, the OS wouldn't know how to organize files. Any new storage device must have a file system added to it before it can be used.

---

## Default File Systems by OS

| Operating System | Recommended File System |
|---|---|
| **Windows** | NTFS |
| **Linux (Ubuntu)** | ext4 |
| **Cross-platform** | FAT32 |

---

## Cross-OS Compatibility

File systems have limited cross-OS compatibility. This is a common scenario in IT support:

| File System | Windows | Linux (Ubuntu) | macOS |
|---|---|---|---|
| **NTFS** | ✓ read/write | ✓ read/write | Read-only (without third-party tools) |
| **ext4** | ✗ (without third-party tools) | ✓ read/write | ✗ |
| **FAT32** | ✓ read/write | ✓ read/write | ✓ read/write |

> If you need a USB drive that works across Windows, Linux, and macOS — reformat it with **FAT32**.

---

## FAT32 Limitations

FAT32 offers universal compatibility but with significant constraints:

| Limitation | Detail |
|---|---|
| **Max file size** | 4 GB per file |
| **Max volume size** | 32 GB |

This makes FAT32 suitable for small USB drives but not for general-purpose storage.

---

> 📎 See also: [[Disk Partitioning and Filesystem Essentials]] | [[Disk Partitioning and Formatting (Windows)]] | [[Mounting and Unmounting Filesystems (Linux)]]

---

**Tags:** #google-it-support #operating-systems #filesystems #ntfs #ext4 #fat32 #storage
