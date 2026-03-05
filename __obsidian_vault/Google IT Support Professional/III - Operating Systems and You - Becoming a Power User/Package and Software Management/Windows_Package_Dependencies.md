> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

Software packages usually rely on other pieces of code to function. This is called having **dependencies** — one piece of software depends on another to work correctly.

> 📎 See also: [[Windows Package Dependencies (Supplemental)]]

---

## Dependencies & Libraries

A **library** is a bundle of reusable code written by someone else that other programs can tap into. In Windows, shared libraries are called **Dynamic Link Libraries (DLLs)**.

### Why DLLs?

- The same DLL can be used by multiple programs simultaneously
- Shared code doesn't need to be loaded into memory separately for each app → **less RAM usage**
- Updates to a DLL apply once and benefit all programs that use it

---

## How Windows Manages Dependencies

Windows installation packages (`.exe` / `.msi`) typically bundle:

- All required **DLL files** and other resources
- An **MSI file** that tells the Windows Installer how to assemble everything

The Windows Installer handles placing dependencies correctly and ensures they're available to the program after installation.

---

## DLL Hell (Legacy Problem)

In older Windows versions, a common problem arose:

1. App A uses `graphics.dll` v1.0
2. App B installs and overwrites `graphics.dll` with v2.0
3. App A breaks — it doesn't know how to use the new DLL version

This was known as **DLL Hell**.

---

## Side-by-Side Assemblies (SxS)

Modern Windows solves DLL Hell using **Side-by-Side Assemblies (SxS)**:

- Shared libraries are stored in `C:\Windows\WinSxS`
- Apps specify which version of a library they need via a **manifest file**
- Windows loads the correct version automatically
- **Multiple versions of the same DLL** can coexist without conflict

---

## Package Management in PowerShell

Windows has a built-in **Package Manager** accessible via PowerShell commandlets:

| Commandlet | Purpose |
|---|---|
| `Find-Package` | Search for a package and its dependencies |
| `Install-Package` | Install a package |
| `Get-PackageSource` | List configured package sources |
| `Register-PackageSource` | Add a new package source/repository |

> A **commandlet** is a PowerShell command in the `Verb-Noun` format (e.g. `Get-Help`, `Select-String`).

### Example: Installing Sysinternals via Chocolatey

The default PowerShell package source is the **PowerShell Gallery**. To install packages from other repositories, you need to register them first.

#### 1. Add Chocolatey as a package source

```powershell
Register-PackageSource -Name chocolatey -ProviderName Chocolatey -Location http://chocolatey.org/api/v2
```

#### 2. Verify available sources

```powershell
Get-PackageSource
```

#### 3. Find a package and its dependencies

```powershell
Find-Package sysinternals -IncludeDependencies
```

#### 4. Install the package

```powershell
Install-Package sysinternals
```

---

**Tags:** #google-it-support #operating-systems #windows #software #packages #dependencies #powershell #cli #installation
