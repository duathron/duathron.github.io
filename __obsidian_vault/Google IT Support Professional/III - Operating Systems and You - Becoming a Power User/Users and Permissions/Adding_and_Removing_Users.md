> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 2: Users and Permissions

---

## Overview

Adding and removing user accounts is a core admin task. Best practice: always set a default password and force the user to change it on first login — so the admin never knows the user's real password.

> 📎 See also: [[Passwords]] | [[Selecting Secure Passwords (Supplemental)]]

---

## Windows

### GUI – Computer Management

#### Add a User

1. Open **Computer Management** → Local Users and Groups
2. Right-click → **New User**
3. Fill in: Username, Full Name, Password
4. Check **"User must change password at next logon"**
5. Click **Create**

#### Remove a User

1. Right-click the username → **Delete**
2. Confirm the warning

> ⚠️ Usernames are unique identifiers tied to a **SID (Security Identifier)**. Deleting a user and recreating them with the same username will **not** restore access to the old user's resources.

---

### CLI – PowerShell

Both `net user` (legacy DOS) and `New-LocalUser` / `Remove-LocalUser` (native PowerShell) can be used. `net user` is simpler; `New-LocalUser` requires scripting.

#### Add a user

```powershell
net user <username> * /add
```

The `*` prompts for a password interactively. Without it, the password is typed in plain text on the command line.

#### Force password change at next logon

```powershell
net user <username> /logonpasswordchg:yes
```

#### Combine: create account + force password change

```powershell
net user <username> <password> /add /logonpasswordchg:yes
```

#### List all local users

```powershell
Get-LocalUser
```

#### Remove a user

```powershell
net user <username> /delete
```

```powershell
Remove-LocalUser <username>
```

Both commands produce the same result.

---

## Linux

#### Add a user

```bash
sudo useradd <username>
```

Sets up basic configurations and creates a **home directory** for the user.

#### Force password change at first login

Combine `useradd` with `passwd -e`:

```bash
sudo useradd <username>
sudo passwd -e <username>
```

#### Remove a user

```bash
sudo userdel <username>
```

#### Verify user was created/removed

```bash
cat /etc/passwd
```

---

## Patterns in CLI Commands

| Action | `net user` | PowerShell Native |
|---|---|---|
| Add | `net user <name> * /add` | `New-LocalUser` |
| Remove | `net user <name> /delete` | `Remove-LocalUser` |
| Change password | `net user <name> *` | — |

Notice the pattern: the base command stays the same, only the **parameter** changes (`/add` → `/delete`). Recognizing these patterns helps you learn new commands faster and recall ones you haven't used in a while.

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash #users #security
