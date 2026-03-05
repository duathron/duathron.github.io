> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## Windows

### GUI Editors

| Editor | Notes |
|---|---|
| **Notepad** | Built-in, basic text editing |
| **[Notepad++](https://notepad-plus-plus.org/)** | Open source, supports multiple tabs, syntax highlighting, advanced features |

**Syntax highlighting** displays text in different colors/fonts based on file type, making it easier to read code and configuration files.

### Editing from the CLI

No built-in CLI editor in [[PowerShell]], but you can launch a GUI editor:

```powershell
start notepad++ myfile.txt
```

---

## Linux

### nano

A lightweight CLI text editor available on virtually every Linux distribution.

```bash
nano myfile.txt
```

### Key Shortcuts (inside nano)

| Shortcut | Action |
|---|---|
| `Ctrl+G` | Open help page |
| `Ctrl+O` | Save (write out) |
| `Ctrl+X` | Exit (prompts to save if changes were made) |

The `^` symbol at the bottom of nano means **Ctrl**.

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash #text-editors
