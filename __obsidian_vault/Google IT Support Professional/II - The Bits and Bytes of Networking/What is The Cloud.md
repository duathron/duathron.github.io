> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## Definition

**Cloud computing** is a model where computing resources are provisioned in a shareable way, so users get what they need, when they need it — without owning the underlying hardware.

## Core Technology: Hardware Virtualization

- A single **physical machine** (host) runs multiple **virtual instances** (guests)
- A **hypervisor** manages the VMs and presents a virtual hardware platform indistinguishable from real hardware
- Each guest runs its own independent OS
- The cloud scales this by connecting **large clusters of machines** that share resources across all virtual instances

## Why Cloud?

**Traditional model problem:** You buy physical servers sized for peak demand, but most resources sit idle most of the time.

**Cloud model:** A provider hosts your virtual instances on shared infrastructure. You pay for what you use, plus:

- No waiting for physical hardware delivery — provision in minutes via web UI
- Built-in services (backups, load balancing, etc.)
- Transparent hardware failure recovery — VMs migrate to healthy hosts automatically
- Scales up or down as needed

## Cloud Types

| Type | Description |
|---|---|
| **Public Cloud** | Large cluster of machines run by a third-party provider (e.g. AWS, GCP, Azure) |
| **Private Cloud** | Same concept, but owned and hosted on-premises by a single organization |
| **Hybrid Cloud** | Combination — sensitive workloads on private cloud, less sensitive on public cloud |

---

**Tags:** #google-it-support #networking #cloud #virtualization
