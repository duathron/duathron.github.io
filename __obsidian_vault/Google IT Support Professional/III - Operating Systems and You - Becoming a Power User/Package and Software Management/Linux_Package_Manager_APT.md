> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

**APT** (Advanced Package Tool) is the package manager used in Ubuntu. It extends the functionality of `dpkg` by automating dependency installation, simplifying package discovery, and cleaning up unused packages.

> 📎 See also: [[Linux Package Manager (Supplemental)]]

---

## Core APT Commands

### Install a package

```bash
sudo apt install <package>
```

APT automatically resolves and installs all required dependencies. The output shows a summary:

```
0 upgraded, 18 newly installed, 0 to remove and 16 not upgraded.
```

### Remove a package

```bash
sudo apt remove <package>
```

APT also removes dependencies that are no longer needed by any other installed package.

### Update package list

```bash
sudo apt update
```

Refreshes the list of available packages from all configured repositories. Does **not** install or upgrade anything — only updates the index.

### Upgrade installed packages

```bash
sudo apt upgrade
```

Installs available updates for all currently installed packages. Run **after** `apt update` to ensure the latest versions are used.

> ✅ Best practice: always run `sudo apt update` before installing new software or running `apt upgrade`.

### View help

```bash
apt --help
```

Lists all available APT subcommands including list, search, show, and more.

---

## Package Repositories

APT pulls packages from **repositories** — remote servers that act as central storage locations for packages. Ubuntu includes several default repository sources.

### Repository source file

```
/etc/apt/sources.list
```

This file contains the URLs of all configured package repositories. APT checks these locations when searching for packages. Additional repositories must be added here manually or via tools like `add-apt-repository`.

---

## PPAs – Personal Package Archives

**PPAs** are special repositories hosted on **Launchpad** (owned by Canonical Ltd.), allowing open-source developers to distribute software outside of the official Ubuntu repositories.

| Aspect | Details |
|---|---|
| **Hosted on** | Launchpad servers (canonical.com) |
| **Use case** | Distribute newer or custom software not yet in official repos |
| **Security risk** | Less vetted than official Ubuntu repositories — can contain buggy or malicious software |

> ⚠️ Use PPAs with caution. Prefer official developer repositories or Ubuntu's own repos when available.

---

## APT vs. dpkg

| Feature | `dpkg` | `apt` |
|---|---|---|
| Installs `.deb` files | ✓ | ✓ |
| Resolves dependencies | ✗ | ✓ |
| Downloads from repositories | ✗ | ✓ |
| Removes unused dependencies | ✗ | ✓ |

---

**Tags:** #google-it-support #operating-systems #linux #software #packages #package-manager #apt #cli #bash #installation #ubuntu
