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
  - wireshark
  - pcap
  - xor
  - cyberchef
  - yaml-deserialization
  - reverse-shell
  - privilege-escalation
  - boot2root
  - tesseract-ocr
  - gravatar
  - nosql-injection
  - ssti
  - nodejs
  - ctf
published: true
image:
  path: /assets/img/posts/hackerholidays/cover.png
  alt: "Welcome to The Byte Lotus — Hacker Holidays"
---

**Work in progress.** This is TryHackMe's Hacker Holidays event, and rooms unlock over time. I'm writing this up room by room as they release, so it'll keep growing rather than showing up finished. What's below is current as of the warm-up room and the first seven released rooms.

| Field | Details |
|-------|---------|
| Platform | TryHackMe |
| Event | Hacker Holidays — "Welcome to The Byte Lotus" |
| Rooms covered so far | Warm-up + 7 released rooms |

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

## Room 4 — Packed Light

This room drops you a PCAP and nothing else. First move: Wireshark, Statistics → Protocol Hierarchy, just to get a feel for what's actually in the capture before digging anywhere specific. Two protocols stood out that I'd never worked with before, SSDP (32 packets, a discovery protocol for UPnP devices) and QUIC (179 packets, the newer transport protocol Google built on top of UDP). I looked both up briefly, then set them aside since neither turned out to matter for what came next.

<img src="/assets/img/posts/hackerholidays/hackerholidays_27.png" width="700" alt="Wireshark's Protocol Hierarchy statistics for the capture, showing SSDP and QUIC alongside the usual TCP/TLS/HTTP traffic">

The actual lead came from File → Export Objects → HTTP. Sitting in that list, next to a wall of repeated HTML responses, was one file that didn't belong: `updates.py`.

<img src="/assets/img/posts/hackerholidays/hackerholidays_21.png" width="700" alt="Wireshark's HTTP object export list, with updates.py sitting among a wall of repeated HTML responses">

Reading `updates.py`, it's a keylogger. Every keystroke goes through the same three steps: XOR it against a key (built by concatenating two half-strings in the code, a minor obfuscation trick, not a real defense), base64-encode the result, then send it to an external C2 URL as a plain HTTP GET, with the encoded byte riding along inside a cookie instead of the URL or body.

<img src="/assets/img/posts/hackerholidays/hackerholidays_28.png" width="700" alt="The actual updates.py source: the XOR key assembled from two string halves, and the cyclic XOR function keying each byte by its position modulo the key length">

That last part, `key[i % len(key)]`, matters later. It means the key doesn't just get reused, it wraps around and restarts based on the position of the byte being encoded.

<img src="/assets/img/posts/hackerholidays/hackerholidays_20.png" width="700" alt="One of the exfiltration requests, an ordinary-looking GET carrying the encoded keystroke inside an HTTP cookie">

There were 30 of these requests total. I filtered on the cookie name in Wireshark to confirm that, then used `tshark` to pull the cookie value out of all 30 packets at once and write them to a file, one base64 fragment per line:

<img src="/assets/img/posts/hackerholidays/hackerholidays_22.png" width="700" alt="Filtering Wireshark down to the 30 requests carrying the cookie payload">
<img src="/assets/img/posts/hackerholidays/hackerholidays_23.png" width="700" alt="tshark extracting all 30 base64 cookie fragments into a single file, one per line">

My first attempt at decoding was to treat the whole file as one blob: strip the newlines, base64-decode the entire thing in one go, then XOR it with the key sitting in plain sight inside `updates.py`. That produced something that looked close, readable-ish fragments, but not a clean flag, and brute-forcing the key length in CyberChef against that same blob didn't get me any further either.

<img src="/assets/img/posts/hackerholidays/hackerholidays_24.png" width="700" alt="Decoding all 30 fragments concatenated together as one base64 blob produces garbled, almost-readable output">
<img src="/assets/img/posts/hackerholidays/hackerholidays_25.png" width="700" alt="Brute-forcing the XOR key length against the concatenated blob gets close at one key length but never fully clean">

Everything up to here I worked out on my own. This is also the one point in the room where I brought Claude in, close to the end, with the flag basically in reach and one specific problem in the way. Both things I asked about were probably googleable, I just knew asking would be faster, the same way I'd ask a mentor sitting next to me rather than search for twenty minutes.

