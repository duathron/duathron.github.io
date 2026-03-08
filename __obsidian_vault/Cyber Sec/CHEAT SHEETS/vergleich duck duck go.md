## Find command cheatsheet

### Basic usage
- **find [path] [expression]** — search for files starting at path (use . for current directory)

### Common tests
- **-name "pattern"** — name matches shell pattern (case-sensitive)  
- **-iname "pattern"** — name matches, case-insensitive  
- **-type [f|d|l|c|b|p|s]** — file type: f=file, d=dir, l=symlink, c=char dev, b=block dev, p=pipe, s=socket  
- **-size [+N/-N/Nc]** — file size: +N = greater than N, -N = less than N, N = exactly N; suffixes: c=bytes, k=KB, M=MB, G=GB  
- **-mtime [+N/-N/N]** — modified N*24 hours ago: +N = more than N days, -N = less than N days  
- **-mmin / -amin / -cmin** — modified/access/changed minutes  
- **-user USER / -group GROUP** — owner user or group  
- **-perm MODE** — permissions. Use numeric (e.g., 644) or symbolic (u=rwx). Prefix with / for any-match (e.g., -perm /222 means any write bit set).  
- **-empty** — empty file or directory  
- **-regex "pattern"** — match full path with regex (default Emacs regexes); **-regextype TYPE** to choose (e.g., posix-extended)

### Logical operators & grouping
- **-and / -a** — logical AND (implicit between tests)  
- **-or / -o** — logical OR  
- **! expression** or **-not expression** — negate expression  
- Use parentheses to group: **\( expr \)** (escape in shell)

### Actions
- **-print** — print path (default in many implementations)  
- **-print0** — print paths separated by NUL (useful with xargs -0)  
- **-ls** — detailed listing (like ls -dils)  
- **-exec command {} \;** — run command once per matched file; {} is replaced by path; terminate with escaped semicolon  
- **-exec command {} +** — run command with multiple paths at once (more efficient)  
- **-delete** — delete matched files (use with caution; -depth may be needed for dirs)  
- **-quit** — stop after first match

### Using with xargs
- Example: find . -type f -name "*.log" -print0 | xargs -0 gzip
- Prefer **-print0** + **xargs -0** to handle special characters/newlines in names.

### Performance tips
- Specify starting path as narrowly as possible (e.g., find /var/log -type f)  
- Use -prune to skip directories:
  - Exclude dir: find . -path "./node_modules" -prune -o -type f -print
  - Multiple exclusions: find . \( -path "./dir1" -o -path "./dir2" \) -prune -o -print
- Prefer type tests early to reduce work: find . -type f -name "*.txt"
- Use -maxdepth N / -mindepth N to limit depth.

### Examples
- Find files named README.md anywhere under current dir:
  - find . -name "README.md"
- Find all *.py files, case-insensitive:
  - find . -iname "*.py"
- Find empty directories:
  - find . -type d -empty
- Find files larger than 100 MB:
  - find . -type f -size +100M
- Find files modified in last 7 days:
  - find . -type f -mtime -7
- Delete all .tmp files (confirm first):
  - find . -type f -name "*.tmp" -print
  - find . -type f -name "*.tmp" -delete
- Replace spaces with underscores in filenames:
  - find . -depth -name "* *" -execdir bash -c 'for f; do mv -- "$f" "${f// /_}"; done' bash {} +
- Run a command on each file (using -exec):
  - find . -type f -name "*.sh" -exec chmod +x {} \;
- Batch command (efficient):
  - find . -type f -name "*.jpg" -exec jpegoptim {} +
- Find and archive recent files (modified in last 2 days):
  - find . -type f -mtime -2 -print0 | tar --null -T - -czvf recent.tar.gz

### Notes on portability
- GNU find (Linux) supports many extensions (-printf, -iname, -regextype). BSD/Mac find differs (e.g., -print0 supported but -delete present; -regextype may not exist). When writing scripts for portability, prefer POSIX constructs or test on target systems.

