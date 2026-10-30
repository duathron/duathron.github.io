---
title: "Building an Elastic Detection Lab Around a PCAP I'd Already Solved"
date: 2026-10-30 08:00:00 +0100
categories:
  - Projects
  - Security
tags:
  - elastic
  - detection-engineering
  - docker
  - packetbeat
  - bash
  - home-lab
image:
  path: /assets/img/posts/elastic-detection-lab/cover.png
---

## The Problem 

I'd already worked through TryHackMe's "Overpass 2 - Hacked" room: a PCAP of a real attack, read by hand in Wireshark, question by question. That's forensics, reading something that already happened. What it doesn't teach is what happens *before* someone reads the capture: how an alert gets generated in the first place, out of raw traffic, without a human already knowing what to look for.

So I set myself a second use case against the same PCAP: build a real Elastic Security stack at home, feed it the Overpass 2 traffic, and write detection rules that actually fire against it, not just a writeup that says "this would have been caught." Everything here was built and run in a home lab, on my own machine, not in a professional environment, and I want to be upfront about something before going further: this was a lab built together with Claude Code, but not in the sense of Claude writing the config and me copy-pasting it. It acted as a tutor, asking me questions, answering mine, reviewing what I wrote and pointing out where it was wrong, while I typed every line of `compose.yml`, `packetbeat.yml`, and the ingest script myself. That distinction mattered more than I expected, and I'll get to why.

## What It Does

The lab is a single-node Elastic Stack, Elasticsearch + Kibana + Packetbeat 9.5.5, running in Docker (via OrbStack on my machine, arm64). A bash script, `ingest.sh`, takes the Overpass 2 PCAP, converts it if needed, hashes it, and feeds it to Packetbeat, which writes the traffic into Elasticsearch as searchable events. On top of that sit two detection rules in Elastic Security, each built against one specific thing the attacker did:

**"mkfifo in HTTP request body"** (severity high): a custom-query rule that matches `http.request.body.content.text : *mkfifo*`. The room's own attack opens with a webshell upload, and that webshell's payload is a `mkfifo`-based reverse shell command sent over an HTTP POST body. The rule doesn't care whether `mkfifo` is dangerous on its own, it isn't, it's a normal tool for inter-process communication. What makes it worth flagging here is the context: a shell command sitting inside the body of an HTTP request to a web server has no legitimate reason to be there.

**"Suspicious connection from server over unusual port"** (severity medium): a threshold rule that fires when the server itself opens a connection to a port other than 443 or 53, grouped by destination IP and port. This one's built to catch the outbound side of the attack, the reverse shell calling back to the attacker on port 4242, and a second thing I didn't expect to find (more on that below).

Both rules are tested against the known incident capture, re-ingested, and verified through real alerts in Kibana, not something I'm claiming would work "live" without having actually run it that way.

## How It Works

### The environment, which turned out to be the bigger learning curve

Writing the two rules in Elastic's query bar took less time than getting a working stack to run them against. Docker together with OrbStack was new to me going in, and the compose file, cert setup, and Packetbeat config all had their own ways of going wrong before anything reached a rule.

`compose.yml` is Elastic's own multi-node example template, cut down to one node. A `setup` container runs once: it generates a CA and certificates with `elasticsearch-certutil`, waits for Elasticsearch to respond, and sets the `kibana_system` password, all before Elasticsearch or Kibana are allowed to start (`depends_on: condition: service_healthy`). The first real error I hit here was a misleading one: Kibana reported "detection engine permissions required" on startup, which sounds like an access problem. The actual cause, found by reading the API's own error message more carefully, was a missing encryption key: it specifically named the "Encrypted Saved Objects plugin," which maps to `XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY`, unset in `.env`. Nothing to do with permissions at all.

