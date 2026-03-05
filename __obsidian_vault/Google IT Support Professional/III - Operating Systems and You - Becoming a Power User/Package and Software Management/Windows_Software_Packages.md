> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

Developers package software in different ways depending on the target platform and installation method. On Windows, the primary format is the **executable (.exe)**, which follows Microsoft's **Portable Executable (PE)** format. Packages can contain additional resources like images, code, and MSI files.

> 📎 See also: [[Windows Software Packages (Supplemental)]]

---

## Package Types

### .exe – Executable File

The standard Windows software package. Created according to Microsoft's **Portable Executable (PE)** format. An EXE can contain:

- Instructions for the computer to execute
- Images and other resources
- An embedded **MSI file**

### .msi – Microsoft Install Package

Used to guide the **Windows Installer** during installation, maintenance, and removal of software. Contains:

- An installation database
- Summary information
- Data streams for each part of the installation
- Optional internal/external source files

The Windows Installer reads the MSI to handle bookkeeping automatically — but follows strict rules about how software gets installed.

### .appx – Universal Windows Platform App

Introduced with **Windows 8** via the **Microsoft Store**. Apps in this format can run on any compatible Windows device (desktop, tablet). Distributed and updated automatically through the Store.

---

## MSI vs. Custom Installer

| Approach | Pros | Cons |
|---|---|---|
| **MSI + Windows Installer** | Handles bookkeeping, uninstall logic, updates automatically | Strict installation rules — less flexibility |
| **Custom EXE installer** | Full control over installation behavior | Must handle dependencies and uninstall logic manually |

---

## Installing from the GUI

Double-click the `.exe` → follow the installation wizard (either the Windows Installer UI or a custom setup experience).

---

## Installing from the CLI

Run directly from PowerShell or Command Prompt:

```powershell
# By filename (from the same directory)
hello.exe

# By absolute path
C:\Users\Cindy\Desktop\hello.exe
```

### Common CLI Flags (Self-Extracting Packages)

| Flag | Effect |
|---|---|
| `/quiet` | Silent installation — no UI shown |
| `/passive` | No user interaction, but progress bar visible |
| `/norestart` | Suppress automatic reboot prompt |
| `/forcerestart` | Force reboot immediately after install |
| `/extract:[path]` | Extract package contents to a path |
| `/log:[path]` | Enable verbose logging to a file |
| `/?` / `/h` / `/help` | Show available options |

> ⚠️ Flags vary by vendor. Always check with `/?` or the vendor's documentation.

---

## Microsoft Store

The **Microsoft Store** (introduced with Windows 8) is a curated app repository for:

- Universal Windows Platform (UWP) apps
- Games and media

Apps from the Store are certified for compatibility and **updated automatically**. Some organizations disable the Store to prevent unauthorized installations.

---

## When to Use CLI Installation

CLI installation is useful for:

- **Automated deployments** — scripts or configuration management tools
- **Silent installs** — no user interaction required
- **Remote administration** — deploying software across multiple machines

---

**Tags:** #google-it-support #operating-systems #windows #software #packages #cli #powershell #installation
