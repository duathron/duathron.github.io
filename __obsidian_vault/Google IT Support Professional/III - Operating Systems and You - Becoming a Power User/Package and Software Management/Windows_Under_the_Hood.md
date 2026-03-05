> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

Understanding what happens **under the hood** during software installation helps IT professionals diagnose problems — for example, when a package modifies a configuration file it shouldn't and causes system issues.

> 📎 See also: [[Windows Under the Hood (Supplemental)]]

---

## Custom EXE Installers

When you run an `.exe` that uses a **custom installer** (no MSI, no Windows Installer):

- The installation logic is entirely written by the developer
- Most Windows software is **closed source** — you can't read the source code to see what it does
- You can still observe its behavior using monitoring tools

### Process Monitor (Sysinternals)

**Process Monitor** (`procmon.exe`) is part of the [[Windows Package Dependencies|Microsoft Sysinternals]] toolkit. It shows real-time activity of any running process:

- Files being written or modified
- Registry changes
- Process and thread activity
- Network activity

This is a powerful tool for observing exactly what an installer is doing — even without access to its source code.

---

## MSI-Based Installers

Installation packages using the **MSI format** must conform to a defined set of rules so the Windows Installer can read and execute them.

### What's Inside an MSI File

An MSI is not a simple file — it is a **combination of databases** containing:

| Component | Description |
|---|---|
| **Installation tables** | Instructions for where files go and what actions to take |
| **Files and objects** | The actual program files to be installed |
| **Shortcuts and resources** | Icons, registry entries, etc. |
| **Libraries** | DLLs and other dependencies |

### How Windows Installer Uses the MSI

1. Reads the database tables to determine installation steps
2. Places files and application data in the correct locations
3. **Tracks all actions taken** during installation
4. Creates a **reverse set of instructions** for uninstallation — this is how programs can be cleanly removed

---

## Orca.exe – MSI Inspection Tool

**Orca** is a tool provided by Microsoft (part of the **Windows SDK**) for viewing and editing MSI files. Useful for:

- Inspecting the contents and tables of an MSI package
- Creating or modifying Windows Installer packages
- Troubleshooting installation issues without programming knowledge

---

**Tags:** #google-it-support #operating-systems #windows #software #packages #installation #troubleshooting #sysinternals
