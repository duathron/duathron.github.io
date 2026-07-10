---
title: "Auditing barb, vex, sift against the OWASP LLM Top 10 — and the security layer we refused to build"
date: 2026-07-10 09:00:00 +0200
categories:
  - Projects
  - Python
tags:
  - python
  - llm-security
  - owasp
  - prompt-injection
  - output-handling
  - ai-agents
  - barb
  - vex
  - sift
published: true
image:
  path: /assets/img/posts/owasp-llm-hardening/cover.png
  alt: Auditing barb, vex, sift against the OWASP LLM Top 10 — and the security layer we refused to build
---

Same disclosure as my Shipwright and Sigmaforge posts: I am not a programmer. I direct AI agents, give feedback, and decide what to accept or reject; the agents do the core build. That includes the audit and the fix described here. My part was reading the findings, sitting in on the decision sessions, and signing off on what shipped.

## The Problem

`barb` (phishing/URL triage), `vex` (IOC enrichment), and `sift` (alert triage) each call an LLM for one thing: an advisory natural-language summary next to the deterministic verdict. Nothing about that summary drives a decision in the tool. It gets printed.

A routine smoke test on `sift` broke that assumption. I ran `sift triage --provider ollama` against a model my local Ollama install did not have. It should have failed loudly. Instead it swallowed the 404 and printed a template summary that looked exactly like an LLM one. I would have believed I got a real analysis. Nothing in the code review had caught it; I only noticed because I happened to run that exact command myself.

That single incident raised a bigger question I had not asked yet. If three of my tools lean on an LLM for output, what is my actual exposure under the [OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org)? I did not know the answer, so I asked the agents to find out: a research pass against the OWASP list, then a file-and-line audit of all three codebases.

## The Audit

The LLM output in all three tools is advisory, never authoritative. Deterministic verdicts and extracted IOCs are the source of truth; the LLM writes a paragraph a human reads. That one fact ends up deciding almost everything below. It is why "validate the LLM's output against a schema" got rejected as security theater later, and why the render path turned out to be the highest-value fix.

Triaged against the OWASP list, three categories were clearly in scope for this architecture (LLM01 Prompt Injection, LLM05 Improper Output Handling, LLM02 Sensitive Information Disclosure), four were medium (LLM09 Misinformation, LLM10 Unbounded Consumption, LLM07 System-Prompt Leakage, LLM06 Excessive Agency), and three did not apply at all: no training data, no RAG, no autonomous agency anywhere in these tools (LLM03, LLM04, LLM08).

The file-and-line pass against the in-scope and medium categories turned up seven concrete gaps:

| # | Gap | OWASP | Where |
|---|-----|-------|-------|
| 1 | `barb` called the LLM with zero injection scan and no boundary between data and instructions | LLM01 | `barb/explain/llm.py`, `explain/prompt.py` |
| 2 | LLM text rendered through Rich with `markup=True` and no ANSI/control-character stripping; markdown output unescaped too, a stored-injection sink into Jira/Confluence, not just the terminal | LLM05 | sift `formatter.py:210`, barb `formatter.py:102`, vex `formatter.py:555/581`, sift `md.py:176` |
| 3 | `sift`'s Ollama call had `timeout=None`: an unbounded hang | LLM10 | `sift/summarizers/ollama.py:146` |
| 4 | Provenance disclaimer shown backwards on failure vs. success, inconsistently across tools | LLM09 | fleet render layers |
| 5 | No output schema validation on `barb`/`vex` | LLM05 | barb/vex explain paths |
| 6 | No general PII/secret redaction before submitting the prompt | LLM02 | fleet prompt-build |
| 7 | `vex` caches the explanation in cleartext, with a cache key not tied to the redaction ruleset version | LLM02 | `vex/ai/cache.py` |

Seven gaps is a worse number than I wanted to see. It is also the honest one, so it stayed in the post.

## Decision One: Fail Loud, Not Quiet

Both of the decisions in this post went through a MeetUp: a set of independent agent personas argue a decision from different angles, with anonymous peer critique and recorded dissent, gated at the end by an independent Skeptic whose only job is to try to break the outcome.

My first instinct after the `sift`/Ollama incident was to add an interactive prompt: fall back to a template or abort, ask the analyst. The room talked me out of it, and the argument was hard to dispute once I saw it. These tools run unattended, piped into SOAR playbooks. Standard input is already the data (the tool reads it to EOF before it ever calls the LLM), so a mid-run `input()` call is structurally impossible in that mode. Worse, an interactive prompt does nothing for whatever is consuming the JSON output, which is where the actual deception happens. The masquerade lives in the machine channel, not the human one.

What shipped instead: never silently substitute a template for a requested LLM call. Loud stderr, an additive machine-readable marker, and exit code 4, kept separate from the 0/1/2/3 verdict codes `barb` already used. That incidentally fixed a second bug, where a crashed LLM call in `barb` exited 1 and collided with `barb`'s own "SUSPICIOUS" verdict code. A crash was reading as a real finding. Default posture is now fail-loud abort; the interactive flag got demoted to a deferred, TTY-gated option nobody has built yet.

## Decision Two: The Facade We Didn't Build

The second MeetUp was the harder one, and it is the part of this I'd actually recommend reading if you build anything that shells out to an LLM. The proposal on the table was a shared enforcing wrapper: route every LLM call in the fleet through one guarded transport that scans, redacts, and escapes before anything reaches a model. It sounds like the responsible thing to build. The room voted it down, 8 to 1, on a single piece of evidence: shipped code already called the raw transports directly in more than one place. `sift`'s Ollama call and `barb`'s explain path both bypassed any wrapper that existed. A guard that already has code walking around it isn't a floor, it's a suggestion, and building a nicer version of the same suggestion doesn't fix that.

