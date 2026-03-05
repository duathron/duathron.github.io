> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 2: Users and Permissions

---

## Overview

File permissions restrict access to files and directories — only those who need access should have it. Permissions are a core building block of [[Computer Security]].

---

## Windows – Access Control Lists (ACLs)

Windows assigns file and directory permissions via **Access Control Lists (ACLs)**. Two types exist:

| Type | Purpose |
|---|---|
| **DACL** (Discretionary Access Control List) | Defines who can access a file/folder and what they're allowed to do |
| **SACL** (System Access Control List) | Instructs Windows to log every access to a file/folder in the event log |

Each file or folder has an **owner** and one or more DACLs.

### Permission Types (Windows)

| Permission | File | Directory |
|---|---|---|
| **Read** | View file contents | List files and subdirectories |
| **Read & Execute** | Read + run executables | Read + execute files in directory |
| **List Folder Contents** | — | Alias for Read & Execute on directories |
| **Write** | Modify file contents | Create subdirectories and write files |
| **Modify** | Read + Execute + Write | Same, applied to directory |
| **Full Control** | All permissions + take ownership + change ACLs | Same |

> **Deny** takes precedence over **Allow** — even if a user is in a group with access, an explicit Deny on their account overrides it.

### Special Groups

| Group | Description |
|---|---|
| **Everyone** | All users including guests |
| **Authenticated Users** | All users with a password — excludes guest accounts |
| **Guest** | Passwordless access; disabled by default |

---

### Viewing Permissions – GUI

Right-click file/folder → **Properties** → **Security** tab

### Viewing Permissions – CLI (`icacls`)

`icacls` = Improved Change ACLs — views and modifies ACLs from the command line.

```powershell
icacls ~\Desktop
```

#### Permission flags in `icacls` output

| Flag | Meaning |
|---|---|
| `F` | Full control |
| `M` | Modify |
| `R` | Read |
| `W` | Write |
| `RX` | Read & Execute |
| `OI` | Object Inherit — new files inherit this DACL |
| `CI` | Container Inherit — new subdirectories inherit this DACL |

### Modifying Permissions – CLI (`icacls`)

> ⚠️ In **PowerShell**, wrap parameters in **single quotes** to prevent misinterpretation of parentheses. In **Command Prompt**, use double quotes for paths instead.

#### Grant permissions

```powershell
# PowerShell
icacls 'C:\Vacation Pictures' /grant 'Devan:(OI)(CI)(M)'

# Command Prompt
icacls "C:\Vacation Pictures" /grant Devan:(OI)(CI)(M)
```

#### Remove permissions

```powershell
icacls 'C:\Vacation Pictures' /remove Everyone
```

---

## Linux – File Permissions

Linux uses three permission types across three user roles.

### Permission Types

| Symbol | Numeric | Permission |
|---|---|---|
| `r` | 4 | Read — view file contents or list directory |
| `w` | 2 | Write — modify file or create files in directory |
| `x` | 1 | Execute — run a program or traverse a directory |

### Reading Permissions (`ls -l`)

```
-rwxrw-r--
```

The 10-character string breaks down as:

| Position | Meaning |
|---|---|
| 1 | File type: `-` = file, `d` = directory |
| 2–4 | Owner permissions |
| 5–7 | Group permissions |
| 8–10 | All other users |

**Example:** `-rwxrw-r--`
- Owner: `rwx` → read, write, execute
- Group: `rw-` → read, write
- Others: `r--` → read only

---

### Changing Permissions (`chmod`)

#### Symbolic format

| Target | Symbol |
|---|---|
| Owner | `u` |
| Group | `g` |
| Others | `o` |

```bash
chmod u+x my_cool_file       # add execute for owner
chmod u-x my_cool_file       # remove execute from owner
chmod u+rx my_cool_file      # add read + execute for owner
chmod ugo+r my_cool_file     # add read for everyone
```

#### Numeric format

Add permission values together for each role:

```bash
chmod 754 my_cool_file
```

| Digit | Role | Permissions | Calculation |
|---|---|---|---|
| `7` | Owner | rwx | 4+2+1 |
| `5` | Group | r-x | 4+1 |
| `4` | Others | r-- | 4 |

---

### Changing Ownership

#### Change file owner (`chown`)

```bash
sudo chown devan my_cool_file
```

#### Change file group (`chgrp`)

```bash
sudo chgrp best_group_ever my_cool_file
```

---

**Tags:** #google-it-support #operating-systems #windows #linux #security #permissions #acl #cli #powershell #bash #cybersecurity
