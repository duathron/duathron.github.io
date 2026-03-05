> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 2: Users and Permissions

---

## Overview

The simple permissions covered in [[File Permissions]] are actually **sets of special permissions** — more granular controls that can be combined and customized for complex use cases.

---

## Simple vs. Special Permissions

When you set a simple permission like **Read**, Windows enables a specific subset of special permissions behind the scenes:

- List Folder / Read Data
- Read Attributes
- Read Extended Attributes
- Read Permissions
- Synchronize

You can view these in the GUI via: Properties → Security → Advanced → select user → View.

---

## Special Permissions Reference

The following table shows which special permissions are included in each simple permission:

| Special Permission | Full Control | Modify | Read & Execute | List Folder Contents | Read | Write |
|---|---|---|---|---|---|---|
| Traverse Folder / Execute File | ✓ | ✓ | ✓ | ✓ | | |
| List Folder / Read Data | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Read Attributes | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Read Extended Attributes | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Create Files / Write Data | ✓ | ✓ | | | | ✓ |
| Create Folders / Append Data | ✓ | ✓ | | | | ✓ |
| Write Attributes | ✓ | ✓ | | | | ✓ |
| Write Extended Attributes | ✓ | ✓ | | | | ✓ |
| Delete Subfolders and Files | ✓ | | | | | |
| Delete | ✓ | ✓ | | | | |
| Read Permissions | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Change Permissions | ✓ | | | | | |
| Take Ownership | ✓ | | | | | |
| Synchronize | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

> ⚠️ Groups or users with **Full Control** on a folder can delete **any** file in it, regardless of the permissions on that file.

---

## Additional `icacls` Flags

When viewing special permissions via `icacls`, two additional flags appear:

| Flag | Meaning |
|---|---|
| `IO` | Inherit Only — DACL is inherited by children but does **not** apply to the container itself |
| `WD` | Write Data / Create Files |
| `AD` | Append Data / Create Folders |
| `S` | Synchronize |

---

## Practical Example: `C:\Windows\Temp`

A real-world use case where simple permissions aren't enough. This directory must allow all users to create files, but **not** delete each other's files.

**Solution using special permissions:**

- **Users group:** `WD` (create files) + `AD` (create folders) + `S` (synchronize) — no delete access
- **CREATOR OWNER:** Full Control with `IO` — the owner of any file/folder has full control over their own objects only
- **Local Administrators / SYSTEM:** Full Control over everything

This setup is impossible to achieve with simple permissions alone — Modify would grant delete access, which we don't want.

```powershell
icacls C:\Windows\Temp
```

---

## Notes on Inheritance

- **List Folder Contents** is inherited by folders but **not files**
- **Read & Execute** is inherited by both files and folders
- The `IO` flag means a DACL applies to children only, not the directory itself
- The `OI` and `CI` flags from [[File Permissions]] control whether new objects and containers inherit a DACL

> 📎 See also: [[File Permissions]] | [[Special Permissions on Windows (Supplemental)]]

---

**Tags:** #google-it-support #operating-systems #windows #security #permissions #acl #cli #powershell #ntfs #cybersecurity
