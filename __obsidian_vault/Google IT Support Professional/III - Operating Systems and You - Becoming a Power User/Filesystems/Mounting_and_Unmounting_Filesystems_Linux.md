> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] -> Module 4: Filesystems

---

## Overview

After partitioning and formatting a disk, the file system must be **mounted** before it can be used. Mounting means making a storage device accessible by attaching it to a directory (the **mount point**) in the file system tree.

> See also: [[Disk Partitioning and Formatting (Linux)]] | [[List Directories in CLI (Linux)]]

---

## Why Mounting Is Necessary

In Linux, devices in /dev are not directories -- you cannot cd into /dev/sdb1 directly. The OS needs to know how to interpret the device file system, and mounting is how you tell it.

---

## Mounting a File System

### Manual Mount



- First argument: the **device** (partition to mount)
- Second argument: the **mount point** (directory where it becomes accessible)

The directory must already exist before mounting.

### Get UUID of a Device



Shows the **UUID** (Universally Unique Identifier) and file system type of each storage device.

---

## Unmounting a File System



Both forms work. Note the command is umount (not unmount).

> Always unmount a drive before physically disconnecting it -- especially USB drives. Failing to do so can cause file system errors.

When the computer **shuts down**, manually mounted file systems are automatically unmounted.

---

## Persistent Mounting: /etc/fstab

Mount points set with the mount command are **temporary** -- they disappear after reboot. To mount a file system **automatically at boot**, add an entry to /etc/fstab.

### fstab Column Structure

| Column | Field | Description |
|---|---|---|
| 1 | **Device** | UUID or device name (e.g. /dev/sda1) |
| 2 | **Mount point** | Directory where device is mounted |
| 3 | **File system type** | e.g. ext4, ntfs, vfat, swap |
| 4 | **Options** | Mount options, comma-separated |
| 5 | **Dump** | Set to 0 (obsolete backup method) |
| 6 | **Pass (fsck order)** | 0 = skip, 1 = root fs (check first), 2 = other partitions |

### Example fstab Entries



### Adding a New Partition to fstab

1. Get the UUID: sudo blkid
2. Open /etc/fstab in a text editor (e.g. nano /etc/fstab)
3. Add a new line with all six fields
4. Reboot and verify the mount point is accessible

---

## Common fstab Mount Options

| Option | Effect |
|---|---|
| defaults | rw, suid, dev, exec, auto, nouser, async |
| auto / noauto | Mount or skip at boot |
| ro / rw | Read-only or read-write |
| nouser | Only root can mount (default) |
| user | Any user can mount; only that user can unmount |
| users | Any user can mount and unmount |
| noexec | Prevent execution of binaries |
| sync / async | Synchronous or asynchronous I/O |

---

## lsblk - View Block Devices



| Column | Meaning |
|---|---|
| NAME | Device name (sda, sda1, sdb, etc.) |
| MAJ:MIN | Major (driver type) and minor (device ID) numbers |
| RM | 0 = not removable, 1 = removable |
| SIZE | Storage capacity |
| RO | 0 = read-write, 1 = read-only |
| TYPE | disk / part / etc. |
| MOUNTPOINT | Where mounted (blank = not mounted) |

---

**Tags:** #google-it-support #operating-systems #linux #filesystems #storage #mount #fstab #cli #bash