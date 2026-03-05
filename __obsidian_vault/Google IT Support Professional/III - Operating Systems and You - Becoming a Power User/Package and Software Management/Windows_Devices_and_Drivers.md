> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

A **driver** is software that allows hardware devices to communicate with the operating system. Windows manages all devices and their drivers through a central console called the **Device Manager**.

> 📎 See also: [[Windows Devices and Drivers (Supplemental)]]

---

## Device Manager

**Device Manager** groups all hardware devices on the computer by category (displays, keyboards, storage, etc.).

### Opening Device Manager

| Method | Steps |
|---|---|
| **Run dialog** | `Win+R` → type `devmgmt.msc` → Enter |
| **Right-click** | Right-click "This PC" → Manage → Device Manager |

### What You Can Do in Device Manager

Right-click any device to access:

| Action | Effect |
|---|---|
| **Update driver** | Search for and install a newer driver version |
| **Disable device** | Temporarily disable the device without uninstalling |
| **Uninstall device** | Remove the device and its driver |
| **Scan for hardware changes** | Detect newly connected devices |
| **Properties** | View manufacturer, driver version, and device status |

---

## Plug and Play (PnP)

Windows uses a **Plug and Play** system to automatically detect and configure new hardware when it is connected.

### PnP Device Installation Process

1. A new device is connected to the computer
2. Windows asks the device for its **Hardware ID** — a unique string assigned by the manufacturer
3. Windows searches for a matching driver in this order:
   - Local list of well-known drivers
   - Windows Update
   - Driver Store
   - Installation disk (if provided with the device)
4. Windows installs the driver — the device is ready to use

> Most of this process happens automatically in the background without user interaction.

---

**Tags:** #google-it-support #operating-systems #windows #drivers #hardware #device-manager
