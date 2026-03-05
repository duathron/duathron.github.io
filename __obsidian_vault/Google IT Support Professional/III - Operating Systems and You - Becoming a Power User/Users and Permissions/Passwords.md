> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 2: Users and Permissions

---

## Overview

Passwords add security to user accounts. Only the account owner should know their own password — even an admin managing other accounts **should not know users' passwords**. Instead, force the user to set their own password on first login.

---

## Windows

### GUI – Computer Management

1. Open **Computer Management** → Local Users and Groups
2. Right-click on a username → **Properties**
3. Check **"User must change password at next logon"** → Apply → OK
4. The user is forced to set a new password on their next login

To manually set a password (e.g. if the user forgot it):
- Right-click the username → **Set Password**
- ⚠️ This may cause the user to lose access to certain stored credentials

### CLI – PowerShell (`net user`)

`net user` is a legacy DOS-style command. Use `/?` for help.

#### Change a password

```powershell
net user <username> *
```

The `*` causes `net` to **prompt** for the password interactively — the password is never visible on screen or in logs. This is preferred over typing the password directly in the command, as it avoids:
- Shoulder surfing (someone reading the screen)
- Logging (commands are often recorded in log files sent to central services)

#### Force password change at next logon

```powershell
net user <username> /logonpasswordchg:yes
```

This mirrors the GUI approach — the admin does not learn the user's password. The user sets it themselves at next login.

> 📎 See also: [[Selecting Secure Passwords (Supplemental)]]

---

## Linux

### Change your own password

```bash
passwd
```

Passwords are stored in **`/etc/shadow`** — a special, encrypted (hashed) file readable only by root. Even with access, the hashes cannot be reversed.

### Force a user to change their password

```bash
passwd -e <username>
```

The `-e` (expire) flag immediately expires the user's password. On their next login, they will be required to set a new one.

---

## Key Principles

| Principle | Details |
|---|---|
| **Admins shouldn't know user passwords** | Use forced password change at next logon instead |
| **Never type passwords in plain text on the CLI** | Use `*` with `net user` to avoid logging and shoulder surfing |
| **Passwords are hashed, not stored in plain text** | Linux uses `/etc/shadow`; Windows uses NTLM hashes |

---

**Tags:** #google-it-support #operating-systems #windows #linux #security #passwords #users
