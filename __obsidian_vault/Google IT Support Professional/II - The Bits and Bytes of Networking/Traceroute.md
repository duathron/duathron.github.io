> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## Overview

While [[ping]] tells you *if* you can reach a host, **traceroute** tells you *where* along the path a problem might be. It maps every router hop between source and destination.

## How It Works

Traceroute manipulates the [[TTL]] field at the [[IP Address|IP]] level:

1. Sends a packet with **TTL = 1** → first router decrements to 0 → drops packet → sends [[ICMP]] Time Exceeded back
2. Sends next packet with **TTL = 2** → reaches second router before being dropped
3. Continues incrementing TTL until the packet reaches the **final destination**
4. **3 identical packets** are sent per hop

## Output

Each line shows: **hop number**, **round-trip time** (×3), **IP address**, and **hostname** (if resolvable).

## Platform Differences

| | Linux / macOS | Windows |
|---|---|---|
| **Command** | `traceroute` | `tracert` |
| **Protocol** | [[UDP]] packets to high port numbers | [[ICMP]] Echo Requests |

## Long-Running Alternatives

| Tool | Platform | Behavior |
|---|---|---|
| `mtr` | Linux / macOS | Real-time, continuously updating traceroute |
| `pathping` | Windows | Runs for ~50 seconds, then displays aggregate results |

---

**Tags:** #google-it-support #networking #troubleshooting #cli-tools
