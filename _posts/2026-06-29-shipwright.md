---
title: "Shipwright — a shared backbone for my security CLIs, built by AI agents"
date: 2026-06-29 09:00:00 +0200
categories: [Projects, Python]
tags: [python, devtools, ai-agents, supply-chain, prompt-injection, pypi, framework]
published: true
image:
  path: /assets/img/posts/shipwright/cover.png
  alt: "Shipwright — a shared backbone for my security CLIs, built by AI agents"
---

I should say this up front, because it shapes everything below: I am not a programmer. I direct AI agents and I decide whether to accept or reject what they produce. The three security CLIs I have written about here, `barb`, `vex` and `sift`, were all built that way, and so is Shipwright, from end to end: the agents write the code, the tests, the CI pipeline and the release tooling; my part is the direction, the decisions, and the final yes or no. Shipwright is what happened once those three tools started repeating themselves, and almost every part of building it was a concept I was meeting for the first time.

## The Problem

By the time I had three tools, I had three copies of the same security-critical code.

Each CLI had grown its own little prompt-injection filter for the text it feeds to an LLM. Each had its own scale for rendering verdicts. Each had its own code for scoring a detector against a labeled set of samples. The problem only became obvious to me when I found a gap: the injection filter in one tool was missing a jailbreak phrasing the others handled.

Fixing it meant the same change had to land in every tool separately, and not one of them could be forgotten. That was the moment it clicked for me that copied security code is a liability, not a convenience. The code whose entire job is to not miss things was the code most likely to quietly drift apart, and nothing would tell me when it had. I did not have a name for this when I started; I just had the uncomfortable feeling of fixing the same bug twice and knowing I would forget the third time.

What I did not want was to merge everything into one big project. The tools are separate, with their own users on PyPI, and I wanted them to stay that way. So the question I handed the agents was: how do you share the risky parts without gluing the tools together? Shipwright is the answer we landed on, and working it out taught me most of what I now know about how Python projects are actually shipped.

## What It Does

Shipwright is two things in one repository, and I had to learn what each one was for.

The first is an installable Python library, published to PyPI as `shipwright-kit`:

```bash
pip install shipwright-kit
# then:  import shipwright_kit
```

One of the first new ideas for me was that the library should be "import-light." An agent explained the problem: if a tool only wants the scoring code, it should not be forced to load a whole terminal-colour-and-banner stack it never uses just by typing `import`. So `import shipwright_kit` pulls in none of the heavy rendering dependencies; they load only when you actually print something. I would not have known to ask for that. Once it was explained, I could see why it mattered and insist on it.

The module that started everything is `eval`, a harness for measuring detection quality. Precision and recall I knew as words from the SOC learning path, but turning them into something that can fail a build was new to me:

```python
from shipwright_kit.eval import Sample, evaluate, gate

corpus = [Sample("phish-login", "phishing"),
          Sample("example.com", "benign")]

result = evaluate(
    lambda text: "phishing" if "phish" in text else "benign",
    corpus,
    positive_pred=lambda pred: pred == "phishing",
    positive_expected=lambda label: label == "phishing",
)
print(result.precision, result.recall)            # 1.0 1.0
gate(result, min_precision=1.0, min_recall=0.9)   # raises if below
```

The two separate "is this positive?" functions confused me at first, and I made the agent justify them before I accepted the design. The reason turned out to be concrete: in `barb` the thing the tool predicts (a verdict) and the way the data is labeled (`phishing` / `benign`) are not the same vocabulary, so each side has to be turned into a yes/no on its own. I only understood that once I saw it fail without it.

There is also a `design` module with one shared severity scale that every tool maps its own verdicts onto. It is five tiers, low to high, with output that falls back to plain ASCII where coloured Unicode is not safe:

```python
from shipwright_kit.design import Severity, tier_label, glyph

[(s.name, int(s)) for s in Severity]
# [('OK', 0), ('INFO', 1), ('NOTICE', 2), ('WARN', 3), ('CRITICAL', 4)]

tier_label(Severity.CRITICAL)          # '✗ CRITICAL'
glyph(Severity.WARN, ascii_only=True)  # '!'
```

And a `security` module, which is where my original worry finally gets a home. It holds the shared prompt-injection detector and the floors I decided the security parts have to clear: no false positives at all, and recall of at least 0.70.

```python
from shipwright_kit.design import Severity
from shipwright_kit.security.eval import is_alert, SECURITY_MIN_PRECISION, SECURITY_MIN_RECALL

is_alert(Severity.NOTICE)                    # True
SECURITY_MIN_PRECISION, SECURITY_MIN_RECALL  # (1.0, 0.7)
```

