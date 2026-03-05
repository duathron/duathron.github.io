> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management

---

## Overview

Just like [[Windows Package Dependencies|Windows]], Linux software packages often depend on other packages or shared libraries to function. When installing a standalone package with `dpkg`, dependencies are **not** installed automatically.

> 📎 See also: [[Linux Package Dependencies (Supplemental)]]

---

## What is a Package Dependency?

A **package dependency** is a package that another package requires in order to function. When a dependency is missing, the installation fails with an error like:

```
Dependency problems prevent configuration of google-chrome-stable
```

In this case, Chrome depends on `libappindicator1`, which must be installed first.

---

## Linux Shared Libraries

Linux shared libraries work similarly to [[Windows Package Dependencies|Windows DLLs]] — they are bundles of reusable code that multiple programs can use without each needing their own copy.

---

## The Dependency Problem with `dpkg`

`dpkg` is a **standalone package installer** — it installs the package you point it to, but does **not** resolve or install missing dependencies automatically.

```bash
sudo dpkg -i google-chrome.deb
# Error: dependency problems prevent configuration
```

In some cases you might encounter not just one missing dependency, but **ten or more** — installing them one by one manually is impractical.

---

## The Solution: Package Managers

**Package managers** handle dependency resolution automatically. They read a package's manifest, identify all required dependencies, download them from a repository, and install everything in the correct order.

> We'll cover package managers in the next lesson. For now: if you install a standalone package with `dpkg`, you are responsible for resolving dependencies yourself.

---

**Tags:** #google-it-support #operating-systems #linux #software #packages #dependencies #cli #bash #installation
