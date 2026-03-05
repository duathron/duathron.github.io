> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## Command Line Interfaces on Windows

Windows offers two CLIs:

| CLI | Executable | Notes |
|---|---|---|
| **Command Prompt** | `cmd.exe` | Legacy, similar to MS-DOS |
| **[[PowerShell]]** | `powershell.exe` | Supports all Command Prompt commands + many more; used in this course |

Many PowerShell commands are **aliases** — nicknames that map to commands from other shells (e.g. `ls` is an alias for `Get-ChildItem`).

## Listing Directories: `ls`

```powershell
ls C:\
```

Lists all directories and files at the given path. The path is a **parameter** — a value associated with a command.

### Useful Parameters

| Parameter | Purpose |
|---|---|
| `-Force` | Show **hidden and system files** (e.g. `$Recycle.Bin`, `ProgramData`) |

### Getting Help

| Command | Result |
|---|---|
| `Get-Help ls` | Brief summary of parameters |
| `Get-Help ls -Full` | Detailed descriptions + usage examples |

## Key Directories on the C: Drive

| Directory | Purpose |
|---|---|
| `Program Files` / `Program Files (x86)` | Installed applications and programs |
| `Users` | User profile / home directories (one per user) |
| `Windows` | Windows OS installation files |
| `ProgramData` (hidden) | Data for programs installed in Program Files |
| `$Recycle.Bin` (hidden) | Files moved to the Recycle Bin are stored here |

## Parent & Child Directories

A **parent directory** contains other directories; those are its **child directories**. Example: if `Dogs/Corgi/` exists, `Dogs` is the parent and `Corgi` is the child.

---

**Tags:** #google-it-support #operating-systems #windows #cli #powershell #filesystem