`packetbeat.yml` is where the actual pipeline lives: which protocols and ports to parse (HTTP's list includes 8080, which turns out to matter later), capturing the HTTP request body for multipart uploads, and two `fingerprint` processors that hash each event's identifying fields into a deterministic `_id`:

```yaml
processors:
  - add_fields:
      target: labels
      fields:
        pcap_original_sha256: ${LABELS_PCAP_ORIGINAL_SHA256}
        pcap_working_sha256: ${LABELS_PCAP_WORKING_SHA256}
  - fingerprint:
      when:
        not:
          equals:
            type: flow
      method: sha256
      fields: ["@timestamp", "network.protocol", "source.ip", "destination.ip", "source.port", "destination.port", "labels.pcap_original_sha256", "labels.pcap_working_sha256"]
      ignore_missing: true
      target_field: "@metadata._id"
  - fingerprint:
      when:
        equals:
          type: flow
      method: sha256
      fields: ["flow.id", "labels.pcap_original_sha256", "labels.pcap_working_sha256"]
      ignore_missing: true
      target_field: "@metadata._id"
```

That `_id` is what makes re-ingesting the same PCAP safe: Elasticsearch refuses to write a second document with an `_id` it already has, so running `ingest.sh` twice gives `acked: 0, duplicates: 71` instead of 71 duplicate events.

`ingest.sh` is the part I wrote during an actual bash crash course, lesson by lesson, with real mistakes along the way. Two are worth showing because they changed how I think about the language, not just the script.

First: I tried to store a command's output in a variable with `md5_original=(md5 -q $pcap_original)`, then checked it by typing `$md5_original` on its own. It printed the hash, which looked right, so I assumed it worked. Claude's read of it was that the mechanism was wrong even though the output looked correct: `name=(...)` in bash builds an *array* of words, it doesn't run anything. Typing `$md5_original` alone then executed that array as a command, which is what actually ran `md5 -q` and printed the hash. The variable held the command, not the result. `echo "$md5_original"` showed the words (`md5`, `-q`, the path) instead of a hash, which is what exposed it. The fix was `$(...)`, command substitution: `md5_original=$(md5 -q "$pcap_original")` runs the command and stores what it prints.

Second, and this one was a forensic-integrity bug, not just a syntax error: an early draft of the script converted `.pcapng` to `.pcap` with `editcap`, then checked afterward whether the converted file's path happened to equal the original's path (to avoid overwriting the evidence if someone passed in a file that already had a `.pcap` extension). The guard was correct in principle. It sat *after* the `editcap` call that would have done the overwriting. By the time the check could catch the problem, the problem had already happened. Finding this before it ever ran against the real evidence copy was the whole point of writing the crash course against a disposable file first.

```bash
sha256_original=$(shasum -a 256 "$pcap_original" | cut -d " " -f1)

filecheck=$(file -b "$pcap_original" | cut -d " " -f 1)
if [ "$filecheck" == "pcap" ]; then
	pcap_working="$pcap_original"
elif [ "$filecheck" == "pcapng" ]; then
	pcap_working="${pcap_original%.*}_converted.pcap"
	if [ "$pcap_working" == "$pcap_original" ]; then
		echo "Error: original file and converted file have the same filename." >&2
		exit 1
	fi
	editcap -F pcap "$pcap_original" "$pcap_working"
else
	echo "Error: wrong file format ($filecheck)" >&2
	exit 1
fi

sha256_working=$(shasum -a 256 "$pcap_working" | cut -d " " -f1)
```

The fixed order: name the converted file with a suffix that can never collide with the input (`_converted.pcap`), check the guard *before* calling `editcap`, hash both files, log it. Claude pointed out that this leaves two independent reasons the collision can't happen anymore, the naming rule and the explicit check, belt and suspenders, even though I'd only asked for the ordering bug to be fixed.

### Getting the ingest time onto every event

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_01.png" width="700" alt="Packetbeat JSON log showing an x509 certificate signed by unknown authority error during an early test run">

Both detection rules need a timestamp field they can run their look-back window against. The PCAP's own packet times are from July 2020, so a rule can't use `@timestamp` directly, that would mean scanning years back on every run. The field that should hold "when this got ingested," `event.ingested`, showed up as empty on every single one of the 71 events I'd written. Packetbeat's config had `pipeline: pcap-ingest` set, and testing that pipeline directly against Elasticsearch (`_ingest/_simulate`) proved it worked fine on its own. So config said use the pipeline, Elasticsearch could run the pipeline, and the actual written documents never went through it anyway. I never found out why Packetbeat itself wasn't sending the pipeline with its write requests, that's still an open question. What fixed it was going around the problem instead of through it: `index.final_pipeline` is a setting that lives on the index template rather than in the client's request. My first guess at why that mattered was incomplete, I knew it "runs always, last," but not the actual deciding point Claude filled in: any pipeline a client names in its own request can simply replace a regular pipeline, while `final_pipeline` runs after whichever pipeline ran and no client can switch it off. Setting `setup.template.settings: index.final_pipeline: pcap-ingest` in `packetbeat.yml`, then deleting the data stream so the setting applied to a freshly created backing index, got `event.ingested` into all 71 documents, no exceptions.

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_02.png" width="700" alt="Kibana Discover showing 71 documents with event.ingested now present on every one, packet time from 2020 next to ingest time from 2026">

That same fix also explained an earlier moment of confusion: Discover showed 61 events for a query that should have returned 71. Not a data problem, a time-range problem: Discover's default range only covered events from "this year," which hid the 10 events still carrying their original 2020 timestamps. Widening the range to the last 10 years brought the count back to 71. Before trusting any count out of Discover after that, I check the time range first.

### Two rules, two different stories about what "fired" means

The custom-query rule's wizard preview kept failing with a 60-second timeout whenever I set a long look-back window like "last 10 years."

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_03.png" width="700" alt="Kibana rule preview timing out after 60 seconds, with errors stamped five minutes apart showing the simulated run progress">

My first guess was that it was somehow about data volume, even with very few packets in the index. Wrong: Claude worked out the real mechanism from the error timestamps themselves, five minutes apart each. The preview doesn't just search once, it simulates a rule run at every scheduled interval across the whole window, so the cost scales with the number of runs (range divided by interval), not with how much data exists. Ten years at a 5-minute interval is roughly a million simulated runs, and those five-minute-apart error timestamps show exactly where it got stuck before giving up. A narrow 3-day window around the actual attack date found the one real hit in under a second.

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_04.png" width="700" alt="Rule preview with a narrow 3-day window around July 2020, showing exactly one alert">

The rule went live after that, scheduled every 5 minutes with `event.ingested` as its timestamp override. I re-ingested the same PCAP a few more times while testing the port rule, and the mkfifo rule picked up the POST request and alerted for real, no preview, no manual trigger, three separate times.

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_05.png" width="700" alt="A real mkfifo alert in Kibana, with three different timestamps visible: when the event happened in 2020, when it was ingested, and when the rule alerted">

That screenshot shows three different clocks on one alert: `kibana.alert.original_event.end` (2020, when the attack happened), `event.ingested` (when my script wrote it into Elasticsearch), and the alert's own `@timestamp` (when the rule noticed). Keeping those three straight in my head took a while; they're not the same thing and a rule built on the wrong one either never fires on old data or fires the moment anything is written, regardless of when it happened.

What it didn't do: alert a fourth time on a later re-ingest of the exact same PCAP into the exact same backing index. The reason is the fingerprint `_id` again. Same evidence, same index, same `_id`, and Elasticsearch has already written that document, so there's nothing new to alert on. It's not that the rule stopped working, it's that re-ingesting identical evidence into the same place produces identical documents, and the rule correctly treats "the same document" as "already handled."

### The port rule, and the thing I wasn't looking for

The reverse shell on port 4242 is raw TCP with no application protocol Packetbeat recognizes, so it only exists as a *flow* record, not a parsed transaction. Checking that flow's own timing turned up something I didn't predict:

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_06.png" width="700" alt="Kibana Discover showing the port 4242 flow with an event duration of about 10 milliseconds, despite the real shell session lasting minutes">

`event.duration` on that flow was about 10 milliseconds. The real shell session in the 2020 capture ran for minutes. The cause is a replay option in Packetbeat (`-t`, replay as fast as possible with no waiting between packets) combined with flows being timed on Packetbeat's own clock rather than the packet's original timing, so the whole multi-minute session compresses into however long the replay took. This stayed an open question rather than something I fixed: getting a flow's real packet-time duration back would mean a different tool entirely (something like Zeek, which keeps connection records tied to packet time), and that's its own project for later, not something I built.

My first instinct for the port rule itself was a denylist: block specific ports I already knew were bad, 4242 among them. Claude pointed out the obvious weakness, an attacker who picks any other port walks straight past a list like that, and pushed me toward an allowlist instead: the server rarely opens outbound connections at all, so flag everything except the few ports it has a real reason to use. Checking which ports the server actually opened turned up 443, 53, and 8080. I'd assumed 8080 was my own Elastic stack's traffic leaking in. Checking its actual destination before allowing it ruled that out: 8080 went straight to the attacker's IP, not to anything of mine.

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_07.png" width="700" alt="Rule preview showing 5 alerts split across two different time groups, flows and HTTP transactions">

That preview is where the find actually showed up: two of the five hits on port 8080 were full HTTP transactions, not just flows, fetching `index.html` and `cooctus.png` from the attacker's server. Going by the filenames, that's likely the defaced page from the room itself, "H4ck3d by CooctusClan," with the cactus mascot, though I never checked the actual fetched bytes against the page content to confirm it. Either way, the port rule, built for the reverse shell, also caught this second download, purely because the allowlist check forced me to look at where 8080 went instead of assuming it was harmless.

Suppressing duplicate alerts per destination (so the flow and the HTTP transaction for the same connection collapse into one) needs a feature locked behind an Elastic Platinum license, which this lab doesn't have.

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_08.png" width="700" alt="Kibana's alert suppression option, grayed out with a tooltip stating it requires a Platinum license or above">

The free workaround is a threshold rule: group by destination IP and port, alert once per group instead of once per document.

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_09.png" width="700" alt="Threshold rule preview showing 2 alerts, one per remote endpoint, down from 5 individual document hits">

Two alerts instead of five, one per remote endpoint. The trade-off: a threshold alert carries the group fields and a count, not the original source document, so the URL and the 2020 timestamp from that HTTP transaction aren't on the alert itself, an analyst would have to go look them up separately. For a known forensic capture that's a fine trade; for something monitored going forward, that's a real limit, not just a detail.

### What "alert identity" means for a rule you re-ingest into

<img src="/assets/img/posts/elastic-detection-lab/elastic-detection-lab_10.png" width="700" alt="All 8 alerts from both rules, with their ancestor source index and document id columns visible, showing which alerts share a source document and which don't">

Eight total alerts came out of both rules across several re-ingests. The mkfifo rule only ever alerted when the underlying document's `_id` and backing index were genuinely new (a fresh data stream, created on a different day); re-ingesting the identical document into an unchanged index produced no new alert. The threshold rule has no single source document behind each alert at all, its identity comes from the group and the run, so it alerted again every single time, regardless of whether the underlying traffic was new. Re-ingesting the same incident repeatedly, which is exactly what testing a rule against a fixed capture involves, feeds the threshold rule's alert count every time. That's alert fatigue in miniature, and it's the kind of thing these two rules, tested only by re-ingesting the same fixed capture, can hide until one of them is watching something live.

## Bugs Found in Testing

- **Misleading permission error.** Kibana's "detection engine permissions required" message was actually a missing encryption key in `.env`, nothing to do with access rights.
- **Pipeline configured but never applied.** `output.elasticsearch.pipeline: pcap-ingest` was present in Packetbeat's effective config and worked correctly when tested directly against Elasticsearch, but the documents Packetbeat wrote never went through it. Root cause unresolved; fixed by forcing the pipeline at the index-template level instead (`index.final_pipeline`), which the client can't skip.
- **Rule preview timeout on long look-back windows.** A 10-year window simulates roughly a million scheduled runs and hits Kibana's 60-second preview limit every time. A narrow window around the real event date avoids it; Kibana's own UI warns about this if you read it.
- **Flow timing doesn't reflect the original packet timing.** Replaying with `-t` (no delay between packets) compresses a multi-minute real session into a 10-millisecond flow record. Not fixed in this lab; would need a different ingest tool to preserve real connection duration.
- **Bash: array vs. command substitution.** `name=(command args)` builds an array of words and runs nothing; `name=$(command args)` runs the command and stores its output. Both can look identical at the prompt if you only check the final printed value.
- **Guard placed after the operation it was supposed to prevent.** An early `ingest.sh` draft checked for a potential evidence-overwrite collision *after* the `editcap` call that would cause it, which defeats the entire point of the guard.
- **Discover time range silently hides data.** A query that should return 71 documents returned 61 because the default range excluded the 10 events still carrying their original 2020 timestamps.

## Next Steps

- A real packet-time-preserving ingest path (Zeek's `conn.log` or similar) instead of Packetbeat flows, to get accurate connection durations without replaying in real time.
- Working out why Packetbeat's own `pipeline:` setting never reached the write requests, rather than routing around it with `final_pipeline`.
- Revisiting the port allowlist: it currently only excludes 443 and 53 by port number, which means the backdoor's own download over 443 and any DNS-tunneling traffic over 53 would both pass through unflagged. A pairing of port *and* expected destination would close part of that gap, not built yet.
- The ICMP branch of the port rule (`not destination.port : *`) is intentional but untested, since this capture has no ICMP traffic to validate it against.
- Testing what alert suppression would look like with a Platinum trial, now that the threshold-rule workaround and its limits are understood firsthand.

## References

- [Elastic Security documentation](https://www.elastic.co/guide/en/security/current/index.html)
- [Packetbeat reference](https://www.elastic.co/guide/en/beats/packetbeat/current/index.html)
- [TryHackMe Room — Overpass 2 - Hacked](https://tryhackme.com/room/overpass2hacked), the PCAP this lab is built around. See the [full writeup](/posts/overpass2/) for how the attack itself was originally read by hand.
