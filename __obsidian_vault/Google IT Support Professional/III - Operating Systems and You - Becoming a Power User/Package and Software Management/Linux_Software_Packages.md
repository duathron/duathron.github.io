> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

Linux has many different distributions, each potentially using different package formats. Package types vary by distro — knowing which format a distro uses is essential for software management.

| Distribution | Package Format |
|---|---|
| **Red Hat / CentOS / Fedora** | `.rpm` (Red Hat Package Manager) |
| **Debian / Ubuntu** | `.deb` (Debian Package) |

This course focuses on **Debian packages** as used in Ubuntu.

---

## Debian Packages (`.deb`)

Standalone `.deb` files are used when developers distribute software directly on their websites rather than through a central repository. To work with them, the `dpkg` (**Debian Package**) command is used.

### Install a Package

```bash
sudo dpkg -i <package.deb>
```

The `-i` flag stands for **install**.

### Remove a Package

```bash
sudo dpkg -r <package_name>
```

The `-r` flag stands for **remove**.

### List All Installed Packages

```bash
dpkg -l
```

The `-l` flag lists all installed Debian packages. Output can be lengthy — pipe it to [[Searching Within Files and Directories|grep]] to filter results.

### Search for a Specific Package

```bash
dpkg -l | grep <search_term>
```

Uses the [[Input Output and the Pipeline|pipeline]] to pass `dpkg -l` output into `grep`, filtering for matching package names.

**Example:**

```bash
dpkg -l | grep atom
```

Returns all installed packages with "atom" in the name.

---

## Key Flags Summary

| Flag | Purpose |
|---|---|
| `-i` | Install a `.deb` package |
| `-r` | Remove an installed package |
| `-l` | List all installed packages |

---

**Tags:** #google-it-support #operating-systems #linux #software #packages #cli #bash #installation
