# Radar Suite

![Last commit](https://img.shields.io/github/last-commit/Terryc21/radar-suite) ![Stars](https://img.shields.io/github/stars/Terryc21/radar-suite?style=flat) ![Issues](https://img.shields.io/github/issues/Terryc21/radar-suite) ![Release](https://img.shields.io/github/v/release/Terryc21/radar-suite) ![License](https://img.shields.io/github/license/Terryc21/radar-suite) ![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)

**Audit skills for Claude Code that catch iOS/macOS bugs other tools miss — by tracing how data flows through your app, not by matching code against a checklist.** Every finding cites a real `file:line` in your code and is rated on a 9-column severity table. A capstone skill aggregates findings into a ship-or-don't-ship grade.

Built while shipping [Stuffolio](https://stuffolio.app) (Universal iOS/iPadOS/macOS app, currently build 33). Free, open source, Apache 2.0.

> **New to Claude Code skills?** Start with [README-newer-dev.md](README-newer-dev.md) for a gentler walk-through. The doc below assumes you already work with Claude Code daily.

## TL;DR

- **What:** 8 skills (6 domain auditors + a router + a foundation skill) that trace behavior through Swift codebases to find bugs single-file linters can't see.
- **Why:** Pattern-based audits check each bolt is torqued; behavioral audits turn on the shower and check where the water actually goes. Different layer, different bugs.
- **Install:** Two `/plugin` commands in Claude Code; then `/radar-suite` is available in any project.
- **Try first:** `/radar-suite ui-enhancer --scope <small directory>` — ~5 min, one report to look at.
- **Calibrated:** public [fidelity log](MISSED-IT-BY-THAT-MUCH.md) of real misses and false positives; "[What it can't catch](#honest-limits)" section enumerates structural blind spots.
- **Maturity:** v2.1.0 shipped; used through real App Store submission cycles on a 600-file Swift codebase; CHANGELOG tracks every release.

## Calibrated honesty (read this before installing)

I keep [**MISSED-IT-BY-THAT-MUCH.md**](MISSED-IT-BY-THAT-MUCH.md) — a public log of cases where Radar Suite missed a real bug or flagged something that wasn't a problem. The entries are specific (this commit, this file, this finding) and unflattering. Reading it gives you a calibrated sense of false-positive and false-negative rates rather than a marketing pitch about accuracy.

Most pattern-based audit skills don't keep this kind of log because doing so requires admitting their detection patterns aren't complete. Radar Suite's domains are explicitly tagged `grep-sufficient`, `enumerate-required`, or `mixed`, which forces the question of which findings could have been missed and why.

## Why behavioral, not pattern-based

Most code-quality skills compare your code against a rule catalog: force unwraps, missing `@MainActor`, `try?` swallowing errors, deprecated APIs. Fast, precise, context-free. They catch a real class of bugs but miss anything that doesn't compress into a single-file pattern.

Radar Suite traces behavior. It starts from what the user sees (a screen, a flow, a backup round-trip) and follows the data through views, view models, managers, and persistence to verify the loop actually closes. A file can pass every pattern check and still contain a bug only visible in the trace.

Concrete: a SwiftData `@Model` with a non-optional inverse relationship will pass every pattern audit. A backup-restore-edit-save cycle that loses one of those relationships will not. The first scan finds nothing; the second flags the silent loss with a citation to the line where the inverse keypath is declared and the line where the restore reads it back without the inverse.

Useful framing: pattern-based skills are the building inspector confirming each bolt is torqued to spec. Radar Suite is the home inspector who turns on the shower and checks where the water actually goes. Different layer, different bugs. A thorough audit uses both.

## What's in the bundle

Eight skills total: six domain auditors, a router that orchestrates them, and a foundation skill that runs implicitly before any finding is emitted.

| Skill | Domain |
|---|---|
| `data-model-radar` | SwiftData / Core Data definitions across nine domains: field completeness, computed property correctness, serialization coverage with intentional-exclusion framework, relationship integrity (including cross-context mutation and stale-object detection), semantic clarity, field usage mapping, migration safety, cross-model consistency, near-duplicate model detection. Risk-ranks the model inventory so you know which to audit first. |
| `time-bomb-radar` | Code that compiles and ships fine but breaks later on aged data. Cascade deletes with live child references, cache expiry that fires wrong, trial paths, background tasks, date-transition edge cases, scheduled side effects. The class of bug that doesn't fail in tests because tests run on fresh data. |
| `ui-path-radar` | Navigation correctness. Enumerates every routing case, traces reachability, flags orphan features (in code but not in any menu), dead ends, broken back links. 32 issue categories. |
| `roundtrip-radar` | Data integrity through complete user journeys. Backup→restore, export→import, create→edit→save. Catches collection narrowing (arrays silently lose elements), bridge parity gaps (multiple consumers of the same model read different field subsets), and silent loss anywhere in the loop. Each finding cites the full UI→manager→model→persistence→UI path. |
| `ui-enhancer-radar` | Visual quality. 13 domains including iPad sheet sizing (audits caller-side `.sheet(...)` for missing `.presentationSizing(.page)` / `.presentationDetents([.large])` / project convenience modifiers), Button hit region (three-factor detector for `.buttonStyle(.plain)` + trailing chevron + Form/List context — the combination that collapses tap targets on iPad), color contrast, spacing, typography. |
| `capstone-radar` | Aggregates findings from the others into a two-section report: "Fix Before Shipping" (release-blocking; A-F grade) and "Hygiene Backlog" (everything else; doesn't affect grade). Tracks velocity over time and celebrates fixes between runs. |
| `radar-suite` | Router. Invokes individual skills, runs targeted pipelines (`--changed` selects skills from your git diff), or runs the full sweep (`--full`). |
| `axis-classification` (foundation) | Runs implicitly before findings are emitted. Enforces the verification checklist (reachability trace, whole-file scan, branch enumeration, pattern citation lookup), the schema gate (rejects findings without file:line citations), and the 3-axis classification framework. You don't invoke it directly. Documented in [README-v2-detailed.md](README-v2-detailed.md) for readers who want the spec. |

## Install

Two commands in Claude Code, run one at a time:

```
/plugin marketplace add Terryc21/radar-suite
```

```
/plugin install radar-suite@radar-suite
```

> **Why two commands?** Claude Code's slash-command dispatcher treats the second `/plugin` as text inside the first command. Run them one at a time.

After installing, try:

```
/radar-suite ui-enhancer --scope <small directory>
```

This runs one skill on a narrow scope. Should finish in ~5 minutes and give you a real report to look at — small enough commitment to evaluate whether Radar Suite is worth a bigger run.

The plugin manifest at `.claude-plugin/plugin.json` is the single source of truth for which skills ship; `.claude-plugin/verify-manifest.sh` detects drift between manifest and disk. If you cloned this repo and ran `./install.sh` between 2026-03-24 and 2026-04-10, your install was silently incomplete — re-run `install.sh` or switch to the plugin path. Details in [README-v2-detailed.md](README-v2-detailed.md#installed-between-2026-03-24-and-2026-04-10-re-run-installsh-or-switch-to-the-plugin).

## Cost-aware run strategy

Radar Suite is deliberately thorough. It reads whole files to catch handlers that grep missed, walks call sites to verify reachability, and cites real patterns from your codebase rather than generic advice. That thoroughness costs tokens — meaningfully more than a single-file linting skill.

Three tiers, in order of token cost:

**1. Single skill** — default for development. Run as often as you want.
```
/radar-suite data-model
/radar-suite ui-path
```

**2. Targeted pipeline** — default for PRs. Auto-selects skills from your git diff. Typically 1-2 hours.
```
/radar-suite --changed
/radar-suite --skills dmr,tbr      # manual selection by short code
```

**3. Full pipeline** — reserve for releases. All six audit skills plus the capstone. Half-day commitment; not what you start with.
```
/radar-suite --full
```

**Cost-lowering strategies** (apply to any tier):
- **Scope to a directory:** `/radar-suite ui-path --scope Sources/Features/Auth/` — skill reads only files under that path.
- **Resume from checkpoint:** audits checkpoint after each phase; an interrupted session resumes from the last checkpoint rather than restarting.

Detailed scoping for monorepos and modular codebases: [README-v2-detailed.md](README-v2-detailed.md#scoping-audits-to-specific-areas).

## Output format

Every audit writes a markdown report to `.agents/research/YYYY-MM-DD-<skill>-<slug>.md` in your project. Every finding has:

- A short description of the issue
- File and line citations for every claim (the schema gate rejects findings without them)
- A 9-column rating table: severity, urgency, risk-of-fix, risk-of-no-fix, ROI, blast radius, fix effort, status, axis classification
- A suggested fix when one is mechanical

The 3-axis classification ranks findings as:

- **Axis 1** — release-blocking. Wrong behavior, data loss risk, crash. The capstone uses Axis-1 count to compute the ship grade.
- **Axis 2** — quality issues that should be fixed but don't block. Performance, code clarity, maintenance burden.
- **Axis 3** — hygiene. Style, dead code, opportunities for cleanup.

You decide what to fix; the skill writes the report and stays out of your code. Optional guided fix flow exists for the cases where the suggested fix is unambiguous — you approve each one before it lands.

## Honest limits

Behavioral audits have real limits. Read these before installing.

**What the audits can't catch:**

- **Bugs in the relationship between two correct files.** Cross-context SwiftData mutations, race conditions, distributed-state coordination — each individual file passes, the bug is in the handoff. The audit reads files; it can't reason about timing.
- **Business-logic correctness.** The skill verifies a button exists, that it's reachable, that its tap handler runs. It can't verify the handler does the right thing.
- **Novel bug classes.** A clean audit means zero matches for the patterns the skills know to look for. New bug shapes that haven't been added to any radar's domain list won't be caught until the next release.
- **Issues that only appear at runtime.** Memory pressure under specific conditions, threading issues that only manifest under load, OS-version-specific bugs. Static analysis has structural limits.

Treat findings as leads to investigate, not items to fix blindly. Verify critical findings before committing.

**Calibrated fidelity:** [MISSED-IT-BY-THAT-MUCH.md](MISSED-IT-BY-THAT-MUCH.md) — public log of real misses and false positives, by commit and file. Read it for the calibrated picture.

## Other Claude Code skills

Companion tools built on the same shipping-real-software loop:

- [**tutorial-creator**](https://github.com/Terryc21/tutorial-creator) — turns a file from your project into an annotated tutorial with vocabulary tracking, pre/post tests, and prerequisite gap analysis. Works for any language.
- [**prompter**](https://github.com/Terryc21/prompter) — rewrites your Claude Code prompt for clarity (resolves ambiguous references, tightens vague verbs, restructures stacked questions) before acting.
- [**bug-echo**](https://github.com/Terryc21/bug-echo) — after you fix a bug, infers the anti-pattern from your diff, validates against the pre-fix file, and scans for sibling instances.
- [**workflow-audit**](https://github.com/Terryc21/workflow-audit) — 5-layer audit of SwiftUI user flows. Pairs naturally with `ui-path-radar`; the radar enumerates routes while workflow-audit traces what a user trying to do something would experience step by step.
- [**unforget**](https://github.com/Terryc21/unforget) — consolidates deferred work (paused plans, audit findings, observed bugs) into one structured file. Radar Suite's unfixed findings become rows there.

All free, all Apache 2.0, all built while shipping Stuffolio.

## Requirements

- Claude Code (any tier; Pro works, Max is comfier for `--full` runs)
- A Swift codebase (iOS, macOS, or Catalyst)

That's the entire requirements list.

## Maintenance

```
/plugin update radar-suite
```

Radar Suite is updated regularly; check the [CHANGELOG](CHANGELOG.md) before a release-blocking audit. Bug reports and false-positive flags help calibrate the next release.

## Deeper documentation

Two longer docs:

- [README-v2-detailed.md](README-v2-detailed.md) — full reference: 3-axis classification spec, schema gate behavior, scoping strategies for monorepos, run-order recommendations, release history per skill (v2.0 → v2.3), and the design philosophy behind each radar's domain selection.
- [README-newer-dev.md](README-newer-dev.md) — gentler walk-through for readers new to Claude Code skills and audit tooling. "What is a skill, here's a small first run" framing.

## License

Apache 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Author

Terry Nyberg, [Coffee & Code LLC](https://stuffolio.app/). If Radar Suite catches a real bug for you, [a coffee](https://buymeacoffee.com/stuffolio) is appreciated. Issue reports about what worked or didn't are even more useful.