### Quick reference table
| Test/Action | Example | Meaning |
|-------------|---------|---------|
| -name | -name "*.txt" | shell pattern match |
| -iname | -iname "*.TXT" | case-insensitive name |
| -type | -type f | file type |
| -size | -size +10M | larger than 10 MiB |
| -mtime | -mtime -30 | modified within 30 days |
| -perm | -perm 644 | exact permission |
| -perm /MODE | -perm /222 | any write bit set |
| -exec ... {} \; | -exec rm {} \; | run per-file |
| -exec ... {} + | -exec rm {} + | batch execution |
| -print0 | -print0 | null-separated output |
| -delete | -delete | delete matched files |
| -prune | -path ./node_modules -prune | skip directory |
| -maxdepth | -maxdepth 2 | limit depth |

## Useful sample commands

### Searching & listing
```bash
# List all regular files under current dir
find . -type f -print

# List all directories only
find . -type d -print

# Show detailed info like 'ls -l' for matches
find . -type f -name "*.conf" -ls
```

### Name and pattern matching
```bash
# Case-insensitive search for Python files
find /projects -iname "*.py"

# Files whose name starts with "test" and ends with .js
find . -type f -name "test*.js"
```

### Time-based
```bash
# Files modified in the last 24 hours
find . -type f -mtime -1

# Files modified within the last 60 minutes
find . -type f -mmin -60

# Files older than 180 days
find /var/log -type f -mtime +180
```

### Size-based
```bash
# Files larger than 500 MB
find / -type f -size +500M

# Files smaller than 1 KB
find . -type f -size -1k
```

### Permissions and ownership
```bash
# Files not writable by owner
find . -type f ! -perm -u=w

# Files owned by user 'alice'
find /home -user alice

# Files with world-writable permission
find . -perm /o=w
```

### Combining tests and grouping
```bash
# Find .txt or .md files
find . \( -iname "*.txt" -o -iname "*.md" \) -print

# Find .log files under /var but exclude /var/log/journal
find /var \( -path "/var/log/journal" -prune \) -o -type f -name "*.log" -print
```

### Actions: exec, delete, print0
```bash
# Make all .sh files executable
find . -type f -name "*.sh" -exec chmod +x {} \;

# Remove all core dumps (confirm first)
find / -type f -name "core.*" -print
find / -type f -name "core.*" -delete

# Compress log files in batches (safe with special chars)
find /var/log -type f -name "*.log" -print0 | xargs -0 gzip
```

### Safe renames and fixes
```bash
# Replace spaces with underscores (uses -depth to handle directories)
find . -depth -name "* *" -execdir bash -c 'for f; do mv -- "$f" "${f// /_}"; done' bash {} +

# Lowercase filenames
find . -depth -name '*[A-Z]*' -execdir bash -c 'for f; do mv -n "$f" "$(tr "[:upper:]" "[:lower:]" <<<"$f")"; done' bash {} +
```

### Archiving and backups
```bash
# Create tar.gz of files modified in last 7 days
find . -type f -mtime -7 -print0 | tar --null -T - -czvf recent7days.tar.gz

# Rsync only files found by find (example: sync .log files)
find . -type f -name "*.log" -print0 | rsync --files-from=- --from0 ./ /backup/
```

### Performance & pruning
```bash
# Skip node_modules and .git (fast)
find . \( -path "./node_modules" -o -path "./.git" \) -prune -o -type f -name "*.js" -print

# Limit search depth to 2
find /etc -maxdepth 2 -type f -name "*.conf"
```

### Advanced: regex and regextype (GNU find)
```bash
# Use POSIX extended regex to match .c or .cpp files
find . -regextype posix-extended -regex '.*\.(c|cpp)$'

# Match paths containing a UUID-like pattern
find . -regextype posix-extended -regex '.*[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}.*'
```

### One-liners for common tasks
```bash
# Count number of files under current dir
find . -type f | wc -l

# Total size of *.log files (in human-readable)
find . -type f -name "*.log" -print0 | du -ch --files0-from=-
```
