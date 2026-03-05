> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## Why IPv6?

[[IANA]] has exhausted the IPv4 address space. IPv4 uses 32-bit addresses (~4.2 billion addresses) — not enough for today's internet-connected devices. IPv6 was developed in the mid-1990s to solve this.

> IPv5 was an experimental protocol (connection-oriented) that never saw wide adoption. The name was skipped to avoid confusion.

## IPv6 Addresses

- **128 bits** in size → 2¹²⁸ possible addresses (~3.4 × 10³⁸ — an undecillion)
- Written as **8 groups of 4 hexadecimal digits**, separated by colons
- Example: `2001:0db8:0000:0000:0000:0000:0000:0001`

### Shortening Rules

1. **Remove leading zeros** in each group → `2001:db8:0:0:0:0:0:1`
2. **Replace consecutive all-zero groups** with `::` (only once per address) → `2001:db8::1`

**IPv6 loopback address:** `::1` (full form: 31 zeros followed by a 1)

## Reserved Address Ranges

| Prefix | Purpose |
|---|---|
| `2001:0db8::/32` | Documentation and education |
| `FF00::` | [[Multicast]] — addressing groups of hosts |
| `FE80::` | Link-local unicast — local segment communication |

### Link-Local Addresses (FE80::)

- Used for local network configuration (similar to [[DHCP]] in IPv4)
- Host ID derived from [[MAC Address]]: 48-bit MAC → algorithm → unique 64-bit number → inserted into host ID portion

## Network ID vs. Host ID

| Bits | Purpose |
|---|---|
| First 64 bits | Network ID |
| Last 64 bits | Host ID (~9.2 quintillion hosts per network) |

No address classes needed (unlike IPv4). Subnetting uses the same **[[CIDR]] notation** applied to the network ID portion.

---

**Tags:** #google-it-support #networking #ipv6 #subnetting