So the ruling went the other way. `shipwright_kit.llm` stays a dumb transport. Redaction, injection scanning, and render safety are the caller's job, enforced by a tested invariant per tool, not by routing through a gate that can be skipped. What was worth sharing got promoted to the library only after clearing a "does a second consumer actually need this" bar: `safe_render()` for the output-escaping fix, and the existing injection detector that `barb` now also uses. Everything single-consumer, like the Ollama timeout value or the cache versioning, stayed local to its own tool.

Two more decisions from that session are worth stating plainly, because they were rejections, not additions:

- Schema-validating the LLM's output got reclassified from a security control to a robustness nicety. `barb` and `vex` return a bare string that only ever gets printed. There's no parser downstream and no control-flow path that string can hijack. Wrapping it in a schema invents a contract that doesn't exist and doesn't buy anything real.
- A default-on PII redaction pass got rejected outright, because it would have blinded the tools to the exact things they are supposed to triage: emails, IPs, hashes are IOCs, not incidental noise to scrub. Redaction stays scoped per tool to an explicit IOC allowlist.

One dissent is worth recording as-is rather than smoothing over: the persona arguing from first principles voted against the whole approach, on the grounds that per-tool invariants mean a fourth tool has to re-derive the same wiring from scratch. The room agreed that's a real cost, and recorded the re-open trigger for it: the day a fourth tool needs the same scan-redact-render pipeline, build the composed helper. Not before.

## What Shipped

| Package | Version | Change |
|---|---|---|
| `shipwright-kit` | 0.12.0 | New `security.safe_render()`, stdlib only, strips ANSI/OSC/control characters, escapes Rich markup, plus a plain-text `escape_markup` path for non-Rich sinks. |
| `sift-triage` | 1.4.0 | Ollama timeout bounded; `executive_summary` escaped at both console and markdown output. |
| `barb-phish` | 1.8.0 | Joins the shared injection detector as its third consumer, with a redact-then-submit boundary and a data-not-instructions system prompt; explanation escaped at both render sinks. |
| `vex-ioc` | 1.8.0 | Explanation escaped at all four render sinks, scoped per field so trusted severity-color markup keeps working. |

All three tools now pin `shipwright-kit>=0.12.0`. Every one of these went through the same Skeptic gate before merge.

The detail that actually mattered in implementation, and the kind of thing I would have gotten wrong on my own: the escape has to be scoped to the LLM-sourced field only. The same formatter legitimately uses `markup=True` for its own severity-color spans elsewhere, so a blanket escape would have broken those. It also can't touch the injection detector's own `[REDACTED: ...]` markers, or the fix would eat its own evidence.

## Testing Traps

The QA-focused persona in the review caught three ways a test suite could pass for the wrong reason, and all three would have let a real bug through:

- An injection test that only asserts `spy.called` stays green even against redaction that does nothing. You have to assert the malicious marker is actually absent from the bytes that go out, not just that some function got invoked.
- A markup-escape test run in non-TTY CI can pass because Rich silently turns markup off outside a terminal, not because the escaping works. Forcing `Console(force_terminal=True, record=True)` and adding a mutation check catches that.
- One `vex` config test patched `Path.home`, which does nothing, because the actual path is frozen at import time in a module attribute. It has to patch `vex.config._USER_CONFIG_PATH` directly. This was a real wrong-reason-green from earlier work, not a hypothetical.

## What's Still Open

- The provenance/disclaimer fix is render-only for now. Nothing security-related is going into `-o json`: a SOC analyst on the review flatly blocked that, because it would break the machine contract a playbook parses.
- `vex`'s cache key needs to tie to the redaction ruleset version. Blocked on giving `AICache` an injectable `db_path` first, so a fix here doesn't risk polluting the real `~/.vex/ai_cache.db` during tests.
- Per-tool, IOC-allowlisted PII redaction needs its own spec. Still a gap, just a scoped one now.
- SSRF wiring stays gated until Ollama's `base_url` is actually configurable.
- The TTY-gated `--on-llm-failure` flag and a shared errors helper are both deferred, not built.

Seven gaps went in, five are shipped, one is deliberately rejected as theater, the rest are honestly still open. If I'd let the agents just say "we hardened the fleet," that would have been the easy version and the wrong one. The part of this worth remembering isn't the fix. It's that the review caught a wrapper that looked like safety and wasn't one, and the fix that actually shipped was smaller and less impressive than the one that got voted down.

## Lessons Learned

Going in, I already understood one specific thing: `barb`, `vex`, and `sift` reason about attacker-controlled text (URLs, IOCs, alert bodies) as their actual job. Prompt injection aimed at that input felt like an obvious thing to check for, and gap #1 (`barb` had zero injection scan at all) confirmed I was right to worry about it there.

What I had not considered, until the smoke test forced the question, is that the LLM call itself is a separate attack surface from whatever the tool is built to detect. Scanning the input a tool processes for injection, and making sure what a tool sends to and renders from its own LLM is safe, are two different problems. I only started asking about the second one because a silent failure happened to break in front of me, not because I thought to look for it.

That leaves an honest caveat on the word "hardened" in this post's title. These three tools are hardened against the seven gaps this specific audit found under the OWASP LLM Top 10 list an agent brought me, not against every way an LLM integration can go wrong. I would not have known to ask about that second list at all if a silent failure hadn't broken in front of me first.
