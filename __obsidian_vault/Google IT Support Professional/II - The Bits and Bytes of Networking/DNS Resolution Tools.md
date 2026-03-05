> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## Overview

While the OS handles [[DNS]] lookups automatically, running manual queries is essential for troubleshooting as an IT support specialist.

## nslookup

The most common DNS query tool, available on **Linux, Mac, and Windows**.

### Basic Usage

```bash
nslookup twitter.com
```

Returns the **name server** used for the request and the resolved [[IP Address]] (A record).

### Interactive Mode

Launch by running `nslookup` without arguments. Prompt changes to `>`.

| Command | Effect |
|---|---|
| `server <IP>` | Use a specific name server for all following queries |
| `set type=<record>` | Query a specific record type (default: A). Options: `AAAA`, `MX`, `TXT`, etc. |
| `set debug` | Display full response packets including [[TTL]], intermediary requests, and zone file serial numbers |

### Use Cases

- Verify what IP a domain resolves to
- Test resolution against a specific name server (e.g. [[Public DNS Servers]])
- Query specific [[DNS Record Types]] (MX, TXT, AAAA)
- Deep inspection of DNS responses via debug mode

---

**Tags:** #google-it-support #networking #dns #troubleshooting #cli-tools
