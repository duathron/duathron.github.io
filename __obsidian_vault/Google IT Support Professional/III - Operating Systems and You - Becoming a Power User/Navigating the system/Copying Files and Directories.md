> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## GUI

Right-click → **Copy**, then **Paste** — or use hotkeys:

| Hotkey | Action |
|---|---|
| `Ctrl+C` | Copy |
| `Ctrl+V` | Paste |

## CLI: `cp`

### Windows ([[PowerShell]])

```powershell
cp <source> <destination>
```

#### Copying Files

```powershell
cp mycoolfile.txt C:\Users\Cindy\Desktop
```

#### Copying Directories

| Parameter | Purpose |
|---|---|
| `-Recurse` | Copy the directory **and all its contents** (including subdirectories) |
| `-Verbose` | Show one output line per copied file (silent by default) |

```powershell
cp "Bird Pictures" C:\Users\Cindy\Desktop -Recurse -Verbose
```

### Linux (Bash)

```bash
cp <source> <destination>
```

#### Copying Files

```bash
cp my_very_cool_file.txt ~/Desktop
```

#### Copying Directories

Use the `-r` flag (recursive):

```bash
cp -r "cat pictures" ~/Desktop
```

### Wildcards (both platforms)

The **asterisk** (`*`) is a wildcard that matches **any pattern**. Useful for copying multiple files at once.

```bash
cp *.jpg ~/Desktop
```

Copies all `.jpg` files in the current directory to the Desktop.

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash #filesystem
