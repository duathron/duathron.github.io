> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management
> **Type:** Supplemental Reading
> **Sources:**
> - [Introduction to Plug and Play – Microsoft Docs](https://docs.microsoft.com/en-us/windows-hardware/drivers/kernel/introduction-to-plug-and-play)
> - [Step 1: The New Device Is Identified – Microsoft Docs](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/step-1--the-new-device-is-identified)
> - [Hardware IDs – Microsoft Docs](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/hardware-ids)
> - [Step 2: A Driver for the Device Is Selected – Microsoft Docs](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/step-2--a-driver-for-the-device-is-selected)

---

## Plug and Play (PnP) – Deep Dive

The **Plug and Play** system is a combination of hardware standards and OS software that allows Windows to automatically detect, configure, and install drivers for connected devices without requiring manual user intervention.

### PnP Components

| Component | Role |
|---|---|
| **Hardware** | Device must support PnP and expose a Hardware ID |
| **BIOS/UEFI** | Enumerates devices at boot |
| **Windows Kernel** | Detects device connections and initiates the driver search |
| **Driver Store** | Local cache of trusted drivers |
| **Windows Update** | Cloud-based driver repository |

---

## Step 1 – Device Identification

When a new device is connected, Windows reads the device's **Hardware ID**:

- Hardware IDs are assigned by the **vendor/manufacturer**
- They are structured strings that uniquely identify the device model
- Format example: `USB\VID_045E&PID_0745` (USB vendor + product ID)
- A device can have **multiple Hardware IDs**, listed from most specific to least specific
- Windows uses the most specific match available when searching for a driver

---

## Hardware IDs

A **Hardware ID** is the primary identifier Windows uses to match a device to its driver.

- Defined by the vendor during manufacturing
- Embedded in the device's firmware
- Read by the OS immediately upon connection
- Used to query the **Driver Store**, **Windows Update**, and **Windows Catalog**

**Compatible IDs** are broader identifiers used as fallback when no exact Hardware ID match is found — they allow a generic driver to work with a device even without a vendor-specific one.

---

## Step 2 – Driver Selection

Once Windows has the Hardware ID, it searches for a matching driver in order:

1. **Driver Store** (`C:\Windows\System32\DriverStore`) — local trusted driver cache
2. **Windows Update** — online driver database
3. **Installation media** — disk or folder provided by the user or vendor

Windows selects the **best match** based on:

- Exact Hardware ID match (preferred)
- Compatible ID match (fallback)
- Driver version and date (most recent preferred)

Once selected, Windows installs the driver and makes the device available to the OS.

---

> 📎 See also: [[Windows Devices and Drivers]] | [[Linux Devices and Drivers]]

---

**Tags:** #google-it-support #operating-systems #windows #drivers #hardware #plug-and-play #reference
