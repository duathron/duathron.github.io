> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## The Problem

The entire internet cannot switch to [[IPv6 Addressing and Subnetting|IPv6]] at once. Legacy devices, coordination complexity, and core internet infrastructure still depend on IPv4. Both protocols must **coexist** during the transition.

## Coexistence Mechanisms

### IPv4-Mapped Address Space

- IPv6 addresses beginning with **80 zeros + 16 ones** map directly to an IPv4 address
- The remaining **32 bits** are the original IPv4 address
- Example: IPv4 `192.168.1.1` → IPv6 `::ffff:192.168.1.1` (or `0000:0000:0000:0000:0000:ffff:c0a8:0101`)
- Allows IPv4 traffic to travel over IPv6 networks

### IPv6 Tunnels

The primary method for IPv6 traffic to traverse IPv4 networks:

1. **IPv6 tunnel server** (entry) receives IPv6 traffic
2. **Encapsulates** the IPv6 data inside an IPv4 datagram
3. Travels across the **IPv4 internet**
4. **IPv6 tunnel server** (exit) **de-encapsulates** and forwards the IPv6 traffic

### Tunneling Protocols

| Protocol | How It Works | Pros | Cons |
|---|---|---|---|
| **6in4 (Manual)** | Encapsulates IPv6 directly inside IPv4; endpoints configured manually | Predictable performance, easy to debug | Often fails behind [[NAT]] |
| **TSP (Tunnel Setup Protocol)** | Negotiates tunnel setup parameters between endpoints | Supports various encapsulation methods, wider deployment | More complex setup |
| **AYIYA (Anything in Anything)** | Encapsulates any protocol in any other; designed for tunnel brokers | Works through NAT and with dynamic addresses; stable roaming | — |
![[ipv6 tunnel 1.png]]
### IPv6 Tunnel Brokers

- Companies that provide **tunneling endpoints as a service**
- No need to deploy your own tunnel server hardware
- AYIYA was specifically developed for tunnel broker use cases

## Outlook

IPv6 adoption is the long-term future of networking. Tunneling is a transitional technology that will eventually become unnecessary as IPv4 infrastructure is phased out.

---

**Tags:** #google-it-support #networking #ipv6 #ipv4 #tunneling
