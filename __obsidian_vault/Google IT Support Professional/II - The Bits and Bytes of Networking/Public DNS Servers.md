> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## Overview

Functional [[DNS]] is essential for any network. There are multiple ways to handle name resolution, and **public DNS servers** serve as a valuable tool for troubleshooting and backup.

## DNS Service Models

| Model | Description |
|---|---|
| **ISP-provided** | Recursive name server included with your internet service; sufficient for basic internet use |
| **Self-hosted** | Required for resolving internal hostnames (e.g. laptop names, printers); common in businesses |
| **DNS as a Service** | Third-party managed DNS; growing in popularity |

## Public DNS Servers

Name servers set up by internet organizations for **free public use**. Useful for:

- **Troubleshooting** name resolution issues
- **Backup** when your primary DNS has problems
- **Temporary resolution** while building out a new network
- **Testing general internet connectivity** (most respond to [[ICMP]] echo requests / [[ping]])

### Notable Public DNS Servers

| Provider | IPs | Notes |
|---|---|---|
| **Level 3 Communications** | `4.2.2.1` – `4.2.2.6` | Never officially acknowledged; used by sysadmins for ~20 years as tribal knowledge |
| **Google Public DNS** | `8.8.8.8` / `8.8.4.4` | Officially documented and supported |

Most public DNS servers are available globally via **[[Anycast]]**.

## Security Considerations

- **DNS hijacking:** Malicious name servers can redirect users to harmful sites by returning faulty responses
- Always use name servers run by **reputable organizations**
- Outside of troubleshooting, prefer your **ISP's name servers**
- Research any public DNS provider before configuring devices to use it

---

**Tags:** #google-it-support #networking #dns #troubleshooting
