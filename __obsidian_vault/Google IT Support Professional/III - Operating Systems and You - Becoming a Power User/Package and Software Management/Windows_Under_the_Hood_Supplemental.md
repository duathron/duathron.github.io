> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management
> **Type:** Supplemental Reading
> **Sources:**
> - [Process Monitor – Microsoft Sysinternals](https://learn.microsoft.com/en-us/sysinternals/downloads/procmon)
> - [Windows Installer Examples – Microsoft Docs](https://learn.microsoft.com/de-de/windows/win32/msi/windows-installer-examples)
> - [Orca.exe – Microsoft Docs](https://learn.microsoft.com/de-de/windows/win32/msi/orca-exe)

---

## Process Monitor (Procmon)

**Process Monitor** (`procmon.exe`) is an advanced real-time monitoring tool from the [[Windows Package Manager|Microsoft Sysinternals]] suite, developed by Mark Russinovich.

### What It Monitors

| Activity Type | Examples |
|---|---|
| **File system** | Files read, written, created, deleted |
| **Registry** | Keys read or modified |
| **Process/thread** | Processes started, threads created |
| **Network** | Connections made by processes |

### Key Features

- **Non-destructive filtering** — set filters without losing captured data
- **Thread stack capture** — helps identify the root cause of an operation
- **Process tree** — shows relationships between all processes in a trace
- **Boot time logging** — can capture activity from system startup
- Scales to tens of millions of events and gigabytes of log data

### IT Support Use Cases

- Monitor what an installer is doing to the file system and registry
- Detect [[Malware]] writing files to unexpected locations
- Troubleshoot application crashes by tracing file or registry access failures

> Available for download at: [Sysinternals Live](https://live.sysinternals.com/Procmon.exe)
> Also available as **Procmon for Linux** on GitHub.

---

## Windows Installer Examples

The **Windows Installer** system uses MSI databases with standardized tables. Microsoft provides examples and documentation covering:

- How installation tables are structured
- How to define file placement, registry entries, shortcuts, and custom actions
- How the installer handles rollback (uninstall) logic

These examples are primarily relevant for developers creating MSI packages, but understanding the structure helps IT professionals troubleshoot complex installation issues.

---

## Orca.exe

**Orca** is a GUI tool for inspecting and editing MSI files, included in the **Windows Software Development Kit (SDK)**.

### Capabilities

| Feature | Description |
|---|---|
| **View MSI tables** | Browse all installation database tables in a structured view |
| **Edit entries** | Modify file paths, registry keys, and other installation parameters |
| **Create packages** | Build new Windows Installer packages from scratch |
| **Validate packages** | Check an MSI for errors against Windows Installer rules |

### When to Use Orca in IT Support

- Inspect what an MSI will install before running it
- Modify an installation path or registry entry in a third-party package
- Diagnose why an MSI installation fails by examining its action tables

> Orca does not require programming knowledge — it provides a straightforward table editor interface.

---

> 📎 See also: [[Windows Under the Hood]] | [[Windows Software Packages]] | [[Windows Package Dependencies]]

---

**Tags:** #google-it-support #operating-systems #windows #software #packages #installation #troubleshooting #sysinternals #reference
