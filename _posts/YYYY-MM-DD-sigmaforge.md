---
title: "Sigmaforge — an honest backtest harness for detection rules, built by AI agents"
date: YYYY-MM-DD 09:00:00 +0200
categories: [Projects, Python]
tags: [python, detection-engineering, sigma, zircolite, ai-agents, evaluation]
image:
  path: /assets/img/posts/sigmaforge/cover.png
---

Same disclosure as my Shipwright post: I am not a programmer. I direct AI agents and decide what to accept or reject. Sigmaforge was built that way, end to end. And the most useful thing it produced was not the tool — it was a list of the ways I was quietly fooling myself, each caught by an independent review agent whose only job is to distrust my results before I believe them.

This is the honest version of that, including the parts that are not finished.

## The Problem

A Sigma rule is a detection pattern, written in YAML. SigmaHQ ships thousands of them. The question almost nobody answers per-rule: does a given rule actually catch the attack it targets (recall), and how often does it fire on normal day-to-day activity (false positives)? Without measuring both, "we have detections" is a guess with a progress bar.

I wanted a harness that runs rules against labeled attack logs and against normal-activity logs and reports, honestly, what each rule does — including saying "I cannot measure this" when that is the truth.

## What It Does

Sigmaforge takes a set of Sigma rules plus two labeled log corpora and produces per-rule numbers:

- **Recall** from a native-EVTX **attack** corpus (EVTX-ATTACK-SAMPLES) — does the rule fire on the known-malicious events?
- **Precision / false-positive rate** from a **benign** corpus — does it fire on normal activity?

The detection engine is [Zircolite](https://github.com/wagga40/Zircolite), which runs Sigma rules over Windows event logs. It reads native EVTX directly, and reads the JSON benign corpus through a field mapping I had to write by hand (the benign data is an Elasticsearch export with field names like `process_path`, not Sigma's `Image`).

The part I care about most is the honesty gate. Precision is only reported for a rule when two things hold: a pinned known-malicious "positive control" event actually fires (proving the field mapping isn't silently broken), and the rule's selection fields were present in enough events to mean anything. Otherwise the cell reads `unmeasured` — never a clean-looking number that isn't real.

```python
def precision_or_unmeasured(score, min_events):
    if score.events_evaluated < min_events:   # not enough events to mean anything
        return "unmeasured"
    denom = score.tp + score.fp
    return score.tp / denom if denom else "unmeasured"
```

A run also writes a manifest pinning the rule set, the field-mapping hash, the corpus hashes, and a worker-invariant run hash, so a result is tied to exactly the inputs that produced it.

## How It Works

The flow is: load rules → filter (drop the rules that need cross-event correlation, since those break a sharded run) → run the engine over each corpus → score each rule against the per-event labels → apply the gates → render a report. The scoring math is reused from `shipwright-kit` (my dev framework's eval library) rather than re-derived, so the precision/recall definitions are the same ones my other tools are tested against.

But the actual engineering content of this project is not the pipeline. It is the rule I set and refused to bend: **no self-review.** Every change, and every result, goes through an independent review agent — I call it the Skeptic — before I trust it. For someone who cannot read a diff and spot the subtle bug, an adversarial second reader is not a nicety. It is the only thing standing between me and a confident, wrong answer.

## What the Skeptic caught (the honest part)

This is the real writeup. In order, the review agent caught me shipping:

- **Precision computed without the gate, and false positives counted without checking the event's label.** My first scoring path counted every benign-corpus hit as a false positive — but the benign corpus has some malicious-labeled events mixed in, and a hit on one of those is a true positive, not a false alarm. The label-aware version existed in the code but nothing called it; the function that actually ran was the wrong one. Tests were green because they tested the unused function.
- **A recall denominator wrong by about 23×.** I was dividing by all events in the attack corpus instead of the process-creation events the rules can actually match.
- **A precision of 1.0 that meant nothing.** One rule showed 1.0 with zero false positives — but only because the corpus contained zero benign examples of that activity for it to false-positive on. No false positives were possible, so the number carried no signal. It is now flagged as a tautology rather than presented as "FP-resistant."
- **A corpus I had mislabeled.** I called the benign baseline "COMISET" (a real university-network dataset), but about 88% of it was synthetic goodware I had added to make it bigger. The metric is now `precision@combined-benign` with the blend disclosed, not a pretend "real university traffic" number.

And then the ones I have **not** fixed yet, which are why I will not put per-rule numbers in front of anyone:

- **Recall is pooled across all techniques.** Every rule's recall divides by the same total, so a rule that perfectly catches its one technique still shows about 1.6% — it is near-zero by construction, not because the rule misses. It needs to be per-technique.
- **The engine runs one rule set while I score another.** The engine fires Zircolite's bundled rule snapshot; I then match results back to my rule list by title. The engine logged 767 benign hits; my scoring reported 2, because everything outside my title-filtered set was dropped. So "only 2 of 609 rules fired" is partly an artifact of that mismatch, not a clean fact.
- **Event IDs collide across files**, which can quietly undercount recall, and my tests never caught it because they only ever used single-file fixtures.

Every one of these would have looked fine to me. I am writing them down because the honest list is the actual deliverable here — it is what I learned, and it is the thing a detection engineer would actually want to see.

## The one finding (hand-verified)

The harness flagged one rule, **"Suspicious Windows Service Tampering,"** firing 66 times on the benign corpus — the shape of an over-broad rule that would drown an analyst in false alarms. So I read all 66, one by one, before believing it.

They held up: **all 66 are genuine false positives, zero mislabels.** Every one is the **Ninite** software installer running `net stop "TeamViewer N"` to upgrade TeamViewer — 33 from the signed Microsoft `net.exe`, 33 from the `net1.exe` that `net.exe` always spawns, across TeamViewer versions 5 through 15. The rule lines up on `OriginalFileName: net.exe` + `CommandLine` containing `stop` + the service token `TeamViewer` (a broad remote-admin product in the rule's service list), with no parent-process constraint — so routine installer activity trips it. The rule's own `falsepositives:` note anticipates exactly this.

A one-line `filter:` excluding the Ninite installer lineage takes the false positives from **66 to 0**.

The honest limit, stated plainly: I can show the false positives drop to zero, but I **cannot** show the patched rule still catches a real attack on this data — the attack corpus happens to contain no service-tamper event whose service name is in the rule's hard-coded list, so the *original* rule already detected zero of it here. The fix is attack-safe by construction (the Ninite lineage appears nowhere in the attack set), but "detection intact" is argued, not demonstrated. And the benign corpus is ~88% goodware installers, so this is an over-broad-on-installer-traffic finding, a tuning candidate — not a claim about a real SOC's false-positive rate. Full analysis, the before/after rule, and the evidence are in the repo (`reports/finding_service_tampering.md`).

## Next Steps (honest open questions)

- Find a corpus with an in-list service-tamper sample, so the Service Tampering fix can show detection is intact (not just argued).
- Per-technique recall, so the recall column means something.
- One rule source: compile only the rules I score into the engine, so firing and scoring agree.
- A value-level coverage counter, so more than two rules are actually measurable.
- A benign corpus that is real enterprise traffic, not goodware installers.
- Reproducible from a clean clone — right now too much lives only on my machine.

The harness works. Whether it is yet measuring something a SOC would care about is the open question I am still answering. Saying that plainly is more useful than a precision number I cannot defend.