The second half of Shipwright is the framework that ships the library: a scaffolder for starting new projects, reusable CI/CD pipelines, the quality gates, and the agent skills and personas that run all of it. The repository holds no project code of its own. It runs the very gates it hands to the projects, which was the only way I could believe in them — if a gate was too painful to live with, I would feel it here first.

## How It Works

Work moves through a chain of gates, and failing one blocks the next:

```
commit → lint + unit (auto) → build → dogfood + eval (auto) →
QM gate (manual) → beta sign-off (manual) → release
```

The rule for what is allowed into the shared library is something I learned by getting it wrong: **build a feature inside one tool first, and only lift it into `shipwright_kit` when a second tool genuinely needs the same thing.** My instinct had been to generalise early, to guess at the shared version up front. That guess was usually wrong, and a wrong guess baked into a library three tools depend on is expensive to undo. Waiting for the second real user has been the better teacher every time.

The part I am proudest of understanding is how the two tools consume the injection detector. `sift` calls the shared one but keeps its own logic for pulling fields out of an alert. `vex` builds on top of it and keeps its own cleanup step — and in switching over, `vex` gained the jailbreak and prompt-exfiltration patterns it had been missing entirely. Then each repository has a test that checks its detector is still the shared one underneath. The idea that a test could assert "this is still the same code, nobody has quietly re-forked it" was completely new to me, and it is exactly the alarm the whole project needed: the drift that started this is now caught automatically instead of going unnoticed.

The framework itself is run by AI agents working from personas and skills — scaffold a project, onboard it, review a change, exercise a release against real and deliberately nasty inputs, publish it. My role is to decide and to approve. The one rule I will not bend is **no self-review**: every change is checked by a separate review agent I call the Skeptic, and nothing ships on the word of whoever wrote it. For someone who cannot read a diff and spot the subtle bug, a second reader whose job is to distrust the first is not a luxury, it is the only safety rail I have.

Supply-chain security was a whole vocabulary I had to pick up before I could approve any of it. Pinning GitHub Actions to exact commit hashes, running CodeQL, generating a software bill of materials, publishing to PyPI through an OIDC "Trusted Publisher" so there is no long-lived password to leak — each of those was a term I had to look up and understand well enough to say yes to. I leaned on the agents to propose them and on my own reading to check the proposals were not nonsense. The PyPI upload sits behind a gate that makes me approve every single release by hand, which is the part I do understand completely: I am the last check.

## Bugs Found in Testing

Honesty is the whole point of this section, so here are the real failures.

The agents built test sets that would have proven nothing, and the Skeptic caught it. More than once the labeled data an agent had assembled was wrong: mistyped positives, "misses" that were imagined rather than measured, harmless things like null hashes and private IPs marked as malicious. Any of them would have set a quality floor that looked strict and meant nothing, and on the surface it looked rigorous enough that I would have approved it. That is exactly why the Skeptic exists: the agent that builds a thing is never the agent that signs it off. The lesson I took away is one I now apply everywhere: a test set has to be honestly measured before it is allowed to gate anything, or it just manufactures false confidence.

Onboarding `sift` into the gates turned up a genuine bug in the tool that had nothing to do with the framework: a cached result was skipping the `--ticket` step. I would never have found it by hand; the heavier fuzz-testing the gates require is what shook it loose.

A subtle one that never reached me as a problem: the shared imports had been declared as development-only dependencies, so a normal `pip install` of a tool that needed `shipwright_kit` would have failed with an import error. It worked in the dev setup, which is where it would have hidden. An agent flagged it and the Skeptic confirmed it before it ever bit a user, and the fix went straight into the backlog. It cost me about five minutes of attention. What I kept was the lesson I did not have before: that "works in development" and "works when installed" are two different claims, and only the second one matters to whoever runs `pip install`.

And a naming trap I want on the record. I wanted the import to just be `shipwright`. It turns out there is already an unrelated `shipwright` on PyPI, and it also installs something called `shipwright` you can import — so installing both would have collided two different things under one name. That is why the package is `shipwright-kit` and the import is `shipwright_kit`: it keeps them apart. The repo and the name "Shipwright" stayed; only the package labels had to change. I learned what a namespace collision was by walking straight into one.

## Next Steps

The honest open question is still how much to share. Every time a second tool wants something, I have to judge whether it is really the same need or two things that only look alike, and I am still learning to tell those apart. So far, waiting for the second real user has kept me from over-sharing, and I trust that more than my urge to tidy things up early.

The next tool will be scaffolded from the template instead of assembled from scratch. That will be the first time the framework has to prove it helps at the *beginning* of a project and not only with the upkeep of one. I will write that up honestly too, including the parts where it gets in my way.
