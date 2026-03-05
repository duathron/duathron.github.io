> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

Operating system updates are critical for two reasons: **new features** and **security patches**. A **security patch** is software that fixes a known security hole in the OS. The longer a system goes without patches, the more vulnerable it is to exploitation.

As an IT support specialist, routinely installing OS updates is a core responsibility.

---

## Windows

### Windows Update Client

The **Windows Update client service** runs in the background and periodically checks Microsoft's update servers. When updates are available, it can download and install them automatically or prompt the user for permission. A restart is usually required after installation.

### Update Settings

Navigate to: **Start → search "updates" → Windows Update Settings**

From there you can:
- Check for new updates manually
- View update history
- Configure download and install behavior
- Set a preferred install time

### Windows 7 / 8 – Configurable Update Modes

| Mode | Behavior |
|---|---|
| **Automatic** | Download and install updates automatically |
| **Manual** | User decides whether to download/install each update |
| **Off** | Updates disabled entirely (not recommended) |

### Windows 10 – Cumulative Updates

Windows 10 changed the update model significantly:

| Aspect | Details |
|---|---|
| **Model** | Cumulative — each monthly release supersedes all previous updates |
| **Benefit** | A machine that's been offline for months only needs to download the latest cumulative update |
| **Tradeoff** | Updates are **mandatory** — users cannot opt out or cherry-pick individual updates |

> Microsoft has announced that Windows 7 and 8 are also moving to the cumulative update model.

---

## Linux

### Routine Package Updates

The commands covered in [[Linux Package Manager APT]] update installed packages but do **not** upgrade the core OS:

```bash
sudo apt update      # refresh package index
sudo apt upgrade     # install updated packages
```

### The Linux Kernel

In Linux, the **kernel** is the core of the operating system — analogous to "Windows 10" as a package. The kernel handles:

| Function | Details |
|---|---|
| **Memory management** | Tracks what memory is in use and where |
| **Process management** | Determines which processes get CPU time and for how long |
| **Device drivers** | Acts as interpreter between hardware and processes |
| **System calls & security** | Handles requests from processes |

Like any other package, the kernel receives regular updates containing security patches, new features, and bug fixes.

### Checking Kernel Version

```bash
uname -r
```

Returns the current kernel release version (e.g. `4.1.x-generic`).

### Full System Upgrade (including kernel)

```bash
sudo apt update
sudo apt full-upgrade
```

`full-upgrade` differs from `upgrade` in that it will also upgrade the **kernel** and resolve changing dependencies (adding/removing packages as needed).

After reboot, verify the new kernel is active:

```bash
uname -r
```

### Update Manager (GUI)

Ubuntu also includes a graphical **Update Manager**:

- Checks for **security updates daily** and **non-security updates weekly**
- Opens on the desktop automatically when updates are available
- Can also be triggered manually

---

## Windows vs. Linux: OS Update Comparison

| Aspect | Windows | Linux |
|---|---|---|
| **Update tool** | Windows Update client (background service) | `apt upgrade` / `apt full-upgrade` / Update Manager |
| **Kernel/OS package** | Windows 10 cumulative update | Linux kernel package |
| **Mandatory?** | Yes (Windows 10) | No — user-initiated |
| **Restart required?** | Usually | Yes, after kernel upgrade |
| **GUI option?** | Yes (Settings) | Yes (Update Manager) |

---

> 📎 See also: [[Linux Package Manager APT]] | [[Windows Package Manager]] | [[Linux Devices and Drivers]]

---

**Tags:** #google-it-support #operating-systems #windows #linux #updates #security #kernel #cybersecurity
