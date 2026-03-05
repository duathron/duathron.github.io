> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

In Linux, everything is treated as a file — including hardware devices. When a device is connected, a **device file** is created in the `/dev` directory. Device drivers are often part of the Linux kernel itself or installed as **kernel modules**.

---

## The /dev Directory

All device files live in `/dev`. Not every file here represents a physical device — some are virtual (e.g. `/dev/null`).

### Common Device Examples

| Path | Device |
|---|---|
| `/dev/sda` | First SCSI/SATA hard drive |
| `/dev/sdb` | Second hard drive (detected after sda) |
| `/dev/sr0` | First optical disk drive |
| `/dev/usb` | USB device |
| `/dev/usbhid` | USB mouse |
| `/dev/usb/lp0` | USB printer |
| `/dev/null` | Discard — data written here is thrown away |

---

## Device Types

In `ls -l` output, the first character indicates the file/device type:

| Symbol | Type |
|---|---|
| `-` | Regular file |
| `d` | Directory |
| `b` | **Block device** |
| `c` | **Character device** |

### Block Devices

Transfer data in **fixed-size blocks**. Examples: hard drives, USB drives, CD-ROMs.

### Character Devices

Transfer data **one character at a time**. Examples: keyboards, mice, monitors, printers.

### Pipe Devices

Similar to character devices, but output goes to a **running process** instead of a display.

### Socket Devices

Allow **multiple processes** to communicate with each other.

---

## Device Managers in Linux

### udev (Automatic)

**udev** is the Linux device manager. It runs a daemon that listens for kernel messages about devices connecting or disconnecting, then automatically creates or removes the corresponding device file in `/dev`.

---

## Drivers in Linux

Unlike Windows, Linux drivers are often **built directly into the kernel**. When you plug in a supported device, it simply works.

For unsupported devices, drivers are installed as **kernel modules** — extensions that add functionality to the kernel without modifying it directly.

> Kernel modules can be installed the same way as any other Linux software (e.g. via `apt`). Note: not all kernel modules are drivers.

---

## Checking Installed Devices – CLI

| Command | Output |
|---|---|
| `ls /dev` | Lists all device files in `/dev` |
| `lspci` | Lists devices on the PCI bus |
| `lsusb` | Lists devices on the USB bus |
| `lsscsi` | Lists SCSI devices (e.g. hard drives) |
| `lpstat -p` | Lists all printers and whether they are enabled |
| `dmesg` | Lists devices recognized by the kernel |

---

## Installing a Printer – GUI (GNOME)

1. Open **Settings** → **Printers**
2. Click **Unlock** (requires sudo/printadmin privileges)
3. Select the printer from the list → click **Add**
4. Open **Printer Details** → choose driver installation method:
   - **Search for Drivers** — automatic search via PackageKit
   - **Select from Database** — manually pick from installed databases
   - **Install PPD File** — use a PostScript Printer Description file

## Installing a Printer – CLI (CUPS)

```bash
lpadmin -p <printername> -m <driverfilename>.ppd
```

- `-p` — add or modify a named printer
- `-m` — specify the PPD driver file (stored in `/usr/share/cups/model/`)
- `man lpadmin` — full command reference

---

> 📎 See also: [[Windows Devices and Drivers]] | [[Linux Under the Hood]]

---

**Tags:** #google-it-support #operating-systems #linux #drivers #hardware #kernel #cli #bash
