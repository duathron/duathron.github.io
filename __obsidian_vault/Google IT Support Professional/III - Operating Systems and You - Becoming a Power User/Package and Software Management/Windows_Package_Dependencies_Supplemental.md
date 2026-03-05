> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management
> **Type:** Supplemental Reading

---

## Dynamic Link Libraries (DLL)

**DLL files** are reusable programming modules that make up core Windows functions. Multiple applications can use and reuse the same DLL files simultaneously, which conserves disk space and RAM.

### Common DLL File Types

| Extension | Purpose |
|---|---|
| `.drv` | Device drivers — manage physical devices like printers |
| `.ocx` | ActiveX controls — e.g. calendar date-picker objects |
| `.cpl` | Control Panel files — manage Control Panel functions |

### How DLLs Save Memory

An application can load only the DLL modules it currently needs. For example, if a user never uses the Print function, the printer driver DLL is never loaded into memory — improving overall performance.

---

## DLL Dependencies — What Can Break Them

| Cause | Effect |
|---|---|
| **Overwriting a DLL** | App B installs a newer DLL version, breaking App A which relied on the old version |
| **Deleting DLL files** | Applications or malware remove DLLs needed by other apps |
| **DLL upgrades ("DLL Hell")** | New DLL version installed but other apps not yet updated to be compatible |
| **Rolling back DLL versions** | Reinstalling an older app overwrites a newer DLL, breaking apps that depend on it |

---

## Microsoft's Solutions

### Windows File Protection

- Only applications with **valid digital signatures** are allowed to update or delete system DLL files
- Prevents unauthorized overwrites by apps or malware

### Private DLLs

- Removes the sharing option entirely for sensitive DLLs
- A private copy of the DLL is stored inside the **application's own root folder**
- Changes to the shared system DLL do not affect the app's private copy

### .NET Framework Assembly Versioning

- Allows adding an **updated DLL version without removing the older one**
- Prevents breaking apps that still depend on the old version
- DLL versions are stored in `C:\Windows\assembly` — the **Global Assembly Cache (GAC)**

Each DLL version in the GAC is identified by a **Strong Name Assembly** consisting of:

| Component | Description |
|---|---|
| **Assembly name** | Multiple DLLs can share the same name |
| **Version number** | Differentiates DLL versions |
| **Culture** | Region/country of deployment (or "neutral") |
| **Public key token** | Unique 16-character key assigned at build time |

---

## Side-by-Side Assemblies (SxS)

A **side-by-side assembly** is a public or private resource collection available to applications at runtime. DLLs and dependencies can be located here instead of the Windows registry.

- Stored in: `C:\Windows\WinSxS`
- Use **XML manifest files** instead of registry entries to store configuration
- Private manifests are stored inside the app's folder or embedded in the app itself

### What a Manifest Can Contain

| Element | Description |
|---|---|
| **Names** | Manages file naming conventions |
| **Resource collections** | DLLs, COM servers, Windows classes, interfaces, type libraries |
| **Classes** | Included if versioning is used |
| **Dependencies** | References to other side-by-side assemblies |

> 💡 **IT Support tip:** If an app's configuration settings aren't found in the Windows registry, check the app's side-by-side assembly manifest instead.

---

> 📎 See also: [[Windows Package Dependencies]] | [[Windows Software Packages]]

---

**Tags:** #google-it-support #operating-systems #windows #software #packages #dependencies #dll #security #reference
