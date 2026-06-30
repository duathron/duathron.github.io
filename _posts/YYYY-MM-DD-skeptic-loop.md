---
title: "The Skeptic loop — how a non-programmer gets output from AI agents he can trust"
date: YYYY-MM-DD 09:00:00 +0200
categories: [Projects, AI]
tags: [ai-agents, agent-orchestration, code-review, evaluation, detection-engineering]
image:
  path: /assets/img/posts/skeptic-loop/cover.png
---

Same disclosure as my Shipwright and Sigmaforge posts: I am not a programmer. I direct AI agents, give feedback, and decide what to accept or reject; the agents do the core build. That sounds like it should make me powerless against bugs, and for a long time it did. I cannot read a diff and spot the subtle thing that is wrong. So how do I ship anything I am willing to put my name on?

The answer turned into a method I now use on every project, and it is the most useful thing I have learned in this whole career change. It is not a tool. It is a way of orchestrating agents so that nobody, including me, gets to mark their own homework. I call the second agent the Skeptic, and the thing that makes it work is that it runs in a loop.

## The problem: confident, plausible, and quietly wrong

The failure mode with AI agents is not that they write obvious garbage. It is the opposite. They produce output that looks right. The code runs. The tests are green. The numbers are printed in a tidy table. Everything about it signals "done."

And some of it is silently wrong in a way that no amount of reading-it-over by the same agent will catch, because the agent that wrote it has the same blind spot when it reviews it. Self-review inherits the original mistake. You get a confident second opinion from the same source that was confident the first time.

For me this is worse than for someone who can read code well, because the normal safety net (a human who glances at the diff and goes "wait, that denominator looks off") is not available to me. I would read the green tests and the clean table and accept it. That is the exact trap.

## What the Skeptic loop is

Three rules, and they are simple:

1. **A separate role whose only job is to distrust.** The Skeptic is not the builder being asked to double-check. It is an independent reviewer with one instruction: assume this is wrong until the evidence says otherwise. It verifies against primary evidence, not against the builder's summary. Does the code actually run? Does the regex actually match what the comment claims? Are the numbers real, or printed from a function that is never called? Are the tests green for the right reason?
2. **A loop, not a single pass.** Review, fix, re-review. Then again. The Skeptic reports findings, the builder fixes them, and the work goes back to the Skeptic, until a pass comes back clean with zero findings. One review pass is not enough, because the fixes themselves can introduce new problems.
3. **No self-review, and a cap.** The builder never gates its own work. The loop is bounded (I cap it at five iterations) so it converges instead of spinning forever. If it is still not clean at the cap, I stop and decide what to do, rather than shipping something on a "good enough" that nobody actually verified. On a BLOCK, nothing ships.

That is the whole thing. It is less a piece of technology than a refusal: nothing is trusted on the word of the agent that produced it.

## What it actually caught

The reason I believe in this is not theory. On Sigmaforge, my detection-rule backtest harness, every real bug was caught by the Skeptic, not by me. In order:

- **A scoring function that looked right and was never called.** A label-aware version of the false-positive math had been written, but the function that actually ran was the wrong, older one. The tests were green because they tested the unused function. I would never have caught that. The green checkmark was telling the truth about the wrong thing.
- **A recall number wrong by about 23 times.** It divided by every event in the corpus instead of just the events the rules can actually match. The number looked plausible. It was off by more than an order of magnitude.
- **A precision of 1.0 that meant nothing.** One rule showed a perfect score with zero false positives, but only because the data contained zero benign examples of that activity. No false positive was even possible, so the number carried no information. The Skeptic flagged it as a tautology rather than a result.
- **A mislabeled dataset.** A benign baseline was labeled as one well-known corpus, but most of it was synthetic filler blended in. The Skeptic made the harness disclose the blend instead of quietly reporting a clean-sounding source.

None of these would have looked wrong to me. That is the point. Catching them is not my contribution. Insisting that nothing ships until an independent agent has tried to break it is.

## Why this matters more in security

You could argue a confident-wrong result is survivable in plenty of software. A misrendered button is annoying, not dangerous. Detection and security are different, and that is why I treat the loop as mandatory here rather than nice-to-have.

A security metric you cannot defend is a liability the moment someone leans on it. If my harness reports that a detection rule "catches the attack" and that number was computed wrong, the cost is not a cosmetic bug. It is false confidence in a control that is supposed to be the thing standing between an organisation and an intruder. A rule that is believed to work and does not is arguably worse than no rule, because it stops people looking.

The recall-off-by-23x bug is the clean example. Shipped, it would have said rules were near-useless when several were fine, or the reverse. Either way, a person deciding what to trust would have been deciding on a fabricated number. In security the honest answer "I cannot measure this yet" is far more useful than a confident number that does not hold, and the Skeptic is what forces that honesty instead of letting the agent paper over the gap.

## How to set it up yourself

The method is transferable; it has nothing to do with my specific tools. If you are directing AI agents and want output you can stand behind:

- **Make the reviewer a genuinely separate role with an adversarial brief.** "Check this" is too weak; the agent will agree with itself. "Assume this is wrong and prove it against the actual code, data, and runtime" is the instruction that finds things.
- **Have it verify primary evidence, not summaries.** The builder's "all tests pass" is a claim, not proof. The Skeptic should run the thing, read the real numbers, and confirm the tests are green for the right reason.
- **Run it as a loop with a hard cap.** Review, fix, re-review until clean. Cap the iterations so it terminates. If it is not clean at the cap, that is a signal to stop and think, not to ship.
- **Never let the builder gate its own work,** and never ship on an open finding. This is the rule that does the real work, and it is the easy one to quietly break when you are tired and the thing looks done.

## What it costs, and what it does not fix

It is slower. A clean-on-first-try task now takes several passes, and most of them find something. I have made my peace with that, because the alternative is shipping numbers I cannot defend.

It is also not magic. The Skeptic is itself an agent and can be wrong, miss things, or flag a non-issue. It does not turn me into someone who can read code. What it does is move me from "I trust this agent" to "I trust this process," and for the one finding in Sigmaforge that mattered most, the 66 false positives on a single rule, I still read all 66 by hand and had that review checked too. The loop raises the floor. It does not remove the need to look.

That is the honest version. The Skeptic loop is the closest thing I have to an answer for the question I started with: how does someone who cannot read a diff ship work he is willing to defend. Not by getting better at reading diffs. By never letting one agent be the last word.
