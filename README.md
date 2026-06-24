# Radar Suite

![Last commit](https://img.shields.io/github/last-commit/Terryc21/radar-suite) ![Stars](https://img.shields.io/github/stars/Terryc21/radar-suite?style=flat) ![Issues](https://img.shields.io/github/issues/Terryc21/radar-suite) ![Release](https://img.shields.io/github/v/release/Terryc21/radar-suite) ![License](https://img.shields.io/github/license/Terryc21/radar-suite) ![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)

**Audit skills for Claude Code that find a different class of iOS/macOS bugs from what linters and pattern checkers catch — by tracing how data flows through your app across files, not by checking individual files against a rule list.** Every finding cites a real `file:line` in your code and is rated on a 9-column severity table. A capstone skill aggregates findings into a ship-or-don't-ship grade.

Use Radar Suite **alongside** your existing linter / SwiftLint / pattern-based audits — they find different things. A thorough pre-release audit runs both. See [What Radar Suite is for vs what linters are for](#what-radar-suite-is-for-vs-what-linters-are-for).

Built while shipping [Stuffolio](https://stuffolio.app) (Universal iOS/iPadOS/macOS app, currently build 33). Free, open source, Apache 2.0.

## TL;DR

- **What:** 8 skills (6 domain auditors + a router + a foundation skill) that trace behavior across files to find a class of Swift bugs that lives in handoffs between files (data flow, navigation reachability, round-trip integrity).
- **Why:** Linters find single-file pattern bugs efficiently. Radar Suite finds cross-file behavior bugs that don't show up in any one file. **Both belong in a thorough audit; neither replaces the other.**
- **Install:** Two `/plugin` commands in Claude Code; then `/radar-suite` is available in any project.
- **Try first:** `/radar-suite ui-enhancer --scope <small directory>` — ~5 min, one report to look at.
- **Worked examples:** [anonymized before/after findings](skills/radar-suite-axis-classification/coaching-examples-generic.md) — what a finding looks like, with the full schema (axis, audience, before/after, suggested fix, tradeoffs, verification log).
- **Honest limits:** [What it can't catch](#honest-limits) section enumerates structural blind spots.
- **Maturity:** v2.1.1 shipped; used through real App Store submission cycles on a 600-file Swift codebase; CHANGELOG tracks every release.

## What Radar Suite is for vs what linters are for

Radar Suite and linters are complementary, not competitive. They look at code through different lenses and find different classes of bugs. A thorough pre-release audit runs both — neither alone is sufficient.

**Pattern-based tools (SwiftLint, custom linters, single-file audit skills)** check individual files against a rule catalog: force unwraps, missing `@MainActor`, `try?` swallowing errors, deprecated APIs, naming conventions, style. They're fast, precise, run on every save, and catch a real and important class of bugs cheaply. **They will find issues Radar Suite won't** — anything that lives inside one file's text and can be expressed as a grep pattern.

**Radar Suite** traces behavior across files. It starts from what the user sees (a screen, a flow, a backup round-trip) and follows the data through views, view models, managers, and persistence to verify the loop actually closes. It catches bugs that live in the *handoff* between files: data flow gaps, navigation dead ends, round-trip integrity loss. **It will find issues linters won't** — anything that requires reading multiple files together to spot.

Concrete example of the difference: a SwiftData `@Model` with a non-optional inverse relationship is correctly declared. SwiftLint and any pattern audit will say it's fine, because the declaration is fine. A backup→restore→edit→save cycle that loses one of those relationships in the round trip is a bug, but no single file is wrong — each file's view of the data is locally correct. Radar Suite catches the silent loss by reading the round-trip path; the linter has no reason to flag it because there's nothing in any individual file to flag.

Useful framing: pattern-based tools are the building inspector confirming each bolt is torqued to spec. Radar Suite is the home inspector who turns on the shower and checks where the water actually goes. **The inspection isn't complete without both.**

| What linters do better | What Radar Suite does better |
|---|---|
| Run on every save (cheap, fast) | Run before release (deeper, slower) |
| Catch style and pattern violations | Catch behavior and data-flow bugs |
| Single-file context | Cross-file traces |
| Hundreds of well-understood rules | Domain-specific behavior verification |
| Mature ecosystem | New approach, narrower scope |

If your project already uses SwiftLint or another pattern-based audit, keep it. Radar Suite layers on top.

## What's in the bundle

Eight skills total: six domain auditors, a router that orchestrates them, and a foundation skill that runs implicitly before any finding is emitted.

| Skill | Domain |
|---|---|
| `data-model-radar` | SwiftData / Core Data definitions across nine domains: field completeness, computed property correctness, serialization coverage with intentional-exclusion framework, relationship integrity (including cross-context mutation and stale-object detection), semantic clarity, field usage mapping, migration safety, cross-model consistency, near-duplicate model detection. Risk-ranks the model inventory so you know which to audit first. |
| `time-bomb-radar` | Code that compiles and ships fine but breaks later on aged data. Cascade deletes with live child references, cache expiry that fires wrong, trial paths, background tasks, date-transition edge cases, scheduled side effects. The class of bug that doesn't fail in tests because tests run on fresh data. |
| `ui-path-radar` | Navigation correctness. Enumerates every routing case, traces reachability, flags orphan features (in code but not in any menu), dead ends, broken back links. 34 issue categories (19 automated checks). |
| `roundtrip-radar` | Data integrity through complete user journeys. Backup→restore, export→import, create→edit→save. Catches collection narrowing (arrays silently lose elements), bridge parity gaps (multiple consumers of the same model read different field subsets), and silent loss anywhere in the loop. Each finding cites the full UI→manager→model→persistence→UI path. |
| `ui-enhancer-radar` | Visual quality. 13 domains including iPad sheet sizing (audits caller-side `.sheet(...)` for missing `.presentationSizing(.page)` / `.presentationDetents([.large])` / project convenience modifiers), Button hit region (three-factor detector for `.buttonStyle(.plain)` + trailing chevron + Form/List context — the combination that collapses tap targets on iPad), color contrast, spacing, typography. |
| `capstone-radar` | Aggregates findings from the others into a two-section report: "Fix Before Shipping" (release-blocking; A-F grade) and "Hygiene Backlog" (everything else; doesn't affect grade). Tracks velocity over time and celebrates fixes between runs. |
| `radar-suite` | Router. Invokes individual skills, runs targeted pipelines (`--changed` selects skills from your git diff), or runs the full sweep (`--full`). |
| `axis-classification` (foundation) | Runs implicitly before findings are emitted. Enforces the verification checklist (reachability trace, whole-file scan, branch enumeration, pattern citation lookup), the schema gate (rejects findings without file:line citations), and the 3-axis classification framework. You don't invoke it directly. |

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

The plugin manifest at `.claude-plugin/plugin.json` is the single source of truth for which skills ship; `.claude-plugin/verify-manifest.sh` detects drift between manifest and disk. If you cloned this repo and ran `./install.sh` between 2026-03-24 and 2026-04-10, your install was silently incomplete — re-run `install.sh` or switch to the plugin path.

## Cost-aware run strategy

Radar Suite is deliberately thorough. It reads whole files to verify behavior across them, walks call sites to verify reachability, and cites real patterns from your codebase rather than generic advice. That thoroughness costs tokens — meaningfully more than a single-file linter run.

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

### Reading the reports

The 9-column rating table needs a wide terminal (~180 chars) to render as a horizontal table. In a narrower window the cells stack vertically and the report becomes harder to scan. For best readability:

- **GitHub or GitLab**: open the report file in the web UI; tables render natively.
- **Markdown viewer apps**: [Bear](https://bear.app/) (Mac/iOS, free tier; import .md as a note), [MacDown](https://macdown.uranusjr.com/) (Mac, free), [Marked 2](https://marked2app.com/) (Mac, paid), [Obsidian](https://obsidian.md/) or [Typora](https://typora.io/) (cross-platform).
- **VS Code**: built-in Markdown Preview (cmd-shift-V on Mac).

If tables look broken in your terminal (rendered as vertical blocks instead of horizontal rows), widen the window or use one of the apps above. The data is fine; only the rendering needs more space.

## Honest limits

Behavioral audits have real limits. Read these before installing.

**What the audits can't catch:**

- **Bugs in the relationship between two correct files.** Cross-context SwiftData mutations, race conditions, distributed-state coordination — each individual file passes, the bug is in the handoff. The audit reads files; it can't reason about timing.
- **Business-logic correctness.** The skill verifies a button exists, that it's reachable, that its tap handler runs. It can't verify the handler does the right thing.
- **Novel bug classes.** A clean audit means zero matches for the patterns the skills know to look for. New bug shapes that haven't been added to any radar's domain list won't be caught until the next release.
- **Issues that only appear at runtime.** Memory pressure under specific conditions, threading issues that only manifest under load, OS-version-specific bugs. Static analysis has structural limits.

Treat findings as leads to investigate, not items to fix blindly. Verify critical findings before committing.

**Where to look for the bugs Radar Suite won't find:** pattern-based linters (SwiftLint, etc.) catch the single-file violations; runtime profiling (Instruments, debug builds with sanitizers) catches the threading and memory issues; targeted unit tests catch business-logic correctness. Radar Suite covers the cross-file behavioral gap between those tools.

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

## License

Apache 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Author

Terry Nyberg, [Coffee & Code LLC](https://stuffolio.app/). If Radar Suite catches a real bug for you, [a coffee](https://buymeacoffee.com/stuffolio) is appreciated. Issue reports about what worked or didn't are even more useful.
