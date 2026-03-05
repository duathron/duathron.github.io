> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## Print Working Directory: `pwd`

Shows the directory you're currently in. When [[PowerShell]] opens, you're usually in your **home directory** (e.g. `C:\Users\Cindy`).

## Change Directory: `cd`

```powershell
cd <path>
```

### Absolute vs. Relative Paths

| Type | Description | Example |
|---|---|---|
| **Absolute** | Full path from the drive letter | `cd C:\Users\Cindy\Documents` |
| **Relative** | Path relative to your current location | `cd Documents` |

### Useful Shortcuts

| Shortcut | Effect |
|---|---|
| `cd ..` | Move **up one level** (parent directory) |
| `cd ..\Desktop` | Go up one level, then into `Desktop` |
| `cd ~` | Jump to your **home directory** |
| `cd ~\Desktop` | Jump to a path relative to home |
| `.` (single dot) | Refers to the **current directory** |

## Tab Completion

Press **Tab** to auto-complete file and directory names. Press Tab repeatedly to cycle through matching options.

- Type `D` + Tab → cycles through `Desktop`, `Documents`, `Downloads`
- Type `De` + Tab → completes to `Desktop` (only match)

---

**Tags:** #google-it-support #operating-systems #windows #cli #powershell #filesystem
