> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management
> **Type:** Supplemental Reading
> **Sources:**
> - [NuGet – Wikipedia](https://en.wikipedia.org/wiki/NuGet)
> - [Chocolatey Package Repository](https://chocolatey.org/packages)

---

## NuGet

**NuGet** (pronounced "New Get") is the underlying package manager technology that Chocolatey is built on. It is primarily designed for packaging and distributing software written for the **.NET** and **.NET Framework** ecosystems.

### Key Facts

| Property | Detail |
|---|---|
| **Package format** | Single `.nupkg` ZIP file containing .NET assemblies + manifest |
| **Created by** | Outercurve Foundation (originally as "NuPack"), introduced 2010 |
| **Client tool** | `nuget.exe` — free, open-source CLI |
| **IDE integration** | Visual Studio (2012+), Visual Studio for Mac, JetBrains Rider |
| **Build tool support** | MSBuild, .NET Core SDK (`dotnet.exe`) |

### Supported Languages

- .NET Framework packages
- .NET packages
- Native C++ packages (via CoApp)

### Repositories

Developers can publish NuGet packages to:
- **Public repositories** (e.g. nuget.org)
- **Private repositories** (e.g. hosted internally for an organization)

---

## Chocolatey

**Chocolatey** is a Windows package manager built on top of NuGet and PowerShell. It extends NuGet's capabilities to cover general Windows software — not just .NET libraries.

### Public Repository

The [Chocolatey package repository](https://chocolatey.org/packages) hosts thousands of Windows applications available for automated installation. Examples include browsers, developer tools, utilities, and more.

### Use Cases for IT Support

| Scenario | How Chocolatey Helps |
|---|---|
| **Automated deployments** | Script installations across multiple machines |
| **Internal apps** | Host a private Chocolatey repository for company software |
| **Configuration management** | Integrates with SCCM, Puppet, and other tools |
| **Dependency resolution** | Automatically installs required dependencies |

---

> 📎 See also: [[Windows Package Manager]] | [[Windows Package Dependencies]]

---

**Tags:** #google-it-support #operating-systems #windows #software #packages #package-manager #chocolatey #nuget #powershell #reference
