> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 2: Users and Permissions

---

## User Types

| Type | Access Level |
|---|---|
| **Standard User** | Restricted — can use the machine but cannot install software or change certain settings |
| **Administrator** | Full control — can view all accounts, modify users, access all files, install software, change system settings |

- A machine can have **multiple administrators**
- On a personal machine, the owner is typically the default administrator
- On public/work machines, the IT support specialist is usually the administrator

## User Isolation

Each user account is **isolated** from others — users cannot see each other's files and folders by default.

## Groups

Users are organized into **groups** based on access levels and permissions. Administrators define what each group is allowed to do.

**Example:** A home computer administrator creates two groups:

- **Parents** — no software installation rights
- **Children** — no software installation rights + child safety restrictions

Groups allow managing permissions for many users at once instead of configuring each user individually.

---

**Tags:** #google-it-support #operating-systems #users #permissions #groups

---

## Windows: Viewing User and Group Information

### Computer Management Tool

Search for **Computer Management** in the Start menu. Key sections:

| Section | Purpose |
|---|---|
| **Task Scheduler** | Schedule programs/tasks to run at specific times |
| **Event Viewer** | System logs storage |
| **Shared Folders** | Folders shared between users on the machine |
| **Local Users and Groups** | User and group management |
| **Performance** | Monitoring CPU, RAM, and other resources |
| **Device Manager** | Manage hardware devices (network cards, monitors, etc.) |
| **Disk Management** | Under Storage — manage disks and partitions |
| **Services and Applications** | Enable/disable system services (e.g. [[DNS]]) |

"Computer Management (Local)" = managing a single machine. In an enterprise, a **Windows domain** connects computers, users, and files to a central database manageable from any domain machine.

### Built-in Accounts

- **Administrator** — full access, disabled by default (dangerous to use permanently)
- **Guest** — limited access built-in account

### User Account Properties

| Option | Purpose |
|---|---|
| **User must change password at next login** | Force password reset (e.g. after compromise) |
| **User cannot change password** | Prevent user from modifying their own password |
| **Password never expires** | Disable password expiration |
| **Account is disabled** | Deactivate the account |
| **Account is locked out** | Block login (e.g. for security reasons) |

### Tabs

- **General** — basic user info and account options
- **Member Of** — shows which groups the user belongs to
- **Profile** — user profile settings (e.g. home folder location)

### UAC (User Account Control)

Instead of being logged into the local administrator account permanently, you can use your own account and approve administrative actions when needed. UAC prompts for confirmation (password) before allowing system changes.

### CLI: Viewing Users and Groups

Much faster than the GUI, especially when checking multiple machines.

| Command | Purpose |
|---|---|
| `Get-LocalUser` | List all user accounts and their enabled/disabled status |
| `Get-LocalGroup` | List all groups on the local machine |
| `Get-LocalGroupMember Administrators` | Show members of a specific group |

Requires **[[PowerShell]] 5.1 or newer**.

> **Note:** These are **local** account commands. Organizations with many Windows machines commonly use **Active Directory** to manage user accounts in a central directory service.

---

## Linux: Viewing User and Group Information

### The Root User

- First user created automatically during Linux installation — the **super user**
- Has **unrestricted access** to the entire OS (similar to the Windows local Administrator account)
- UID is always **0**
- Dangerous to stay logged in as root — risk of accidentally modifying critical files

### sudo and su

| Command | Purpose |
|---|---|
| `sudo <command>` | Run a **single command** as root (similar to Windows UAC) |
| `su` | Switch to another user (defaults to **root** if no user specified) |
| `exit` | Return to your normal user after `su` |

### Key Files

| File | Purpose |
|---|---|
| `/etc/group` | Lists all groups and their members |
| `/etc/passwd` | Lists all user accounts |
| `/etc/sudoers` | Defines who can use `sudo` (root-only readable) |

### `/etc/group` Format

```
sudo:x:27:cindy
```

| Field | Meaning |
|---|---|
| `sudo` | Group name |
| `x` | Password (encrypted, stored separately) |
| `27` | Group ID (GID) — used by the OS instead of group name |
| `cindy` | List of group members |

### `/etc/passwd` Format

```
root:x:0:0:root:/root:/bin/bash
```

| Field (first three) | Meaning |
|---|---|
| `root` | Username |
| `x` | Password (encrypted, stored separately) |
| `0` | User ID (UID) — used by the OS instead of username |

> Most accounts in `/etc/passwd` are **not human users** — they're system accounts needed to run background processes with specific permissions.

---

**Tags:** #google-it-support #operating-systems #users #permissions #groups #windows #linux
