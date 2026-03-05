> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking
> **Type:** Supplemental Reading

---

## Software & Hardware Troubleshooting

### File Management (Windows / Linux)

| Windows | Linux | Purpose |
|---|---|---|
| `copy` | `cp` | Copy files between locations |
| `xcopy` | — | Copy with options (`/s` include subdirs, `/j` protect large files) |
| `robocopy` | — | Advanced copy (`/sec` preserves security permissions) |

### Disk Management

| Windows | Linux | Purpose |
|---|---|---|
| `chkdsk` | `fsck` | Check file system for errors (`/f` to repair) |
| `sfc` | — | Scan for and repair corrupted system files |
| `format` | — | Erase and reset a drive |
| `diskpart` | `fdisk` | Manage disk partitions |

### Other Tools

| Command | Purpose |
|---|---|
| `shutdown` (both) | Shut down local or network computers (`/fw` reboots into firmware) |
| `winver` | Display current Windows version |

---

## Networking Troubleshooting

### Network Information

| Windows | Linux | Purpose |
|---|---|---|
| `ipconfig` | `ip` / `ifconfig` | Display network configuration (`/all` for full details) |
| [[ping]] | `ping` | Test connectivity and response time to a host |
| `pathping` | — | Trace route + measure packet loss per hop (runs ~50s) |
| `tracert` | [[Traceroute\|traceroute]] | Trace packet route to destination |
| `hostname` | `hostname` | Display device name on the network |

### Information & Diagnostics

| Command | Purpose |
|---|---|
| `netstat` (both) | Display network activity stats (active/passive sockets) |
| [[DNS Resolution Tools\|nslookup]] (both) | Query [[DNS]] records |
| `net user` | Add, modify, delete, or display user accounts |
| `net use` | Manage connections to shared network resources (`/delete` to remove) |

### Group Policy Management (Windows)

| Command | Purpose |
|---|---|
| `gpupdate` | Update group policy settings |
| `gpresult` | Display Resultant Set of Policy (RSoP) |

---

**Tags:** #google-it-support #networking #troubleshooting #cli-tools #reference
