> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 2: Users and Permissions
> **Type:** Supplemental Reading
> **Source:** [File and Folder Permissions – Microsoft TechNet](https://technet.microsoft.com/en-us/library/cc732880(v=ws.11).aspx)

---

## Special NTFS Permissions — Full Reference Table

The table below shows which special [[NTFS]] permissions are included in each simple permission. This is the complete mapping used by Windows to translate simple permissions into their underlying access controls.

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

---

## Important Notes

**Full Control and deletion:** Groups or users with Full Control on a folder can delete any file within it, regardless of the permissions set on that file.

**Inheritance difference between List Folder Contents and Read & Execute:**
- **List Folder Contents** is inherited by folders but **not by files** — it should only appear when viewing folder permissions
- **Read & Execute** is inherited by both files and folders, and is always present when viewing file or folder permissions

**Everyone group:** In modern Windows versions, the Everyone group does **not** include the Anonymous Logon group by default. Permissions applied to Everyone do not affect anonymous logon sessions.

---

> 📎 See also: [[Special Permissions on Windows]] | [[File Permissions]]

---

**Tags:** #google-it-support #operating-systems #windows #security #permissions #acl #ntfs #reference #cybersecurity
