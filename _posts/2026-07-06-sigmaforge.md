---
title: Sigmaforge — an honest backtest harness for detection rules, built by AI agents
date: 2026-07-06 09:00:00 +0200
categories:
  - Projects
  - Python
tags:
  - python
  - detection-engineering
  - sigma
  - zircolite
  - ai-agents
  - evaluation
image:
  path: /assets/img/posts/sigmaforge/cover.png
---

Same disclosure as my Shipwright post: I am not a programmer. I direct AI agents, give feedback, and decide what to accept or reject; the agents do the core build. Sigmaforge was built that way, end to end. And the most useful thing it produced was not the tool. It was a list of the ways the agents' own work was quietly wrong: results that looked right but were not. I cannot read a diff and spot a subtle bug, so I could not catch those myself. What caught them was an independent review agent, the Skeptic, whose only job is to distrust the work before I accept it.

This is the honest version of that, including the parts that are not finished. The harness started barely working and grew into something with a real attack corpus, a command-line interface, and a PyPI release. Along the way it also produced one honest negative result that turned out to be as useful as any feature.

## The Problem

A Sigma rule is a detection pattern, written in YAML. SigmaHQ ships thousands of them. The question almost nobody answers per-rule: does a given rule actually catch the attack it targets (recall), and how often does it fire on normal day-to-day activity (false positives)? Without measuring both, "we have detections" is a guess with a progress bar.

I wanted a harness that runs rules against labeled attack logs and against normal-activity logs and reports, honestly, what each rule does, including saying "I cannot measure this" when that is the truth.

## What It Does

You install it and run it:

```bash
pip install sigmaforge
sigmaforge manual        # the bundled reference, rendered in the terminal
```

There are two commands, split by a rule I could not get around: **you cannot compute recall or precision without ground-truth labels.** So the tool has two honest modes instead of one dishonest one.

- `sigmaforge hunt --rules R --logs L` runs rules over **any** logs and lists the hits. It needs the engine but no labeled corpora, so it works straight after `pip install`. Because the logs are unlabeled, it prints `precision/recall = unmeasured — unlabeled corpus`. It is a hit list, not a measurement, and it says so.
- `sigmaforge backtest --rules R --config sigmaforge.yaml` runs rules against the **labeled** corpora and produces the real numbers: per-technique recall, label-aware precision, the honesty gates, a Markdown report and a JSON manifest. With no corpora configured it does not crash. It prints what to fetch and points you back at `hunt`.

