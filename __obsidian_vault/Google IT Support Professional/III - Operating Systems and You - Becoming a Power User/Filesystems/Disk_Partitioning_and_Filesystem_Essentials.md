> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 4: Filesystems

---

## Overview

Before adding a [[Filesystem Review|file system]] to a disk, you need to partition it. A **partition** is a logical division of a disk that can be managed independently. When you format a file system onto a partition, it becomes a **volume**.

> ⚠️ **Partition ≠ Volume**: A partition is a raw division of the disk; a volume is a partition that has been formatted with a file system.

---

## Storage Divisions

| Term | Definition |
|---|---|
| **Partition** | Logical division of a physical disk — acts as a separate sub-disk |
| **Volume** | A partition formatted with a file system, accessible by the OS |
| **Cluster** (allocation unit size) | Minimum amount of space a file can occupy on a volume |

---

## Why Partition?

- Gives the **illusion of multiple separate disks** on one physical drive
- Allows **dual-booting** (e.g. Windows on one partition, Linux on another)
- Enables **different file systems** on the same physical disk

---

## Partition Tables

A **partition table** tells the OS how the disk is partitioned — which partitions to boot from, how space is allocated, etc. There are two main schemes:

### MBR – Master Boot Record

| Property | Detail |
|---|---|
| **Age** | Legacy standard |
| **Max volume size** | 2 TB |
| **Partition types** | Primary (max 4), Extended (1 per disk), Logical (inside extended) |
| **Boot compatibility** | Traditional BIOS |

- Only **4 primary partitions** per disk
- To add more: convert one primary to an **extended partition**, then create **logical partitions** inside it
- Slowly being phased out

### GPT – GUID Partition Table

| Property | Detail |
|---|---|
| **Age** | Modern standard |
| **Max volume size** | > 2 TB |
| **Partition types** | Single type — unlimited partitions |
| **Boot compatibility** | Required for **UEFI** booting |

- GPT is the new default for modern systems
- Required if using UEFI firmware (see [[Operating_System_Updates]])

---

## Cluster Size and Space Efficiency

**Cluster size** (allocation unit size) is the smallest unit of storage a file can occupy. A file always takes up at least one full cluster, regardless of its actual size.

**Example (4 KB cluster):**

| File size | Clusters used | Space wasted |
|---|---|---|
| 4.0 KB | 1 cluster = 4 KB | 0 KB |
| 4.1 KB | 2 clusters = 8 KB | 3.9 KB |

> Cluster A (small file, full cluster used) vs. Cluster B (tiny file, most of the cluster wasted) — the image from the course illustrates this trade-off.

**Choosing cluster size:**
- **Small files** → use smaller cluster sizes → less wasted space
- **Large files** → use larger cluster sizes → fewer read operations to assemble a file
- Default cluster size is usually fine; only tune for specific workloads

---

> 📎 See also: [[Filesystem Review]] | [[Disk Partitioning and Formatting (Windows)]] | [[Disk Partitioning and Formatting (Linux)]]

---

**Tags:** #google-it-support #operating-systems #filesystems #storage #partitions #mbr #gpt #uefi
