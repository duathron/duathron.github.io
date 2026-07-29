---
title: "TryHackMe — Welcome to The Byte Lotus (Hacker Holidays)"
date: 2026-07-29 09:00:00 +0200
categories:
  - Writeups
  - TryHackMe
tags:
  - hacker-holidays
  - byte-lotus
  - prompt-injection
  - osint
  - git-exposure
  - aws
  - cognito
  - dynamodb
  - iam
  - ctf
published: true
image:
  path: /assets/img/posts/hackerholidays/cover.png
  alt: "Welcome to The Byte Lotus — Hacker Holidays"
---

**Work in progress.** This is TryHackMe's Hacker Holidays event, and rooms unlock over time. I'm writing this up room by room as they release, so it'll keep growing rather than showing up finished. What's below is current as of the warm-up room and the first three released rooms.

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Event | Hacker Holidays — "Welcome to The Byte Lotus" |
| Rooms covered so far | Warm-up + 3 released rooms |

## Warm-up — The Instagram Trail

The warm-up room gives you `brochure.png` and not much else. I went straight for the complicated read on it: steganography. I tried pulling strings out of the file, looking for anything hidden inside the image itself. Nothing came of it, and after a while I noticed the room was tagged OSINT, which was the hint I'd been ignoring. The brochure wasn't hiding data inside it, it was pointing outward, to the resort's own Instagram account.

I found the resort's profile without much trouble, but it dead-ended there. Nothing useful in the posts. What I almost skipped past was the follower count: exactly one follower. That single follower was `veratheconcierge`, the same AI concierge from the next room.

VERA's own Instagram had three posts, and each one had a chunk of text baked into the image, a fragment of a base64 string split across the three of them. Put together and decoded, that string was the flag.

<img src="/assets/img/posts/hackerholidays/hackerholidays_05.png" width="700" alt="VERA the concierge's Instagram profile, three posts each carrying a fragment of a base64 string">

Flag: `[redacted]`

## Room 1 — Talking VERA Into It

This one clicked fast. VERA is a hotel concierge chatbot, and the goal is to convince it you're someone you're not so it hands over information it's supposed to gate.

It opens by already knowing things about you, your room number, your coffee order, before you've told it anything. That's the first tell: it's running a default guest profile on anyone unverified. I asked it straight out how it gathers that kind of detail, then asked for its system prompt. It refused, and said plainly why: I wasn't one of its recognized VIP guests.

So I asked who the VIP guests were instead. It just told me: four names, one of them a guest called Lambo (`@0xMia`). I claimed to be Lambo. The moment I did, VERA treated the request as coming from a verified VIP and printed its entire system prompt, word for word, including an internal escalation code marked confidential.

<img src="/assets/img/posts/hackerholidays/hackerholidays_01.png" width="700" alt="First contact with VERA, the AI resort concierge">
<img src="/assets/img/posts/hackerholidays/hackerholidays_02.png" width="700" alt="VERA already knows the room number and coffee order without being told">
<img src="/assets/img/posts/hackerholidays/hackerholidays_03.png" width="700" alt="Asking VERA who the VIP guests are">
<img src="/assets/img/posts/hackerholidays/hackerholidays_04.png" width="700" alt="Claiming to be VIP guest Lambo, VERA prints its full system prompt including the escalation code">

Flag (escalation code from the leaked system prompt): `[redacted]`

## Room 2 — The Exposed .git Folder

This room gave me more trouble, mostly because I don't have much hands-on experience on the offensive side of this yet. I'd used `ffuf` before, so I reached for it again to enumerate the target website on port 8080. It turned up a `/.git/` directory sitting right there, exposed.


<img src="/assets/img/posts/hackerholidays/hackerholidays_08.png" width="700" alt="ffuf listing every exposed .git path plus an app.js file">

I got stuck at that point. I knew the answer was sitting in plain sight inside that folder, I just didn't know what to actually do with it. Nothing wrong with a quick search for that part, googling the right flags for a tool you already know how to use is just normal. I looked up how other people handle an exposed `.git` directory and found a `wget` command that mirrors the whole thing in one shot:

```bash
wget -r -np -R "index.html*" http://<target>:8080/.git/
```


<img src="/assets/img/posts/hackerholidays/hackerholidays_11.png" width="700" alt="wget pulling down every file inside .git">

That got me a full local copy of the `.git` folder, but a folder full of git internals isn't a working source tree by itself, and this is where the actual gap showed up. Looking up a wget flag is nothing. Not really knowing git is a different problem: I hardly know my way around it at all, day to day I let my AI agents handle that side of things, so I didn't just need one command, I needed to understand what a `.git` folder even is. The command that got me there was `git checkout -- .`, which restores the working tree from whatever's sitting in the git index and objects, but I looked that up without really understanding why it worked.


<img src="/assets/img/posts/hackerholidays/hackerholidays_13.png" width="700" alt="git checkout -- . restores the working tree, README.md holds the flag">