The detection engine is [Zircolite](https://github.com/wagga40/Zircolite), which runs Sigma rules over Windows event logs. The recall corpus is now [splunk/attack_data](https://github.com/splunk/attack_data) (Apache-2.0), foldered by ATT&CK **sub-technique**: about 24,600 process-creation events across 46 sub-techniques. The benign corpus is a blend of goodware (Nextron's baseline) and a real enterprise week (DARPA OpTC). The benign data is an Elasticsearch export with field names like `process_path`, not Sigma's `Image`, so it reads through a field mapping that had to be written by hand.

The part I care about most is still the honesty gate. A number is only reported when it can mean something; otherwise the cell reads `unmeasured`, and now it always carries a **reason code** so I know what to fix:

| reason | what it means |
|--------|---------------|
| `no-tag` | the rule has no usable ATT&CK technique tag |
| `technique-0-events` | the rule's technique has zero events in the attack corpus |
| `below-floor` | too few events were evaluated to mean anything |
| `no-benign-exemplars` | nothing in the benign corpus carried the rule's fields |

A run also writes a manifest pinning the rule set, the field-mapping hash, the corpus hashes, and a worker-invariant run hash, so a result is tied to exactly the inputs that produced it.

## How It Works

The flow: load rules, drop the ones that need cross-event correlation (those break a sharded run), compile **only those rules** into the engine, run it over each corpus, score each rule against the per-event labels, apply the gates, render the report. The scoring math is reused from `shipwright-kit` (my dev framework's eval library), and the whole pipeline now lives in one module that both the CLI and my batch scripts call, so there is no "real script" and "weaker CLI" any more; they run the same code.

But the actual engineering content of this project is not the pipeline. It is the rule I set and refused to bend: **no self-review.** Every change, and every result, goes through an independent review agent (the Skeptic) before I trust it. For someone who cannot read a diff and spot the subtle bug, an adversarial second reader is not a nicety. It is the only thing standing between me and a confident, wrong answer.

## What the Skeptic caught (the honest part)

This is the real writeup. Before I accepted any of it as done, the Skeptic caught these in the agents' work, in order:

- **Precision computed without the gate, and false positives counted without checking the event's label.** An early scoring path counted every benign-corpus hit as a false positive, but the benign corpus has some malicious-labeled events mixed in, and a hit on one of those is a true positive. A label-aware version had been written, but nothing called it; the function that actually ran was the wrong one. The tests were green because they tested the unused function.
- **A recall denominator wrong by about 23×:** it divided by all events instead of the process-creation events the rules can match.
- **A precision of 1.0 that meant nothing:** one rule showed 1.0 with zero false positives, but only because the corpus had zero benign examples of that activity. No false positives were possible, so the number carried no signal. Now flagged as a tautology.
- **A mislabeled corpus:** the benign baseline was labeled "COMISET" (a real university dataset), but ~88% of it was synthetic goodware blended in. The metric now discloses the blend.

None of these would have looked wrong to me. I would have read the green tests and the clean-looking numbers and accepted them. Catching them is not my contribution; insisting that nothing ships on the agents' word alone is.

Three more bugs took longer to fix than to find. The agents fixed them under direction. Real work, not a victory lap:

- **Recall is now per-technique.** It used to divide every rule by the same corpus-wide total, so a rule that perfectly caught its one technique still showed ~1.6%, near-zero by construction. Now each rule is scored only against the attack events of its own sub-technique, with no sibling dilution (a `T1059.001` rule is not scored against `T1059.003` events).
- **One rule source.** The engine used to fire Zircolite's bundled snapshot while a different list was scored, joined by title, which silently dropped 765 of 767 hits. Now exactly the rules that are scored are the ones compiled into the engine, so firing and scoring agree.
- **Event-ID collisions across files.** The same record ID in two files used to collapse into one and undercount recall. The identity is now a content hash, with a regression test on multi-file fixtures, the kind missing the first time.

And one new one, caught during the CLI work and **shipped live for a day**: a `pip install` of version 0.2.0 crashed with `ModuleNotFoundError: yaml` the moment you touched the config, because `pyyaml` was imported by shipped code but never declared as a dependency, and the package it relies on stopped providing it transitively. `sigmaforge version` survived because it never loads config, which was the exact path the install check happened to exercise, so the bug slipped straight through. Fixed in 0.3.0. A good reminder that "the tests pass" and "a stranger can install it" are different claims.

## The recall column finally means something

With the sub-technique corpus, **70 of the loaded rules fire on attacks of their own technique**, a column that used to be all zeros. A few honest examples: *Suspicious RDP Redirect Using TSCON* catches 5 of 5 of its events; *Suspicious MSHTA Child Process* 33 of 261; an LSASS-dump keyword rule 22 of 426. The corpus is lopsided (a handful of sub-techniques dominate the event count), so a low-population technique's recall rests on very few events, and the report says so, per rule.

## The volume trap (an honest negative result)

I assumed more benign data would make more rules measurable. So I had the benign corpus roughly **doubled**, from ~47,500 to ~97,400 real enterprise events, and the backtest re-run.

The precision-measurable count went from **7 to 8**. One rule. For twice the data.

That is not a disappointment, it is the finding: the bottleneck is not benign **volume**, it is benign **diversity**. More of the same enterprise activity adds no new field combinations for rules to be measured against, and the enterprise telemetry I pulled records process paths in a form (`\Device\HarddiskVolume1\...`, or a bare `cmd.exe`) that the path-anchored rules cannot match at all. Measuring that "more data doesn't help here, and here is exactly why" is worth more than quietly shipping a bigger corpus and implying progress.

## The one finding (hand-verified)

The harness flagged one rule, **"Suspicious Windows Service Tampering,"** firing 66 times on the benign corpus, the shape of an over-broad rule that would drown an analyst in false alarms. The count alone was not enough to believe: all 66 were read, one by one, and that review was itself Skeptic-checked before I accepted the finding.

It held up: **all 66 are genuine false positives, zero mislabels.** Every one is the **Ninite** software installer running `net stop "TeamViewer N"` to upgrade TeamViewer: 33 from the signed Microsoft `net.exe`, 33 from the `net1.exe` it spawns, across TeamViewer versions 5 through 15. The rule lines up on `OriginalFileName: net.exe` + `CommandLine` containing `stop` + the service token `TeamViewer`, with no parent-process constraint, so routine installer activity trips it. A one-line `filter:` excluding the Ninite lineage takes the false positives from **66 to 0**.

The honest limit, stated plainly: I can show the false positives drop to zero, but I **cannot** show the patched rule still catches a real attack on this data. The attack corpus contains no service-tamper event whose service name is in the rule's list, so the original rule already detected zero of it here. The fix is attack-safe by construction, but "detection intact" is argued, not demonstrated. Full analysis and the before/after rule are in the repo (`reports/finding_service_tampering.md`).

## Next Steps (honest open questions)

The big structural gaps are now closed: per-technique recall, one rule source, the event-ID fix, a real CLI, a clean `pip install`. What is left:

- A benign corpus that is **diverse**, not just big: ideally real desktop activity with normal `C:\...` paths, which is the one thing no public dataset I found provides. The likely answer is generating it in a lab.
- A value-level coverage counter, so a rule that *could* match is distinguished from one that simply had no candidate events.
- A corpus with an in-list service-tamper sample, so the Service Tampering fix can show detection is intact, not just argued.

The harness works, installs, and is honest about what it cannot yet measure. Whether it is measuring something a SOC would care about is the open question I am still answering. Saying that plainly is more useful than a precision number I cannot defend.
