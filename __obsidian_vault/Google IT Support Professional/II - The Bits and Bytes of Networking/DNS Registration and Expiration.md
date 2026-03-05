> **Course:** [[Google IT Support Professional]]
> **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## Overview

[[DNS]] is a global, hierarchical system with [[ICANN]] at the top. Because domain names must be **globally unique**, a structured registration process exists through **registrars**.

## Registrars

- A **registrar** is an organization responsible for assigning domain names to individuals or organizations
- Originally dominated by **Network Solutions Inc.** (handled nearly all non-country-specific domains)
- After an agreement with the US government, the market opened to competition
- Today: hundreds of registrars worldwide

## Registration Process

1. Create an account with a registrar
2. Search for available domain names via the registrar's Web UI
3. Agree on **price** and **registration length** (measured in years)
4. Choose name server setup:
   - Use the **registrar's name servers** as authoritative, or
   - Configure your **own authoritative name servers**

## Domain Transfers

Transferring a domain (to a new owner or registrar):

1. The **recipient registrar** generates a unique verification string
2. The current owner adds this string as a **TXT record** in their DNS settings
3. Once the record has **propagated**, it confirms ownership and transfer approval
4. Ownership moves to the new owner/registrar

## Expiration

- Domain registrations are **time-limited** (typically paid per year)
- Once expired, the domain becomes available for **anyone** to register
- Monitoring expiration dates is critical to avoid losing control of a domain

---

**Tags:** #google-it-support #networking #dns #domain-registration
