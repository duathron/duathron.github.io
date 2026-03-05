> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management
> **Type:** Supplemental Reading

---

## Key Terms

| Term | Definition |
|---|---|
| **Debian** | Free Linux OS used as the foundation for Ubuntu and other distros |
| **Linux package** | Compressed archive containing binaries, libraries, config files, and dependencies for a software application |
| **Linux repository** | Remote server hosting thousands of packages; must be added to the system before it can be searched |
| **Standalone package** | A package that contains all required files — no external dependencies needed |
| **Package dependency** | A package that other packages rely on to function; often listed in a package manifest rather than bundled |
| **Package manager** | Tool that installs, manages, and removes packages — reads manifests and automatically resolves dependencies |

---

## Common Linux Package Types

| Extension | Format |
|---|---|
| `.deb` | Debian packages |
| `.rpm` | Red Hat packages |
| `.tgz` | TAR archive |

---

## Package Managers by Distribution

### Debian / Ubuntu

| Tool | Type | Notes |
|---|---|---|
| `dpkg` | CLI | Core Debian Package Manager — no dependency resolution |
| `APT` | CLI | Front-end for dpkg; installs dependencies automatically |
| `aptitude` | CLI + menu | User-friendly front-end for APT |
| Synaptic Package Manager | GUI | GTK-based; full package management features |
| Ubuntu Software Center | GUI | Integrated into Ubuntu OS |

### Red Hat / CentOS / Fedora

| Tool | Type | Notes |
|---|---|---|
| `rpm` | CLI | Core Red Hat Package Manager |
| `yum` | CLI | Front-end for rpm; comes with Red Hat |
| `dnf` | CLI | Dandified Yum — modern replacement for yum |

---

## The `dpkg` Command — Extended Reference

| Command | Effect |
|---|---|
| `sudo dpkg --install <package>` | Install a package |
| `sudo dpkg --update-avail <package>` | Update a locally saved package |
| `sudo dpkg --remove <package>` | Remove a package |
| `sudo dpkg --purge <package>` | Remove package **and all associated files** |
| `sudo dpkg --list` | List all installed packages |
| `sudo dpkg --listfiles <package>` | List all files belonging to a package |
| `sudo dpkg --contents <package>` | List contents of a new (not yet installed) package |

### Background Tools

When a `dpkg` action parameter is used, one of two tools runs in the background:

| Tool | Purpose |
|---|---|
| `dpkg-deb` | Manipulates `.deb` files — packs/unpacks contents, provides file info |
| `dpkg-query` | Queries `.deb` files for information |

---

> 📎 See also: [[Linux Package Dependencies]] | [[Linux Software Packages]]

---

**Tags:** #google-it-support #operating-systems #linux #software #packages #dependencies #cli #bash #reference
