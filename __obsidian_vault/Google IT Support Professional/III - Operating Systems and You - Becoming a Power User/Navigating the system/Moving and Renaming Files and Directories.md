> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## GUI (Windows)

Right-click → **Rename**

## CLI: `mv`

The `mv` (move) command handles both **renaming** and **moving** files and directories on both platforms.

### Renaming

| Platform | Example |
|---|---|
| Windows ([[PowerShell]]) | `mv blue_document yellow_document` |
| Linux (Bash) | `mv red_document blue_document` |

Renaming = moving a file to a new name **within the same directory**.

### Moving to Another Directory

```bash
mv yellow_document C:\Users\Cindy\Documents    # Windows
mv blue_document ~/Documents                     # Linux
```

### Using Wildcards

Move multiple files at once with the `*` wildcard:

```bash
mv *_document ~/Desktop
```

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash #filesystem
