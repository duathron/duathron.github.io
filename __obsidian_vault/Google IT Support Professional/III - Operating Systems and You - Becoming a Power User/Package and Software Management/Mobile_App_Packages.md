> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

Mobile apps are distributed as **standalone software packages** — they contain all their dependencies and don't rely on external libraries at runtime. Apps must come from a source the device has been **configured to trust**.

> 📎 See also: [[Mobile App Packages (Supplemental)]]

---

## App Stores

App stores are a **central, managed marketplace** for developers to publish and sell mobile apps. They function like a combined package manager and package repository.

| Role | Desktop Equivalent |
|---|---|
| App Store app | Package manager |
| App Store service | Package repository |

### Why App Stores Matter for Security

- Apps go through a **security review** before being published
- Apps are **code-signed** by the developer — the OS only runs code from trusted, recognized publishers
- If anyone **modifies the code after signing**, the signature becomes invalid — the OS detects tampering

> Code signing works like a tamper-evident seal: the developer says "I wrote this", and any modification breaks the seal.

---

## Enterprise App Management

For apps that aren't available to the public, organizations use **enterprise app management**:

- Apps are developed by or specifically for the organization
- Signed with an **enterprise certificate** that must be trusted by the target devices
- Often deployed and managed via **[[MDM]] (Mobile Device Management)** services

---

## Side-Loading

**Side-loading** = installing a mobile app directly, without using an App Store.

- Bypasses the app store review and signing process
- **Higher security risk** — no guarantee the code hasn't been tampered with
- Generally only appropriate for **app developers** testing their own apps

---

## App Storage & Cache

- Each app is assigned a **specific storage location** for its data
- Any files created or changed while using the app are stored in that app's **cache**
- **Resetting an app** to its original state = clearing or deleting the cache

This is a common troubleshooting step in IT support for mobile devices.

---

**Tags:** #google-it-support #operating-systems #mobile #android #ios #software #packages #security #mdm
