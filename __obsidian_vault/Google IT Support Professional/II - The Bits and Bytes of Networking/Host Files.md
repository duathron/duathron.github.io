> **Course:** [[Google IT Support Professional]] **Section:** [[II - The Bits and Bytes of Networking]] → Module 6: Troubleshooting and the Future of Networking

---

## Overview

Before [[DNS]] existed, computers used **host files** to map network addresses to human-readable names. While largely replaced by DNS today, host files remain present on all modern operating systems.

## What is a Host File?

- A **flat file** containing lines of `<IP address> <hostname>` mappings
- Example: `1.2.3.4 webserver` → the system resolves `webserver` to `1.2.3.4`
- Evaluated by the **networking stack of the OS** — applies system-wide (browsers, `ping`, etc.)

## The Loopback Address

- A special address that **routes traffic back to the local machine** — traffic never leaves the node
- **IPv4:** `127.0.0.1`
- **IPv6:** `::1`
- Almost every host file contains:
    
    ```
    127.0.0.1   localhost::1         localhost
    ```
    
- Configured via the host file on every modern OS

## Why Host Files Still Matter

|Use Case|Details|
|---|---|
|**Loopback configuration**|`127.0.0.1 localhost` is still set via host file|
|**Software requirements**|Some applications depend on specific host file entries|
|**Troubleshooting**|Force a domain to resolve to a specific [[IP Address]] for testing|
|**Security risk**|Malware can modify host files to redirect user traffic|

## Key Detail: Resolution Order

Host file entries are checked **before** [[DNS]] resolution on most operating systems. This allows overriding DNS for a specific machine — useful for testing, but also exploitable by viruses.

## Summary

Host files are a legacy name resolution method that predates DNS. They persist on all modern systems primarily for loopback configuration and occasional troubleshooting. Be aware of them as both a diagnostic tool and a potential attack vector.

---

**Tags:** #google-it-support #networking #dns #troubleshooting