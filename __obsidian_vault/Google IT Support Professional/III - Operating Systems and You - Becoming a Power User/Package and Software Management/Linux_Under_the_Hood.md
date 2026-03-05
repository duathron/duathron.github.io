> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

In Linux, software installation from source is more transparent than on Windows — if you know the programming language used, you can read the installation instructions yourself. The exact process varies depending on the language and how the developer has structured the package.

---

## Source Archives

When installing from a **source archive**, the extracted package typically contains three key files:

| File | Purpose |
|---|---|
| **README** | Information about the package — read this before doing anything |
| **Setup script** | Shell script that runs all tasks needed to install the software |
| **Source code** | The actual program code to be compiled and installed |

---

## What a Setup Script Does

A setup script automates the installation steps the developer defines. A typical script might:

1. **Compile** the source code into machine-readable binary instructions
2. **Copy** the compiled binary to a system directory (e.g. `/bin`)
3. **Create** necessary folders (e.g. `/home/<username>/flappyapp`)
4. **Set permissions** or configure other system settings as needed

The developer decides exactly what tasks are required — there is no fixed standard like Windows Installer's MSI format.

---

## Key Difference from Windows

| Aspect | Windows | Linux |
|---|---|---|
| **Format standard** | MSI enforces strict rules | Setup scripts are freeform |
| **Transparency** | Closed source — hard to inspect | Open source — readable if you know the language |
| **Tooling** | Windows Installer handles bookkeeping | Developer handles everything manually in the script |

---

> 📎 See also: [[Windows Under the Hood]] | [[Linux Software Packages]] | [[__obsidian_vault/Google IT Support Professional/III - Operating Systems and You - Becoming a Power User/Package and Software Management/Archives]]

---

**Tags:** #google-it-support #operating-systems #linux #software #packages #installation
