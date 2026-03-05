> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## Root Directory

In Linux, all directories stem from the **root directory**, denoted by `/`. Paths start from root, e.g. `/home/cindy/Desktop` (equivalent to `C:\Users\cindy\Desktop` in Windows).

## Listing Directories: `ls`

```bash
ls /
```

Lists contents of the given path. Without a path, defaults to the current directory.

### Key Directories

| Directory | Purpose |
|---|---|
| `/bin` | Essential binaries/programs (e.g. `ls` itself lives here) — similar to Windows `Program Files` |
| `/etc` | System configuration files |
| `/home` | Personal user directories (documents, pictures, etc.) — similar to Windows `Users` |
| `/proc` | Information about currently running processes |
| `/usr` | User-installed software (not user files) |
| `/var` | System logs and frequently changing files |

### Useful Flags

| Flag | Purpose |
|---|---|
| `-l` | **Long format** — shows permissions, owner, group, size, modification date |
| `-a` | **All** — includes hidden files (prefixed with `.`) |
| `-la` | Combine both — flags can be appended together |

### `ls -l` Output Breakdown (left to right)

File permissions → link count → owner → group → file size → last modified → name

### Getting Help

| Command | Result |
|---|---|
| `ls --help` | Quick reference of all available flags |
| `man ls` | Full manual page (more detailed than `--help`) |

## Hidden Files

Files and directories prefixed with a **dot** (`.`) are hidden by default. Use `ls -a` to reveal them.

---

**Tags:** #google-it-support #operating-systems #linux #cli #filesystem
