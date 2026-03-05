> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## GUI (Windows)

Right-click → **Delete** — file moves to the **Recycle Bin** (`$Recycle.Bin`). Files can be restored from there. Once the bin is emptied, files are gone permanently.

## CLI: `rm`

**Caution:** `rm` does **not** use the Recycle Bin on either platform. Removed files are gone for good.

### Removing Files

| Platform | Example |
|---|---|
| Windows ([[PowerShell]]) | `rm text1.txt` |
| Linux (Bash) | `rm text1.txt` |

### Removing Directories

Directories contain other files, so the recursive flag is required:

| Platform | Command |
|---|---|
| Windows | `rm <directory> -Recurse` |
| Linux | `rm -r <directory>` |

Without `-Recurse` / `-r`, PowerShell will prompt for confirmation; Bash will return an error.

### Force Removal (Windows)

Some files (e.g. system files) require the `-Force` parameter:

```powershell
rm important_system_file -Force
```

If you lack the necessary **file permissions**, you'll need an administrator account to remove the file.

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash #filesystem
