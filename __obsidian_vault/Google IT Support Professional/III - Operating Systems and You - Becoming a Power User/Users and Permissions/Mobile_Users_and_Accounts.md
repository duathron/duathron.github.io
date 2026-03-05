> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 2: Users and Permissions

---

## Overview

Mobile operating systems handle user accounts differently from desktop OSes. Many single-purpose devices (e.g. GPS units) have user accounts under the hood that the user never interacts with. Smartphones and tablets follow a distinct pattern centered around a **primary account**.

> 📎 See also: [[Mobile Users and Accounts (Supplemental)]]

---

## Primary Account & User Profile

- The **primary account** is set up once during device configuration (username + password)
- After setup, the password is typically not re-entered on every use
- The primary account creates a **user profile** on the device, which contains:
	- All linked accounts
	- Personal preferences
	- Installed apps

In both **iOS** and **Android**, the primary account can sync settings and data to the cloud — enabling restore when switching to a new device.

---

## Additional Accounts & Single Sign-On (SSO)

A user profile can be linked to multiple additional accounts (email, social media, etc.). Apps can request permission to use these accounts for **[[Single Sign-On (SSO)]]**:

- The app authenticates the user via an already-signed-in account
- The app never receives the actual credentials — only permission to use them
- Example: "Sign in with Google" inside a third-party app

---

## Multiple User Profiles

- Most mobile devices support **only one user profile** — designed for single-person use
- Some **Android devices** support multiple user profiles (see supplemental reading)
- iOS does **not** natively support multiple user profiles in the same way

---

## Device Security & Access Control

Unlike desktops, mobile OSes don't require re-entering the primary password on every use. This creates a risk: anyone with physical access to the device can access all personal and work data.

### Protection Methods

| Method | Description |
|---|---|
| **Device password / PIN** | Numeric or alphanumeric lock screen |
| **Unlock pattern** | Gesture-based screen lock |
| **[[Biometrics]]** | Fingerprint sensor, facial recognition, voice — something unique to the user |
| **[[MDM]] (Mobile Device Management)** | Organizational policies that enforce device configuration and lock requirements |

**MDM systems** allow organizations to apply and enforce rules about how devices must be configured and used — critical for protecting business data on personal or company-issued mobile devices.

---

## IT Support Best Practices

- Help end users set up accounts on their devices when needed
- **Never ask for a user's password** — always have them enter it themselves
- If a user reveals their password to you, **encourage them to change it immediately**

---

**Tags:** #google-it-support #operating-systems #mobile #android #ios #security #users #sso #mdm
