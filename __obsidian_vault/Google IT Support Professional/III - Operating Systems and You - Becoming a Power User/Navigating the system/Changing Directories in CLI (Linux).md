> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## Print Working Directory: `pwd`

Same as in [[Changing Directories in CLI (Windows)|Windows]] — shows your current directory path (e.g. `/home/cindy/desktop`).

## Change Directory: `cd`

```bash
cd <path>
```

### Absolute vs. Relative Paths

| Type | Description | Example |
|---|---|---|
| **Absolute** | Full path from root `/` | `cd /home/cindy/documents` |
| **Relative** | Path relative to current location | `cd ../documents` |

### Useful Shortcuts

| Shortcut | Effect |
|---|---|
| `cd ..` | Move **up one level** (parent directory) |
| `cd ../documents` | Go up one level, then into `documents` |
| `cd ~` | Jump to your **home directory** |
| `cd ~/desktop` | Jump to a path relative to home |

## Tab Completion

Works like in Windows, with one difference:

| | Windows (PowerShell) | Linux (Bash) |
|---|---|---|
| **Multiple matches** | Cycles through options one by one | Shows **all matching options at once** |

---

**Tags:** #google-it-support #operating-systems #linux #cli #bash #filesystem
