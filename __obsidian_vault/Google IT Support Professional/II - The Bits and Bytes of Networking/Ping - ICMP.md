> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## ICMP – Internet Control Message Protocol

[[ICMP]] is used by routers and remote hosts to communicate **why a transmission has failed** back to the source. It is not designed for direct human interaction — it enables automated error reporting between networked devices.

### ICMP Packet Structure

| Field | Size | Purpose |
|---|---|---|
| **Type** | 8 bits | Category of message (e.g. Destination Unreachable, Time Exceeded) |
| **Code** | 8 bits | Specific reason within the type (e.g. Network Unreachable vs. Port Unreachable) |
| **Checksum** | 16 bits | Integrity verification |
| **Rest of Header** | 32 bits | Optional additional data depending on type/code |
| **Data Payload** | variable | Contains the full [[IP Address|IP]] header + first 8 bytes of the offending packet's data — so the sender knows which transmission caused the error |

---

## Ping

A simple tool available on all major operating systems that uses ICMP to test connectivity.

### How It Works

1. Sends an **ICMP Echo Request** to the destination ("are you there?")
2. If reachable, the destination responds with an **ICMP Echo Reply**

### Usage

```bash
ping <IP or FQDN>
```

### Output (per line)

- Address of the replying host
- **Round-trip time**
- [[TTL]] remaining
- ICMP message size in bytes
- Final statistics: packets sent/received, packet loss %, average round-trip time

### Platform Differences

| | Linux / macOS | Windows |
|---|---|---|
| **Default behavior** | Runs until interrupted (`Ctrl+C`) | Sends 4 echo requests |

---

**Tags:** #google-it-support #networking #icmp #troubleshooting #cli-tools
