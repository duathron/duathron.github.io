> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management
> **Type:** Supplemental Reading
> **Sources:**
> - [Installation Package – Microsoft Docs](https://docs.microsoft.com/en-us/windows/win32/msi/installation-package)
> - [App Packager (MakeAppx.exe) – Microsoft Docs](https://docs.microsoft.com/en-us/windows/win32/appxpkg/make-appx-package--makeappx-exe-)
> - [Portable Executables – Microsoft Docs](https://docs.microsoft.com/en-us/windows/win32/debug/pe-format)
> - [Self-Extractor Command Switches – Microsoft Docs](https://docs.microsoft.com/en-us/troubleshoot/windows-client/deployment/command-switches-supported-by-self-extractor-package)

---

## Installation Package (.msi)

The **MSI file** (Microsoft Install file) contains all information the [[Windows Installer]] needs to install software:

- An **installation database**
- **Summary information** about the package
- **Data streams** for each part of the installation
- Optional **internal and external source files**

Windows Installer uses the MSI to handle installation, maintenance, and removal of programs. MSI files are embedded within a **Portable Executable (.exe)**.

---

## Portable Executable (.exe)

The **PE format** (Portable Executable) is a file format specific to Windows. An `.exe` file can contain:

- Computer instructions to execute (e.g. the embedded MSI)
- Images or other resources the program uses
- Compiled machine code

The PE format is the standard wrapper for distributable Windows software.

---

## Self-Extracting Executable

A self-extractor is an `.exe` that runs either via GUI (double-click) or from the command line. Commonly used by IT professionals for deploying software, updates, or hotfixes.

### Command-Line Switches

| Switch | Effect |
|---|---|
| `/extract:[path]` | Extract package contents to specified folder; shows Browse dialog if no path given |
| `/log:[path]` | Enable verbose logging to the specified log file |
| `/lang:lcid` | Set UI language to specified locale (if multiple are available) |
| `/quiet` | Silent mode — no UI shown |
| `/passive` | Runs without user interaction (minimal UI) |
| `/norestart` | Suppresses restart prompt even if required |
| `/forcerestart` | Forces restart immediately after installation |
| `/?` / `/h` / `/help` | Display available options |

---

## App Packager (MakeAppx.exe)

Part of the **Windows SDK** and **Microsoft Visual Studio**. Used primarily by software developers to:

- Create an **app package** (.appx) from files on disk
- Extract files from an existing app package to disk
- Create and extract **app package bundles** (Windows 8.1 and higher)

This tool is not typically used in day-to-day IT support but is relevant when working with UWP app development or enterprise app packaging.

---

## Microsoft Store

The **Microsoft Store** is the primary curated distribution channel for Windows apps:

- Only contains apps certified for compatibility and curated for content
- Software is **updated automatically** by default
- Some organizations **disable the Store** to restrict unauthorized installations

Software not available in the Store can be downloaded directly from developers as `.exe` packages.

---

> 📎 See also: [[Windows Software Packages]]

---

**Tags:** #google-it-support #operating-systems #windows #software #packages #installation #reference
