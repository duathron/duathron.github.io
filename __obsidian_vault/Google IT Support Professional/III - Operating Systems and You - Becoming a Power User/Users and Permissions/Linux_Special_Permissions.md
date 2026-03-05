> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 2: Users and Permissions

---

## Overview

Beyond standard [[File Permissions]], Linux has three special permission bits that enable advanced access control scenarios — particularly useful when a user needs to perform a privileged action without being granted full root access.

---

## SetUID (Set User ID)

**Purpose:** Run a file with the permissions of the file's **owner**, regardless of who executes it.

**Use case:** The `passwd` command needs to write to `/etc/shadow`, a file owned by root. Normal users can still change their own password because `passwd` has the setuid bit set — it runs as root whenever executed.

### Identifying SetUID

In `ls -l` output, an `s` appears in place of the owner's execute bit:

```
-rwsr-xr-x
```

The `s` in position 4 (owner execute) indicates setuid is active.

### Setting SetUID

```bash
# Symbolic
chmod u+s my_file

# Numeric — prepend 4 to standard permissions
chmod 4755 my_file
```

---

## SetGID (Set Group ID)

**Purpose:** Run a file with the permissions of the file's **group**, regardless of who executes it.

**Use case:** Programs that need to run as a specific group (e.g. group `tty`) without granting the user full group membership.

### Identifying SetGID

An `s` appears in place of the group's execute bit:

```
-rwxr-sr-x
```

### Setting SetGID

```bash
# Symbolic
chmod g+s my_file

# Numeric — prepend 2 to standard permissions
chmod 2755 my_file
```

---

## Sticky Bit

**Purpose:** Allow anyone to write to a file or directory, but **only the owner or root can delete** content from it.

**Use case:** The `/tmp` directory — all users need to write temporary files there, but no one should be able to delete another user's files.

### Identifying the Sticky Bit

A `t` appears at the end of the permissions string (others' execute position):

```bash
ls -ld /tmp
# drwxrwxrwt
```

The `t` at position 10 indicates the sticky bit is active.

### Setting the Sticky Bit

```bash
# Symbolic
sudo chmod +t my_folder

# Numeric — prepend 1 to standard permissions
sudo chmod 1755 my_folder
```

---

## Quick Reference

| Bit | Symbol | Numeric Prefix | Effect |
|---|---|---|---|
| **SetUID** | `s` (owner execute) | `4` | Execute as file owner |
| **SetGID** | `s` (group execute) | `2` | Execute as file group |
| **Sticky Bit** | `t` (others execute) | `1` | Only owner/root can delete |

### Numeric format pattern

```
chmod [special][owner][group][others] file
#        4/2/1    rwx    rwx    rwx
```

Example: `chmod 4755` = setuid + owner rwx + group r-x + others r-x

---

> 📎 See also: [[File Permissions]] | [[Passwords]] | [[Adding and Removing Users]]

---

**Tags:** #google-it-support #operating-systems #linux #security #permissions #cli #bash #cybersecurity
