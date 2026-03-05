> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking
> **Type:** Supplemental Reading

---

## netcat (Linux / macOS)

Basic syntax: `nc [options] <host> <port>`

Tries to establish a [[TCP]] connection to the specified host and port. The host can be a domain or [[IP Address]], the port can be a single number or a range.

### Common Options

| Option | Purpose | Example |
|---|---|---|
| `-u` | Open a [[UDP]] connection instead of TCP | `nc -u host 53` |
| `-z` | Zero I/O — scan for open ports without sending data | `nc -z host 1-1000` |
| `-v` / `-vv` | Verbose / very verbose output | `nc -v -z google.com 80` |
| `-p <localport>` | Specify the local source port | Needed when a protocol requires a specific source port |
| `-e <program>` | Execute a program after connection (not supported in all versions) | — |
| `-n` | Skip [[DNS]] lookup — use when working with raw IPs | `nc -n 1.2.3.4 80` |

Options can be combined: `nc -v -z google.com 80` scans port 80 verbosely.

---

## Test-NetConnection (Windows PowerShell)

**Case-sensitive** command. Basic syntax: `Test-NetConnection -ComputerName <host> -Port <port>`

### Common Usage

| Command | Purpose |
|---|---|
| `Test-NetConnection -ComputerName google.com -Port 80` | Test [[TCP]] connectivity to a specific host and port |
| `Test-NetConnection -InformationLevel "Detailed"` | Detailed ping diagnostics (connects to a default Microsoft address) |
| `Test-NetConnection -ComputerName <host> -Port <port> -InformationLevel Detailed` | Combine specific target with detailed output |
| `Test-NetConnection -ComputerName <host> -DiagnoseRouting` | Route diagnostics (may require admin privileges) |

---

**Tags:** #google-it-support #networking #troubleshooting #cli-tools #ports
