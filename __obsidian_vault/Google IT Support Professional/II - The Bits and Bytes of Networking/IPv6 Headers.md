> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## Overview

The IPv6 header was designed to be **simpler and shorter** than the IPv4 header, despite addresses being 4× longer. Optional fields are moved into separate **extension headers** chained via the Next Header field.

## IPv6 Header Fields

| Field | Size | Purpose |
|---|---|---|
| **Version** | 4 bits | IP version (same as in IPv4) |
| **Traffic Class** | 8 bits | Type of traffic; enables priority differentiation |
| **Flow Label** | 20 bits | Used with Traffic Class for QoS (Quality of Service) decisions by routers |
| **Payload Length** | 16 bits | Length of the data payload |
| **Next Header** | 8 bits | Identifies the next header in the chain (extension header or upper-layer protocol) |
| **Hop Limit** | 8 bits | Same purpose as [[TTL]] in IPv4 — decremented at each hop |
| **Source Address** | 128 bits | Sender's [[IPv6 Addressing and Subnetting\|IPv6 address]] |
| **Destination Address** | 128 bits | Receiver's IPv6 address |
![[ipv6 header.png]]
## Extension Headers

- Optional fields are **abstracted out** of the main header into separate extension headers
- Each extension header contains its own **Next Header** field, forming a chain
- This keeps the base IPv6 header short and efficient
- If no extension header exists, the data payload follows directly

---

**Tags:** #google-it-support #networking #ipv6 #headers