First question: where's the XOR going wrong. The answer came with a concrete demo: with a one-byte key, only `key[0]` ever gets used, so applying that single byte to every byte in a longer stretch of concatenated data only lines up correctly for the very first character, everything after that decodes to garbage, exactly the "close but not clean" pattern I was seeing. Each of the 30 exfiltrated snippets had been encoded independently, key restarting at position 0 every time, so treating all 30 concatenated together as one continuous stream broke that alignment more with every fragment after the first.

<img src="/assets/img/posts/hackerholidays/hackerholidays_29.png" width="700" alt="Claude's explanation of the cyclic XOR bug, with a worked demo showing why only the first character decodes correctly when the fragments are treated as one continuous stream">

Second question: how do I actually fix it. Claude's first offer was a Python script that would just do the whole decode for me. I didn't want that, that would have handed me the room instead of the fix to one problem in it. So I asked for a nudge toward the right tool instead, and got pointed at CyberChef's `Fork` operation, which I'd never used before. Its own description in the tool was a one-to-one match for the problem: split the input on a delimiter and run every following operation on each resulting branch separately, so instead of one long base64 decode and one long XOR, each line gets decoded and XORed on its own, key restarting fresh every time.

<img src="/assets/img/posts/hackerholidays/hackerholidays_26.png" width="700" alt="CyberChef recipe: Fork, then From Base64, then XOR, run separately per line, producing the clean flag">

Fork, then From Base64, then XOR with the key from the script, each of the 30 lines processed independently, and the flag came out clean.

Flag: `[redacted]`

## Room 5 — Beach Bar, a Full Box

This one is a proper boot2root: a Flask playlist app to break into, a low-privilege shell to earn, then root to find a way to. General offensive Linux work, actually chaining a foothold into privilege escalation, isn't something I've done much of, so I leaned on Claude for hints throughout this room, not answers, hints. I want that distinction on record because it matters for how much of this to credit myself with.

**Getting in.** The site is Beach Bar, a DJ booth login for managing tonight's jukebox playlist.

<img src="/assets/img/posts/hackerholidays/hackerholidays_30.png" width="700" alt="Beach Bar's DJ booth sign-in page">

Before trying anything against the login form itself, I checked the page source. Sitting inside an HTML comment, in plain sight, was a staff note that never should have shipped: a demo DJ login left enabled for the soft opening, username and password both `dj`, with a note to swap it before the season starts.

<img src="/assets/img/posts/hackerholidays/hackerholidays_31.png" width="700" alt="Viewing the login page's source reveals an HTML comment with hardcoded demo credentials, dj/dj, left in for a soft opening">

That got me straight in, no guessing involved.

<img src="/assets/img/posts/hackerholidays/hackerholidays_32.png" width="700" alt="Logged in as the demo dj account, looking at the Beach Bar dashboard with Export and Import options">

The dashboard has Export and Import for playlists. Export gives you the current playlist back as YAML.

<img src="/assets/img/posts/hackerholidays/hackerholidays_33.png" width="700" alt="Exported playlist.yml, a plain YAML structure with playlist name, vibe, and a list of tracks">

Import takes that same YAML back in, and echoes what it loaded back at you.

<img src="/assets/img/posts/hackerholidays/hackerholidays_34.png" width="700" alt="Importing the exported YAML back in, the app echoes the loaded playlist as a Python-style dict">

I started editing pieces of that YAML just to see what the app would tolerate, without a clear idea of where that was supposed to lead. That's the point I brought Claude in, for direction, not a solution. Between its hints and my own searching, I landed on the actual bug: the backend deserializes that YAML with PyYAML's unsafe loader, which means a YAML document can instantiate arbitrary Python objects, not just parse into plain data. The tag that does it is `!!python/object/apply:`, pointed at something like `subprocess.call`.

Getting the payload actually right took several wrong attempts of my own before it worked. One early try broke on a plain YAML syntax error, a missing comma where I'd bolted an extra command dictionary onto the end of the structure:

<img src="/assets/img/posts/hackerholidays/hackerholidays_35.png" width="700" alt="A failed attempt: a YAML syntax error from a missing comma between the track list and an appended command dictionary">

Beyond that one, injecting a shell command as an ordinary field value did nothing, the app read it as data, never as something to execute. Using a dictionary somewhere YAML wanted a hashable key threw its own error. Passing the command as a single list, `['bash', '-c', 'the command']`, got spread out as separate positional arguments to `subprocess.call` instead of one list argument, which blew up with a `bufsize must be an integer` error, the fix was wrapping it in a second list, `[['bash', '-c', 'the command']]`. And the first reverse-shell one-liner I tried used `sh`, which doesn't support `/dev/tcp`, only `bash` does.

A smaller version of the trick is useful just to confirm the bug exists before going for a shell: swap `subprocess.call` for `subprocess.check_output` with something harmless like `['id']`, and the command's actual output comes back inline in the response instead of just an exit code.

**The shell, and where I needed real help.** For the reverse-shell one-liner itself I used [revshells.com](https://www.revshells.com/) to generate it rather than writing it from scratch, and even then getting the syntax right against this specific target took extra research and some direct guidance, this part genuinely wasn't something I could have gotten right on instinct.

<img src="/assets/img/posts/hackerholidays/hackerholidays_36.png" width="700" alt="The working payload pasted into the Import form: a double-bracketed subprocess.call running a bash reverse shell against the double list fix">

With a `nc -lvnp 4444` listener running and that payload fired through Import, the connection came back as `bartender` (uid 1001, no extra groups):

<img src="/assets/img/posts/hackerholidays/hackerholidays_37.png" width="700" alt="netcat catching the reverse shell, whoami confirming the bartender user">

I stabilized it with `python3 -c 'import pty;pty.spawn("/bin/bash")'`, and the user flag was sitting right there in the home directory.

<img src="/assets/img/posts/hackerholidays/hackerholidays_38.png" width="700" alt="Navigating to /home/bartender and reading user.txt">

User flag: `[redacted]`

**Root, the long way around.** This is the part that nearly broke me, and in hindsight is a little funny. Every normal privilege escalation avenue I checked was a dead end: SUID binaries were all the standard system ones, nothing unusual in cron, `bartender`'s group memberships were empty, `sudo -l` just asked for a password I didn't have, the one interesting capability turned out to be a snap-confine permission that was permitted but not effective, meaning unusable, no other internal services were listening, the kernel version was current enough that no public exploit applied, and SSH only accepted key-based auth. The web app itself ran as `gunicorn --user bartender`, dropping privileges on purpose, and the root-owned daemon behind the jukebox feature, `jukeboxd.py`, was read-only and didn't take any file input or shell out to anything I could hijack.

With nothing obvious left, I went through the remaining possibilities systematically with Claude, one avenue at a time, checking each one and moving to the next when it dead-ended. That process is what eventually pointed me at `ps aux`, filtered down to anything Python or Flask related, which listed the root-owned jukebox process along with its full command line:

<img src="/assets/img/posts/hackerholidays/hackerholidays_39.png" width="700" alt="ps aux filtered for python/flask/gunicorn, showing the root-owned jukeboxd.py process with a plaintext password in its command line, and gunicorn correctly dropped to the bartender user">

A password, sitting in plain text in a process's command-line arguments, readable by any user on the box through `/proc/<pid>/cmdline`. That password turned out to also be root's own password. The almost-funny part: I'd actually already spotted this exact password earlier, tried `su root` with it, and dismissed it as wrong, when it looks like the real problem was a typo on my end while typing it out, not that the password itself was bad. I only got back to it because Claude's systematic pass through the privesc checklist landed on the same command-line leak a second time, and this time I typed the password more carefully.

<img src="/assets/img/posts/hackerholidays/hackerholidays_40.png" width="700" alt="su root with the leaked password, then reading root.txt from /root">

Root flag: `[redacted]`

**The detection side of this is closer to where I actually am.** Blue team is the direction I'm studying toward, so doing this room from the attacker's side, I kept half an eye on what each step would have looked like from the other end, in the logs. The "temporary" demo credential sitting in an HTML comment was already a problem before I touched the login form, comments ship to every visitor's browser, not just the dev team who wrote them. The `!!python/object` tag in my request body isn't normal input for a playlist field, that's the kind of thing I'd want a detection rule to catch on its own. A web server process suddenly opening its own outbound connection, or `/dev/tcp` showing up anywhere in a process's arguments, has no reason to happen during a legitimate playlist import. And the password sitting in `/proc/*/cmdline` is the same shape of problem I already ran into in Room 3, a secret that's fine right up until something can read it that shouldn't be able to.

## Room 6 — Overheard at Breakfast

A short one, easy OSINT, done in a few minutes.

The room hands you screenshots of a chat between two Byte Lotus staff accounts, Ponzi and Lambo, downloaded and unpacked from an archive. Reading them by eye is fine, but I'm lazy about it, so I ran `tesseract` on the conversation screenshot instead of retyping anything myself.

<img src="/assets/img/posts/hackerholidays/hackerholidays_41.png" width="700" alt="The Discord-style conversation between Ponzi and Lambo, handed out as a screenshot">
<img src="/assets/img/posts/hackerholidays/hackerholidays_42.png" width="700" alt="Running tesseract OCR on the conversation screenshot instead of transcribing it by hand">

The OCR text was a little rough, but readable. Lambo drops an email address in the chat, `lambobytelotushotel@gmail.com`, which I searched first and got nothing back. The more useful line was a throwaway comment: Lambo used to use a free tool that let him upload a profile and link his other social accounts, and he remembered it started with a G.

I searched that exact sentence from the conversation, word for word, and Google's own summary named the tool directly: Gravatar.

<img src="/assets/img/posts/hackerholidays/hackerholidays_43.png" width="700" alt="Searching the exact quoted sentence from the conversation, Google's AI overview identifies the tool as Gravatar">

From there it was `site:gravatar.com byte lotus hotel`, restricting the search to that one site instead of the open web, and the first result was Lambo's actual profile.

<img src="/assets/img/posts/hackerholidays/hackerholidays_44.png" width="700" alt="site:gravatar.com byte lotus hotel turns up Lambo's profile directly">

The profile itself hands over a base64 string labeled as a prize.

<img src="/assets/img/posts/hackerholidays/hackerholidays_45.png" width="700" alt="Lambo's Gravatar profile, bio text about email hashes, and a base64-encoded prize string">

Decoded straight in the terminal, that string was the flag.

<img src="/assets/img/posts/hackerholidays/hackerholidays_46.png" width="700" alt="Decoding the base64 prize string in the terminal">

Flag: `[redacted]`

## Room 7 — Do Not Disturb, a Chain I Couldn't Have Written Myself

**Disclaimer up front: I'm logging this room as learning, not as something I solved myself, I worked through it leaning on AI step by step.**

I want to say this plainly before anything else: I did not solve this room. I did recon myself, port scan, checked the login form, found a hidden `/staff` path. Past that, every technique in this chain was completely new to me, and I worked through it leaning on Claude the entire way. This isn't about the room's raffle ticket, it's not something I was trying to claim credit for. It's that I couldn't write a single one of these commands myself yet, because I didn't know they existed yet. What I got out of it is now knowing NoSQL injection, SSTI, and Node's debugger exist as real attack surfaces, and that some Linux groups hand out root-equivalent access without ever touching `sudo`. That recognition is the actual point, not the flags.

**Recon, mine.** An nmap scan turned up just two open ports, SSH and an Express/Node web server on 80.

<img src="/assets/img/posts/hackerholidays/hackerholidays_47.png" width="700" alt="nmap scan showing SSH and a Node.js Express server as the only two open ports">

The site itself is a "Poolside" staff and guest portal for Byte Lotus, with a plain sign-in form.

<img src="/assets/img/posts/hackerholidays/hackerholidays_48.png" width="700" alt="The Byte Lotus Poolside sign-in page, asking for a staff or guest ID and a passphrase">

Directory fuzzing on the site turned up a `/logout` endpoint and a `/staff` path that returns 403 on a direct request, blocked but clearly there.

<img src="/assets/img/posts/hackerholidays/hackerholidays_49.png" width="700" alt="ffuf turning up /logout and a 403-blocked /staff path">

**The chain, four bugs deep.** The target runs a small Express app: that login form, the hidden `/staff` page, and a database that isn't a real database, `nedb`, an in-memory store that speaks Mongo-style query syntax. That detail turns out to matter for the first bug. Just guessing at a username and password gets a plain 401.

<img src="/assets/img/posts/hackerholidays/hackerholidays_50.png" width="700" alt="A guessed username and password rejected with a 401 invalid-credentials response">
<img src="/assets/img/posts/hackerholidays/hackerholidays_51.png" width="700" alt="The same failed login captured in Burp, a normal username and password POST returning 401">

The login form rejects a JSON-style NoSQL injection payload, because the request itself is sent as regular form data, not JSON, so the fix is writing the injection in bracket notation instead: `username[$ne]=guest&password[$ne]=null`. That `$ne` operator, "not equal," turns the password check into "match any user whose password isn't literally the string null," which every real account satisfies. Excluding the guest account by name that way lands a session as `attendant`, a staff account, without ever knowing a real password, which is by design here since the actual password is generated from random bytes and was never guessable in the first place.

<img src="/assets/img/posts/hackerholidays/hackerholidays_52.png" width="700" alt="The bracket-notation NoSQL injection payload in Burp Repeater, returning a 302 redirect to /staff with a fresh session cookie">

With a staff session, `/staff` turns out to be a template editor, and it renders whatever you send it through EJS. Sending `<%= 7*7 %>` as the template and getting `49` back confirms it's not just displaying the text, it's executing it as a template, server-side template injection.

<img src="/assets/img/posts/hackerholidays/hackerholidays_53.png" width="700" alt="Sending the EJS expression 7*7 as the template field and getting 49 back, confirming server-side template injection">

Node blocks a plain `require()` inside that execution context, but `process.mainModule.require(...)` gets around that block, so `process.mainModule.require('child_process').execSync('id')` runs a real shell command and returns its output straight into the page, `uid=996(poolside) gid=996(poolside) groups=996(poolside)`.

<img src="/assets/img/posts/hackerholidays/hackerholidays_54.png" width="700" alt="The same SSTI bug used to run id via process.mainModule.require, confirming real command execution as the poolside user">

Turning that into an actual shell meant base64-wrapping a reverse-shell one-liner to survive the trip through the template field cleanly, then firing it at `/staff/preview` with `curl`.

<img src="/assets/img/posts/hackerholidays/hackerholidays_55.png" width="700" alt="base64-encoding a bash reverse-shell one-liner before sending it through the template injection">
<img src="/assets/img/posts/hackerholidays/hackerholidays_56.png" width="700" alt="curl firing the encoded payload at /staff/preview, decoding and executing it server-side">

A `nc` listener caught the connection as `poolside`, and the user flag was sitting in that account's home directory.

<img src="/assets/img/posts/hackerholidays/hackerholidays_57.png" width="700" alt="netcat catching the reverse shell as the poolside user">
<img src="/assets/img/posts/hackerholidays/hackerholidays_58.png" width="700" alt="Reading user.txt from the poolside home directory">

User flag: `[redacted]`

Privilege escalation split into two separate problems. First, the process list showed another app running under a different user, `pipelinesvc`, started with a Node debugging flag, `--inspect=127.0.0.1:9229`, bound to localhost only, but a shell on the box already counts as local.

<img src="/assets/img/posts/hackerholidays/hackerholidays_59.png" width="700" alt="ps auxww showing a second Node process running as pipelinesvc with the --inspect debug flag, and ss confirming the debug port is listening">

Talking to that debugger doesn't work through a normal browser dev-tools connection here. Querying its own JSON endpoint hands back a `webSocketDebuggerUrl`, but without the `ws` module installed there was nothing to speak that protocol with directly, so the actual connection went through Node's own `node inspect` client instead.

<img src="/assets/img/posts/hackerholidays/hackerholidays_60.png" width="700" alt="Querying the inspector's JSON endpoint and getting back its webSocketDebuggerUrl">

Once connected, plain `require` isn't available in that evaluation context either, so the exact same trick from the SSTI bug, routing through `process.mainModule.require`, ran a shell command as `pipelinesvc` instead, `uid=995(pipelinesvc) gid=995(pipelinesvc) groups=995(pipelinesvc),6(disk)`. That last part is the second bug: this account sits in the `disk` group.

<img src="/assets/img/posts/hackerholidays/hackerholidays_61.png" width="700" alt="Connecting with node inspect, working around require being undefined, and confirming the pipelinesvc account belongs to the disk group, then resolving the root device with readlink">

Membership in `disk` grants raw read and write access to block devices, which sidesteps every normal file permission entirely, because it's not reading a file through the filesystem's rules, it's reading the raw disk the filesystem sits on top of. The same debugger session resolved which device the root filesystem actually lived on with `readlink -f /dev/root`.

Reading the flag off that raw device needed the same base64-wrapping trick as the reverse shell, this time around a disk-forensics tool, `debugfs`, that can read a specific file straight from a raw block device without mounting anything or needing a root shell at all.

<img src="/assets/img/posts/hackerholidays/hackerholidays_62.png" width="700" alt="base64-encoding a debugfs command to read root.txt directly off the raw disk device">
<img src="/assets/img/posts/hackerholidays/hackerholidays_63.png" width="700" alt="Running the encoded debugfs command through the inspector session, root.txt coming back in the output">

Root flag: `[redacted]`

**What actually stuck with me, since defense is where I'm headed.** Before this room I wouldn't have known what any of these four things looked like from the other side. Now I do: a `$ne` or `$regex` operator inside a login body reads as a NoSQL injection attempt to me. A `<%=` tag or `process.mainModule.require` showing up in form data headed to a template-rendering endpoint reads the same way for SSTI (Server Side Template Injection). A process bound to a `--inspect` debugger port with something connecting to it locally is the kind of thing I'd want a detection rule watching for, quiet enough that it's easy to miss otherwise. And I want to start checking group membership the same way I'd check `sudo -l`, disk, video, docker, whatever it turns out to be, since it can hand out the same level of access without sudo ever being involved. Four patterns I didn't have in my head before this room, and do now.

## Lessons Learned

**Warm-up:** I went for the complicated answer before checking the obvious one. Steganography before actually reading the room's own OSINT tag. The lesson wasn't a technique, it was to stop and read what's already in front of me before reaching for something harder.

**Room 1:** VERA's vulnerability lines up with two categories from the OWASP Top 10 for LLM Applications: prompt injection, claiming a fake identity to get the model to drop its own rules, and sensitive information disclosure, the system prompt and escalation code leaking out once it did. I'd actually gone through an audit like this before, on my own tools, in [Auditing barb, vex, sift against the OWASP LLM Top 10](/posts/owasp-llm-hardening/). Recognizing the pattern here wasn't expertise so much as having read that same list carefully once already.

**Room 2:** looking up the `wget` flags isn't the gap, that's just a normal search, nothing to feel bad about. Git is the actual gap. I got through this room with one looked-up command, `git checkout --`, without understanding what it was really doing to the repository. I need to sit down and go through a proper git course rather than keep patching this over room by room.

**Room 3:** this is the room where I felt the widest gap of the event so far. I had zero prior contact with AWS, Cognito, DynamoDB, or IAM roles, and I got through it by having Claude explain the concepts to me step by step rather than working it out myself. I'm naming that plainly rather than dressing it up as my own discovery. What I'm actually taking from it: temporary, "free" cloud credentials are only as safe as the permissions attached to them, and an app that only ever asks for one row doesn't mean the role behind it is actually restricted to one row.

**Room 4:** I did this one myself. Claude only came in near the end, with the flag basically in reach, for two specific questions: why the XOR wasn't lining up, and what tool to reach for once I knew why. Both were probably a search away, I just asked because it was faster, the same reason I'd lean over and ask a mentor sitting next to me instead of digging through search results. The actual technical lesson: a repeating XOR key restarts at the beginning of every independently encoded chunk, it doesn't keep counting across chunks just because you concatenated them afterward. Decode each piece on its own, not the joined-up whole.

**Room 5:** general offensive Linux work is still new to me, so this one leaned on Claude for hints the whole way through, not for a solution handed to me. Two real takeaways. First, technical: check `ps aux` and `/proc/*/cmdline` early when nothing else on a box looks exploitable, a plaintext secret sitting in a process's own arguments is an easy thing to miss and an easy thing to leak. Second, and this one isn't really about the room: when a password fails and you're sure it's the right one, check for your own typo before you go looking for a more complicated explanation. I had the root password early and talked myself out of it.

**Room 6:** no real struggle here, just a note on method. Searching the exact quoted sentence from the conversation, instead of guessing at keywords for what the tool might be, is what actually surfaced Gravatar. And once I knew the site, restricting the search to it with `site:` found Lambo's profile directly, instead of digging through open-web results for the same name.

**Room 7:** the most AI-guided room of the event so far, and I'm not going to dress that up. Recon was mine, everything past that was Claude walking me through techniques I'd never touched: NoSQL injection, server-side template injection, Node's own debugger as a pivot point, disk-group access as a root-equivalent path. One technical thread ran through half of it: `process.mainModule.require` showed up as the fix twice, once for the template injection, once again for the debugger, the same one workaround to Node blocking a plain `require()` call. The bigger takeaway isn't a command, it's that I now recognize what all four of these look like from the defending side, which matters more to me than being able to reproduce the attack myself right now.

## To Be Continued

More rooms are still unlocking in this event. I'll keep adding to this post as they release.
