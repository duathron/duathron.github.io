> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## GUI (Windows)

Double-click a file to open it in its default application (e.g. Notepad for `.txt`). Change the default via right-click → **Properties** → **Open with**.

## Viewing File Contents

### `cat` (both platforms)

Dumps the entire file content into the shell. Short for **concatenate**.

```bash
cat important_document.txt
```

Not ideal for large files — output scrolls without pausing.

### Paging Through Files

| Platform | Command | Notes |
|---|---|---|
| Windows ([[PowerShell]]) | `more <file>` | Pauses at each terminal page |
| Linux (Bash) | `less <file>` | More functionality than `more`; preferred in Linux |

#### Navigation Keys

| Key | `more` (Windows) | `less` (Linux) |
|---|---|---|
| **Enter** | Advance one line | Advance one line |
| **Space** | Advance one page | Advance one page |
| **Up/Down** | — | Scroll line by line |
| **Page Up/Down** | — | Scroll page by page |
| **g** | — | Jump to beginning |
| **G** | — | Jump to end |
| **/ + word** | — | Search within file |
| **q** | Quit | Quit |

### Head & Tail

View only the first or last lines of a file (default: 10 lines each).

| | Windows (PowerShell) | Linux (Bash) |
|---|---|---|
| **First lines** | `cat <file> -Head 10` | `head <file>` |
| **Last lines** | `cat <file> -Tail 10` | `tail <file>` |

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash #filesystem