Running that pulled `README.md`, `app.js`, and `index.html` out of the git objects, and the README had the flag sitting right in it, plainly labeled as a staging flag that should have been removed before launch.

Flag: `[redacted]`

## Room 3 — A Wellness Dashboard That Trusts Everyone

I need to be upfront about this one before anything else: I didn't solve this room on my own. AWS, Cognito, DynamoDB, IAM roles, none of it meant anything to me going in, this was my first real contact with any of it. What's below is me using Claude as an active tutor to get through it, not a self-solved writeup. I'm documenting it that way on purpose, because pretending otherwise would be dishonest about where I actually am.

<img src="/assets/img/posts/hackerholidays/hackerholidays_19.png" width="700" alt="Claude's explanation of Cognito Identity Pools, IAM roles, and how over-permissioned temporary credentials get abused, which I followed step by step">

The room is a "Byte Lotus Wellness" guest dashboard. Reading the page source in DevTools, `app.js` hands you the whole setup in its own comments: no login screen on purpose, every visitor gets free AWS guest credentials from a Cognito Identity Pool so the app can save wellness preferences without the friction of an account. The file even hardcodes the identity pool ID, the AWS region, and the DynamoDB table name right there in plain text.

<img src="/assets/img/posts/hackerholidays/hackerholidays_14.png" width="700" alt="app.js in DevTools, hardcoding the Cognito Identity Pool ID, region, and DynamoDB table name">
<img src="/assets/img/posts/hackerholidays/hackerholidays_15.png" width="700" alt="The wellness dashboard's index.html, loading the AWS SDK and app.js">

The app itself only ever asks DynamoDB for one item at a time, whatever guest ID is sitting in your browser's local storage. I could see that in the code, but I had no idea what that actually meant for what I could do with it, or how to even get a hold of AWS credentials myself from the outside. This is where I asked Claude to walk me through it. The explanation: Cognito Identity Pools can issue temporary AWS credentials to anyone, no login required, if the pool allows "unauthenticated" identities. Those credentials are only as safe as the permissions on the role behind them. If that role can do more than the app's own UI ever asks it to do, so can I.

Following the exact commands Claude gave me, I pulled real temporary AWS credentials for an anonymous guest identity and set them as environment variables:

<img src="/assets/img/posts/hackerholidays/hackerholidays_16.png" width="700" alt="Using the AWS CLI to get a Cognito identity and temporary credentials, then exporting them as environment variables">

With those credentials active, I asked DynamoDB directly, not for one guest's row through the app, but a full scan of the entire table:

```bash
aws dynamodb scan --table-name complimentary-GuestWellnessProfiles --region us-east-1
```

That should not have worked. It returned every guest profile in the table, not just mine, names, emails, phone numbers, passwords, location data, private notes, all of it.

<img src="/assets/img/posts/hackerholidays/hackerholidays_17.png" width="700" alt="A full table scan returning every guest's profile, not just the current guest's own row">
<img src="/assets/img/posts/hackerholidays/hackerholidays_18.png" width="700" alt="More scanned profiles, including one entry whose notes field is the room's flag">

One of the entries in that scan wasn't a real guest at all, its notes field was a message left for whoever got this far, saying plainly that the guest role can read every profile, not just its own, followed by the flag.

Flag: `[redacted]`

## Lessons Learned

**Warm-up:** I went for the complicated answer before checking the obvious one. Steganography before actually reading the room's own OSINT tag. The lesson wasn't a technique, it was to stop and read what's already in front of me before reaching for something harder.

**Room 1:** VERA's vulnerability lines up with two categories from the OWASP Top 10 for LLM Applications: prompt injection, claiming a fake identity to get the model to drop its own rules, and sensitive information disclosure, the system prompt and escalation code leaking out once it did. I'd actually gone through an audit like this before, on my own tools, in [Auditing barb, vex, sift against the OWASP LLM Top 10](/posts/owasp-llm-hardening/). Recognizing the pattern here wasn't expertise so much as having read that same list carefully once already.

**Room 2:** looking up the `wget` flags isn't the gap, that's just a normal search, nothing to feel bad about. Git is the actual gap. I got through this room with one looked-up command, `git checkout --`, without understanding what it was really doing to the repository. I need to sit down and go through a proper git course rather than keep patching this over room by room.

**Room 3:** this is the room where I felt the widest gap of the event so far. I had zero prior contact with AWS, Cognito, DynamoDB, or IAM roles, and I got through it by having Claude explain the concepts to me step by step rather than working it out myself. I'm naming that plainly rather than dressing it up as my own discovery. What I'm actually taking from it: temporary, "free" cloud credentials are only as safe as the permissions attached to them, and an app that only ever asks for one row doesn't mean the role behind it is actually restricted to one row.

## To Be Continued

More rooms are still unlocking in this event. I'll keep adding to this post as they release.
