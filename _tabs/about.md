---
# the default layout is 'page'
icon: fas fa-info-circle
order: 4
---

# About

*Last updated: 8 October 2026*

Technology has been part of my life for as long as I can remember. A Game Boy at
four. A self-built 486 at twelve, assembled from spare parts salvaged from my
parents' office, running DOS and Windows 95. As a teenager I ran the network
infrastructure at my parents' company and organised LAN parties with friends, long
before any of us had a driver's licence.

The passion was always there. Life had other plans.

I ended up in photography and committed to it fully. I finished my apprenticeship
as the top graduate of my regional photographers' guild, then earned a Bachelor of
Arts with a final grade of 1.0. What kept me engaged wasn't only the visual craft.
Photography is a deeply technical profession that demands constant adaptation:
evolving camera systems, complex colour science, and workflows built on specialised
tools. Over the years I developed deep expertise in **Adobe Photoshop**, at the
level of high-end retouching and multi-layer compositing where precision and an
understanding of how the tool thinks are everything, and in **Capture One**, where
colour, calibration, and RAW processing reward people who understand them at a
fundamental level. Alongside still photography I moved into video production, audio
engineering, and aerial cinematography, holding a certified EU drone pilot licence
(class A2).

Since 2014 I've worked as a freelance commercial photographer for corporate clients
across Germany and beyond. Precision, discretion, and delivering under pressure
aren't skills I'm still developing. They're the foundation I bring with me.

---

In November 2025 I decided to stop ignoring where my instincts had always pointed and
take my technical curiosity seriously, as a profession. Since then I've been learning
consistently: evenings, weekends, alongside a full-time freelance career and a busy
family life with a young child. Motivation was never the question.

My goal is a role as a SOC analyst. Longer term I'm heading towards detection
engineering and AI security, the place where my two interests meet.

## What I'm working on

I passed the Security Analyst Level 1 (SAL1) certification on my first attempt with
850/1000, after completing TryHackMe's SOC Level 1 path. On TryHackMe I've completed
315 rooms and rank in the top 1% worldwide (#5,470, as of 22 September 2026).
Right now I'm working through the Security Engineer and AI Security paths.

Hands-on, most of my SIEM practice so far has been with Splunk and the Elastic Stack
in lab environments. Next on my list are home labs I set up and run myself, starting
with vulnerability management: scanning, CVSS-based prioritisation, remediation and
re-scan.

## Tools I've built

I build security tools by orchestrating AI agents, and publish them on PyPI. My part
is the goal, the steering, and understanding every component well enough to explain
it. The workflow itself is my own design: independent review gates, multi-agent design
reviews, and a rule that the AI never signs off its own work. I don't present the code
as hand-written, and I'm happy to be tested on the concepts.

- **[sift](https://github.com/duathron/sift)** – an alert-triage summarizer with
  four LLM providers, defences against prompt injection, ticketing to Jira, TheHive
  and ServiceNow, and more than 1,100 tests
- **[vex](https://github.com/duathron/vex)** – IOC enrichment against VirusTotal,
  AbuseIPDB, Shodan, WHOIS, MISP and OpenCTI, with STIX 2.1 and MITRE ATT&CK
  Navigator export
- **[barb](https://github.com/duathron/barb)** – a phishing-URL analyser that works
  offline by design, with opt-in OSINT enrichment and an evaluation harness against
  an 800-URL corpus
- **[sigmaforge](https://github.com/duathron/sigmaforge)** – an honest backtest
  harness for Sigma detection rules: it measures whether a rule actually fires on the
  attack it targets and how often it fires on normal activity, and reports
  "unmeasured" where the data isn't good enough to say. My first detection-engineering
  work sample, still evolving.
- **[shipwright](https://github.com/duathron/shipwright)** – the shared library and
  agent framework underneath the other tools: evaluation gates, security helpers and
  project scaffolding

## Certifications

- **SEC1** – Cyber Security 101 *(TryHackMe, February 2026)*
- **Python Fundamentals with Practical Projects** *(Hyperskill / JetBrains Academy, February 2026)*
- **SOC Level 1** learning path, completed *(TryHackMe, April 2026)*
- **SAL1** – Security Analyst Level 1, 850/1000 on the first attempt *(TryHackMe, May 2026)*
- **Google IT Support Professional Certificate** – six courses *(Coursera, July 2026)*
- **Google AI Professional Certificate** – seven courses *(Coursera, August 2026)*

## Why this blog

This blog documents the path: CTF writeups, learning notes, the tools I'm building,
and honest reflections on what it takes to break into cybersecurity from a
non-traditional background. If you're on a similar path, I hope it's useful. If you're
a recruiter or hiring manager, feel free to reach out.

## Get in touch

- [LinkedIn](https://www.linkedin.com/in/christian-huhn-76a407114)
- [GitHub](https://github.com/duathron)
