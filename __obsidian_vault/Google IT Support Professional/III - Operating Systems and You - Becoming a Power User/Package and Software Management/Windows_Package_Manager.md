> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

A **package manager** automates software installation, removal, updates, and dependency management — replacing the manual process of searching, downloading, and running individual installers.

> 📎 See also: [[Windows Package Manager (Supplemental)]]

---

## The Problem with Manual Installation

Without a package manager, managing software on Windows typically requires:

1. Searching the web for the program
2. Navigating to the developer's website
3. Downloading and running an installer
4. Manually checking for and installing updates
5. Using Add/Remove Programs or a custom uninstaller to remove software

This process is slow, error-prone, and difficult to automate across many machines.

---

## Chocolatey

**Chocolatey** is a popular third-party package manager for Windows. It is built on PowerShell and allows installing, updating, and removing software from the command line using a central public repository.

### Key Features

| Feature | Details |
|---|---|
| **Source** | Public Chocolatey repository (`chocolatey.org/packages`) |
| **Custom repositories** | Create private repos for internal company apps |
| **Integration** | Works with configuration management tools like SCCM and Puppet |
| **Underlying technology** | Built on PowerShell and [[Windows Package Dependencies|NuGet]] |

---

## PowerShell Package Management with Chocolatey

Chocolatey can be used directly via the Chocolatey CLI or through PowerShell's built-in package management commandlets after registering Chocolatey as a package source.

### Register Chocolatey as a package source

```powershell
Register-PackageSource -Name chocolatey -ProviderName Chocolatey -Location http://chocolatey.org/api/v2
```

### Find a package and its dependencies

```powershell
Find-Package sysinternals -IncludeDependencies
```

### Install a package

```powershell
Install-Package -Name sysinternals
```

### Verify installation

```powershell
Get-Package -Name sysinternals
```

### Uninstall a package

```powershell
Uninstall-Package -Name sysinternals
```

---

## Commandlet Pattern

All PowerShell package management commands follow the `Verb-Noun` commandlet pattern:

| Commandlet | Purpose |
|---|---|
| `Find-Package` | Search for a package in configured sources |
| `Install-Package` | Install a package and its dependencies |
| `Get-Package` | List installed packages |
| `Uninstall-Package` | Remove an installed package |
| `Get-PackageSource` | List configured package sources |
| `Register-PackageSource` | Add a new package source/repository |

---

**Tags:** #google-it-support #operating-systems #windows #software #packages #package-manager #chocolatey #powershell #cli #installation
