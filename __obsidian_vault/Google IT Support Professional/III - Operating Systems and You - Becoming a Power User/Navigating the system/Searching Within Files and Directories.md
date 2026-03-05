> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## Windows

### GUI Options

**Windows Search Service** — indexes files on your computer into a database for fast lookup.

- Enabled by default on Windows 8/10 desktops for the home directory
- By default searches file **names and properties**, not content
- To enable content search: Start → type "Indexing" → Indexing Options → select `Users` → Advanced → File Types tab → select **Index Properties and File Contents**
- Re-indexing time depends on number and size of files

**Notepad++** — use `Ctrl+Shift+F` to open **Find in Files** dialog. Allows searching specific directories, file extensions, and find-and-replace across files.

### CLI: `Select-String` (alias: `sls`)

Searches for text patterns within files. A **string** is how the computer represents text.

```powershell
sls cow farm_animals.txt
```

Search across multiple files using wildcards:

```powershell
sls cow *.txt
```

Output shows: **filename**, **line number**, and **matching line**.

Supports **regular expressions** for advanced pattern matching.

### Searching for Files in Directories (Windows)

Use `ls` with `-Recurse` and `-Filter` to find files matching a pattern:

```powershell
ls "C:\Program Files" -Recurse -Filter *.exe
```

`-Filter` matches file names against a pattern. Combined with `-Recurse`, it searches through all subdirectories.

---

## Linux

### CLI: `grep`

```bash
grep cow farm_animals.txt
```

Search across multiple files:

```bash
grep cow *
```

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash
