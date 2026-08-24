---
title: "Slingshot"
date: 2026-08-24 08:00:00 +0100
categories: [Writeups, TryHackMe]
tags: [elk, kibana, kql, log-analysis, web-attack, lfi, sql-injection, threat-hunting]
image:
  path: /assets/img/posts/slingshot/cover.png
---

## Introduction

Slingshot drops you into a Kibana instance instead of a terminal. No shell to pop, no exploit to write, just an `apache_logs` index full of ModSecurity audit data and a set of questions about an attack that already happened against a web app running on `slingway.thm`. The job is reconstructing it: which recon tool touched the server, which credentials got used, how the attacker got a foothold, and what they actually walked out with.

## Theory

Kibana's Discover view is a query bar over an Elasticsearch index plus two things that matter for a room like this: the field sidebar on the left, which shows a value breakdown for whatever field is selected, and the expanded-document view, which lets you drill into one hit and read every field a log line carries, not just the ones shown in the results table. The query bar itself uses KQL, Kibana Query Language, `field: value` pairs, wildcards, and filter chips you can pin on top of a free-text search. None of that is exotic once you've used it a few times, but I hadn't, going in.

## Walkthrough

**Finding the attacker.** The log corpus only had a handful of distinct remote IPs in it, so narrowing down which one belonged to the attacker wasn't the hard part. Once I had it, pivoting on `request.headers.User-Agent` for that address laid the rest of the recon out on its own: Nmap, Gobuster, and Hydra all show up as literal substrings in the user agent strings the tools send by default. Each one answered a room question by itself, the Gobuster one came from combining `request.headers.User-Agent: Gobuster` with `response.status: 404`, since a directory brute-force is mostly a wall of misses with the odd hit buried in it.

**Credentials via Hydra.** Filtering the same user agent down to `response.status: 200` instead of 404 gives the one request that actually worked, a `GET /admin-login.php` carrying an `Authorization: Basic` header.

<img src="/assets/img/posts/slingshot/slingshot_02.png" width="700" alt="A Kibana document expanded to show a successful admin-login.php request from the Hydra user agent, carrying a Basic auth header">

Basic auth is just base64 over `user:pass`, so that header decodes on its own. I ran it through CyberChef's From Base64 operation and got the plaintext username and password out, `[redacted]`.

<img src="/assets/img/posts/slingshot/slingshot_01.png" width="700" alt="CyberChef decoding the Basic auth header's base64 payload into the plaintext admin:thx1138 credential pair">

**Getting a foothold.** With working admin credentials, the next question was how they turned into code execution. Filtering on `http.url: */admin/upload.php*` turns up exactly two hits, one that hits the endpoint plain and one carrying a multipart POST.

<img src="/assets/img/posts/slingshot/slingshot_03.png" width="700" alt="Two hits for the upload.php endpoint in Kibana, one a plain GET and one a multipart POST">

The POST body is a file upload named `easy-simple-php-webshell.php`, a minimal PHP shell that echoes the running script's own filename and runs whatever comes in through a `cmd` GET parameter via `system()`. The response confirms the upload landed under `/uploads`, and the file's own source, sitting right there in the request body, carries the room's flag in a comment.

<img src="/assets/img/posts/slingshot/slingshot_04.png" width="700" alt="Expanded document showing the multipart request body: a PHP webshell with a comment carrying the room's flag">

The first command run against that shell, once it was live, was `whoami`. Not creative, but it's the obvious first thing to check once you've got arbitrary command execution and want to know what you're working with.

**Local file inclusion.** The next question pointed at reading a file outside the intended path, so I filtered `http.url: */../../*` to catch anything doing path traversal. That turned up this request line, walking up seven directories and back down into `/etc/phpmyadmin/config-db.php`:

```
GET /admin/settings.php?page=../../../../../../../etc/phpmyadmin/config-db.php HTTP/1.1
```

I hadn't worked with LFI much before this, so I looked up what actually makes an endpoint like `settings.php?page=` vulnerable in the first place.

<details style="border: 1px solid rgba(128,128,128,0.35); border-radius: 6px; padding: 0.75em 1em; margin: 1em 0;">
<summary style="cursor: pointer; font-weight: 600;">What I looked up: how LFI actually works</summary>
<div markdown="1" style="margin-top: 0.75em; padding-top: 0.75em; border-top: 1px solid rgba(128,128,128,0.25);">

It comes down to a script trusting a path the user controls. Something like `include($_GET['file'])` pulls in and runs whatever that parameter points to, without checking that it stays inside an expected folder. `../` sequences exploit that directly: each one walks the include one directory up, so stacking enough of them steps clean out of the web root and back down into wherever the target file actually lives on disk, `/etc/passwd` being a common test target since it's readable on pretty much any Linux box.

What comes back depends on what's on the other end. A plain config file just gets read out, which is what happened in this room, phpMyAdmin's own database credentials landing in the response. But if the same include can be pointed at a file the attacker controls instead, a poisoned log entry, an uploaded image with PHP code tacked onto it, reading a file turns into running one, and LFI stops being information disclosure and becomes code execution.

</div>
</details>

The expanded document confirms the request landed on the real host, `slingwayweb`, going after phpMyAdmin's own database config file, credentials for the database itself.

<img src="/assets/img/posts/slingshot/slingshot_06.png" width="700" alt="Expanded document confirming the LFI request against config-db.php, hostname slingwayweb, method GET">

**The SQL injection.** The last piece was figuring out which database got read from and written to. I didn't have a direct filter for that yet, so I guessed SQL first, phpMyAdmin was already in the picture from the LFI, and searched for anything hitting `import.php`. That was the right guess: the request body is a raw SQL injection, an `INSERT INTO` against a `credit_cards` table sitting inside a `customer_credit_cards` database, padding placeholder values into `card_number`, `cardholder_name`, `expiration_date`, and `cvv` columns.

<img src="/assets/img/posts/slingshot/slingshot_07.png" width="700" alt="Request body showing a raw SQL INSERT INTO credit_cards, submitted through phpMyAdmin's import.php">

A second hit against the same endpoint carries the same query again, further confirmation this wasn't a one-off test but the actual exfiltration path the attacker used against phpMyAdmin's SQL import feature once they had the database credentials from the LFI step.

<img src="/assets/img/posts/slingshot/slingshot_08.png" width="700" alt="A second import.php request repeating the same SQL INSERT, confirming the exfiltration path against the credit_cards table">

**What I'd actually want fixed here.** Every step in this chain traces back to one missing control. Hydra got working credentials because `admin-login.php` never rate-limited or locked out repeated failed attempts, that's the kind of gap a handful of `response.status: 401` events from the same source in a short window should catch on its own. The upload endpoint accepted a `.php` file with no extension or content-type check, an upload feature that needs to exist at all should whitelist file types server-side, not just trust the client. The LFI held because `settings.php?page=` passed user input straight into an include with no allow-list of valid pages, `../` sequences in a URL parameter is cheap to flag. And the SQL injection succeeded because phpMyAdmin's raw SQL import feature was reachable at all from an app-admin session, that's an access-control question as much as an input-validation one, a database admin tool shouldn't be one stolen cookie away from a compromised web app. None of these needed a zero-day, they needed basic input handling and access separation that wasn't there.

## Lessons Learned

I didn't stumble into this room, I picked it on purpose to get better at KQL. I'd already spent time on TryHackMe's [Regular Expressions](https://tryhackme.com/room/catregex) room and the [RegEx Learning](https://apps.apple.com/de/app/regex-learning/id6744048728) app beforehand, and gone through the [Advanced ELK Queries](https://tryhackme.com/room/advancedelkqueries) room once on its own, specifically to build up query syntax I could actually reach for instead of just recognizing when I see it. This room was the next rung on that same ladder: working mostly through the field sidebar and short, specific filters instead of one long query, which is still slower than someone fluent in KQL would be, but it's real practice against a real log corpus, not a tutorial.

The attack chain itself, once reconstructed, wasn't complicated: weak credentials, a webshell upload, LFI into a config file, SQL injection through an admin tool, one step feeding the next. I had to look up how LFI actually works, but not because the room's traversal payload was clever, `../` repeated a few times isn't a hard idea. What made this room worth doing wasn't the attack's difficulty, it was that reconstructing it from logs instead of running it live is a different skill, and specifically the one I came here to practice.

## References

- [TryHackMe Room — Slingshot](https://tryhackme.com/room/slingshot)
- [TryHackMe Room — Regular Expressions](https://tryhackme.com/room/catregex)
- [TryHackMe Room — Advanced ELK Queries](https://tryhackme.com/room/advancedelkqueries)
- [RegEx Learning app](https://apps.apple.com/de/app/regex-learning/id6744048728)
- [CyberChef](https://gchq.github.io/CyberChef/)
