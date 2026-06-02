# docsmith — Design Spec

**Date:** 2026-06-01
**Status:** Approved (design)
**Author:** Christian Huhn (duathron) + Claude

## Problem

`barb`, `vex`, and `sift` are three actively-developed Python security CLIs that
gain features constantly. Their documentation (README, user manual, feature
explainers, in-repo `docs/`) needs to stay technically accurate, broadly
understandable, visually polished, and consistent across all three tools. No
agent currently has a single, grounded process for producing that documentation.

`docsmith` is a skill that lets any agent write a manual, README, feature
explainer, or `docs/` page for these tools — technical yet plainly readable,
with design treatment (verdict color-coding, admonitions, badges, diagrams) and
hard guardrails against inventing or overstating behavior.

## The three tools (context)

| Tool | What it is | Verdict scale | Hard security invariant |
|------|-----------|---------------|--------------------------|
| **barb** | Heuristic phishing URL analyzer (12 analyzers, offline core) | SAFE → LOW_RISK → SUSPICIOUS → HIGH_RISK → PHISHING | **Never makes HTTP requests to the analyzed URL** |
| **vex** | IOC enrichment hub (VirusTotal + AbuseIPDB/Shodan/WHOIS) | CLEAN → UNKNOWN → SUSPICIOUS → MALICIOUS | Secondary enrichers **fail-open**, no-op without a key; never leak restricted TI |
| **sift** | SOC alert triage summarizer (cluster + prioritize + AI summary) | (priority tiers / cluster severity) | **Works fully offline** (rule-based core); AI is opt-in, no data to cloud without consent |

Pipeline: **barb → vex → sift** (key loop sift ↔ vex). Stack: Python 3.11+,
Typer, Rich, Pydantic v2. Canonical per-tool facts live in each tool's
`STATUS.md` / `CONTEXT.md` / `DECISIONS.md` under `AI/PROJECTS/CODING/<tool>/`.

## Scope

**In scope** — the skill produces, on request, any of:
1. `README.md` — GitHub front page (install, quickstart, feature overview, badges).
2. Full user manual — every command, flag, output mode, exit code, examples.
3. Feature explainer — deep-dive "how it works" for one subsystem.
4. In-repo `docs/` set — index + cross-linked per-topic pages.

**Primary audiences:** SOC/DFIR end-users, portfolio reviewers, future-you.
(Deep contributor/internals API docs are *not* the primary target — explainers
aim at understanding, not extension.)

**Out of scope:** TryHackMe room writeups and portfolio blog posts (owned by the
existing `writeup` skill). LinkedIn content (owned by `socialdraft`).

## Decision: structure

**Approach A — single skill + bundled reference kit.** Chosen over skill-only
inline (context bloat, cramped templates) and per-app skills (3× maintenance,
style drift — contradicts the shared-style-guide requirement).

```
SKILLS/docsmith/
  SKILL.md                          # decision engine + 7-step workflow + triggers
  references/
    style-guide.md                  # palette, emoji legend, headings, voice, readability spine
    app-profiles.md                 # per-tool grounding cheat-sheet
    templates/
      README.template.md
      manual.template.md
      feature-explainer.template.md
      docs-index.template.md
```

The agent loads the light `SKILL.md` every invocation and pulls only the
template/reference it needs.

## SKILL.md workflow (7-step spine)

1. **Target** — determine which tool (barb/vex/sift), which artifact, which
   audience slice. Ask if ambiguous.
2. **Source-grounding gate (hard rule)** — read the tool's `STATUS.md`,
   `CONTEXT.md`, `DECISIONS.md`; run `<tool> --help` and each subcommand
   `--help` to enumerate real commands/flags/exit codes; pull the current
   version from `STATUS.md`. No command/flag/output is documented unless it
   exists in source or `--help`. No guessing, ever.
3. **Template** — pick the artifact skeleton; fill only from grounded facts.
4. **Design pass** — apply the style guide: verdict color mirroring (emoji
   swatches matching the tool's Rich palette), GitHub admonitions
   (`> [!NOTE/TIP/WARNING/CAUTION]`), shields.io badges (version/CI/PyPI/license),
   Mermaid pipeline/architecture diagrams, shared heading structure.
5. **Security-accuracy check** — preserve hard invariants verbatim (barb "never
   fetches the URL", vex "fail-open / no-op without key", sift "offline-first,
   AI opt-in"). Never soften, never overstate capability.
6. **Humanizer pass** — invoke the humanizer skill on prose only; skip code,
   tables, and command blocks. Keeps manuals from reading as AI-slop.
7. **Deliver** — write to the tool's repo (`README.md` or `docs/`) or hand back
   standalone, per request.

Conflict rule: when live `--help`/source disagrees with `app-profiles.md` or
`STATUS.md`, **live source wins** and the discrepancy is flagged to the user.

## style-guide.md — contents

- **Readability spine** (the "broadly understandable" requirement): one-line
  "what it is" → TL;DR quickstart (runnable command + real sample output) →
  progressive disclosure → define jargon on first use → every command gets an
  example + expected output → exit-code table.
- **Color coding**: emoji-swatch verdict tables mirroring each tool's Rich
  colors (🟢🔵🟡🟠🔴), admonition usage rules, badge set, Mermaid conventions.
- **Voice**: technical yet plain; short sentences; no marketing fluff;
  humanizer-aligned.

## app-profiles.md — contents

Per tool: CLI command, PyPI package name, one-line description, verdict scale +
color mapping, security invariants, canonical-facts location, pipeline role.
This is a *grounding cheat-sheet* — the agent still verifies against live source
(step 2 is authoritative on conflict).

## Standard manual skeleton

one-liner → quickstart → concepts (verdict scale, pipeline) → command reference
(purpose / syntax / flags table / example / output per command) → output modes →
exit codes → integration (barb→vex→sift) → troubleshooting / `doctor` →
security notes.

## Triggers (description frontmatter)

MUST invoke before writing any README/manual/docs/feature-explainer for barb,
vex, or sift. Trigger phrases: "document barb", "write the README for vex",
"manual for sift", "explain how X works", "docs/readme/manual für <tool>",
tool name + "docs/readme/manual".

## Guardrails (all mandatory)

1. Source-grounding gate (step 2).
2. Humanizer final pass (step 6).
3. Security-accuracy — invariants verbatim (step 5).
4. Version/status sync — pull current version + feature list from `STATUS.md`.

## Success criteria

- An agent can produce any of the 4 artifacts for any of the 3 tools without
  inventing a single flag or command.
- Output is consistent in palette, structure, and voice across all three tools.
- Security invariants appear verbatim and uncolored by hype.
- Prose passes a humanizer review.
- Docs reflect the current `STATUS.md` version, not a stale build.

## Non-goals (YAGNI)

- No auto-publishing / git commits of generated docs (agent delivers; user commits).
- No HTML/PDF rendering pipeline — Markdown only (GitHub-native render).
- No screenshot generation.
- Not a replacement for `writeup` or `socialdraft`.
