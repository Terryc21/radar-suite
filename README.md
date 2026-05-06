# Radar Suite

**Six audit skills for Claude Code that find bugs in iOS/macOS Swift codebases by tracing behavior, not by matching patterns. Each finding cites a real file:line in your code, rated on a 9-column severity table. Plus a capstone skill that aggregates findings into a ship-or-don't-ship grade.**

Built while shipping [Stuffolio](https://stuffolio.app), an iOS/macOS app I work on every day, on a 600-file Swift codebase. Free, open source, no paid tier, no referral links.

<a href="https://buymeacoffee.com/stuffolio"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="120"></a>

If Radar Suite catches a real bug for you, a [coffee](https://buymeacoffee.com/stuffolio) is appreciated. Issue reports about what worked or didn't are even more useful.

---

## Why behavioral, not pattern-based

Most code-quality skills compare your code against a rule catalog: force unwraps, missing `@MainActor`, `try?` swallowing errors, deprecated APIs. Fast, precise, context-free. They catch a real class of bugs but miss anything that doesn't compress into a single-file pattern.

Radar Suite traces behavior. It starts from what the user sees (a screen, a flow, a backup round-trip) and follows the data through views, view models, managers, and persistence to verify the loop actually closes. A file can pass every pattern check and still contain a bug only visible in the trace.

Concrete: a SwiftData `@Model` with a non-optional inverse relationship will pass every pattern audit. A backup-restore-edit-save cycle that loses one of those relationships will not. The first scan finds nothing; the second flags the silent loss with a citation to the line where the inverse keypath is declared and the line where the restore reads it back without the inverse.

Useful framing: pattern-based skills are the building inspector confirming each bolt is torqued to spec. Radar Suite is the home inspector who turns on the shower and checks where the water actually goes. Different layer, different bugs. A thorough audit uses both.

---

## What's in the bundle

Seven skills total. Six audit skills covering distinct domains, plus a router that orchestrates them.

| Skill | Domain |
|---|---|
| `data-model-radar` | SwiftData / Core Data definitions across nine domains: field completeness, computed property correctness, serialization coverage with intentional-exclusion framework, relationship integrity (including cross-context mutation and stale-object detection), semantic clarity, field usage mapping, migration safety, cross-model consistency, near-duplicate model detection. Risk-ranks the model inventory so you know which to audit first. |
| `time-bomb-radar` | Code that compiles and ships fine but breaks later on aged data. Cascade deletes with live child references, cache expiry that fires wrong, trial paths, background tasks, date-transition edge cases, scheduled side effects. The class of bug that doesn't fail in tests because tests run on fresh data. |
| `ui-path-radar` | Navigation correctness. Enumerates every routing case, traces reachability, flags orphan features (in code but not in any menu), dead ends, broken back links. 32 issue categories. |
| `roundtrip-radar` | Data integrity through complete user journeys. Backup→restore, export→import, create→edit→save. Catches collection narrowing (arrays silently lose elements), bridge parity gaps (multiple consumers of the same model read different field subsets), and silent loss anywhere in the loop. Each finding cites the full UI→manager→model→persistence→UI path. |
| `ui-enhancer-radar` | Visual quality. 13 domains including iPad sheet sizing (audits caller-side `.sheet(...)` for missing `.presentationSizing(.page)` / `.presentationDetents([.large])` / project convenience modifiers), Button hit region (three-factor detector for `.buttonStyle(.plain)` + trailing chevron + Form/List context — the combination that collapses tap targets on iPad), color contrast, spacing, typography. |
| `capstone-radar` | Aggregates findings from the others into a two-section report: "Fix Before Shipping" (release-blocking; A-F grade) and "Hygiene Backlog" (everything else; doesn't affect grade). Tracks velocity over time and celebrates fixes between runs. |
| `radar-suite` | Router. Invokes individual skills, runs targeted pipelines (`--changed` selects skills from your git diff), or runs the full sweep (`--full`). |

Every audit skill is invoked by `axis-classification`, a foundation skill that runs before findings are emitted. It enforces the verification checklist (reachability trace, whole-file scan, branch enumeration, pattern citation lookup), the schema gate (rejects findings without file:line citations), and the 3-axis classification framework. You don't invoke it directly; it runs implicitly. Documented in [README-v2-detailed.md](README-v2-detailed.md) for readers who want the spec.

---

## Install

Two commands in Claude Code, run one at a time:

```
/plugin marketplace add Terryc21/radar-suite
```

```
/plugin install radar-suite@radar-suite
```

> **Why not paste both at once?** Claude Code's slash-command dispatcher treats the second `/plugin` as text inside the first command. Run them one at a time.

The plugin manifest at `.claude-plugin/plugin.json` is the single source of truth for which skills ship; `.claude-plugin/verify-manifest.sh` detects drift between manifest and disk. If you cloned this repo and ran `./install.sh` between 2026-03-24 and 2026-04-10, your install was silently incomplete — re-run `install.sh` or switch to the plugin path. Details in [README-v2-detailed.md](README-v2-detailed.md#installed-between-2026-03-24-and-2026-04-10-re-run-installsh-or-switch-to-the-plugin).

---

## Cost-aware run strategy

Radar Suite is deliberately thorough. It reads whole files to catch handlers that grep missed, walks call sites to verify reachability, and cites real patterns from your codebase rather than generic advice. That thoroughness costs tokens — meaningfully more than a single-file linting skill. A full `/radar-suite --full` on a medium Swift project (200-600 files) consumes a substantial chunk of a Claude Code session. Pro tier users should expect a noticeable fraction of weekly allocation; Max tier users are fine.

Three tiers, in order of token cost:

**1. Single skill** (default for development).
```
/radar-suite data-model
/radar-suite ui-path
```
One skill, one focused pass, one report. Best during active development or after a localized refactor. Run as often as you want.

**2. Targeted pipeline** (default for PRs).
```
/radar-suite --changed
```
Auto-selects skills from your git diff. If you only changed view code, runs `ui-path-radar` and `ui-enhancer-radar`; if you touched models, runs `data-model-radar` and `roundtrip-radar`. Typically 1-2 hours.

```
/radar-suite --skills dmr,tbr
```
Manual skill selection by short code. Useful when `--changed` doesn't pick up everything (e.g., adding a new feature flag that wasn't yet referenced in any diff).

**3. Full pipeline** (reserve for releases).
```
/radar-suite --full
```
All six audit skills plus the capstone aggregator. Half-day commitment. Reserve for pre-release audits or quarterly health checks. Not what you start with.

Two strategies that lower cost regardless of tier:

- **Scope to a directory.** Pass a path argument: `/radar-suite ui-path --scope Sources/Features/Auth/`. The skill reads only files under that path.
- **Resume from a previous run.** Audits checkpoint after each phase. If a session ends mid-audit, the next invocation resumes from the last checkpoint rather than restarting.

Detailed scoping strategies for monorepos and modular codebases: [README-v2-detailed.md](README-v2-detailed.md#scoping-audits-to-specific-areas).

---

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

---

## Honest fidelity log

I keep [MISSED-IT-BY-THAT-MUCH.md](https://github.com/Terryc21/radar-suite/blob/main/MISSED-IT-BY-THAT-MUCH.md) — a public log of cases where Radar Suite missed a real bug or flagged something that wasn't a problem. The entries are specific (this commit, this file, this finding) and unflattering. Reading it gives you a calibrated sense of false-positive and false-negative rates rather than a marketing pitch about accuracy.

Most pattern-based audit skills don't keep this kind of log because doing so requires admitting their detection patterns aren't complete. Radar Suite's domains are explicitly tagged `grep-sufficient`, `enumerate-required`, or `mixed`, which forces the question of which findings could have been missed and why.

---

## What it can't catch

Behavioral audits have real limits:

- **Bugs in the relationship between two correct files.** Cross-context SwiftData mutations, race conditions, distributed-state coordination — each individual file passes, the bug is in the handoff. The audit reads files; it can't reason about timing.
- **Business-logic correctness.** The skill verifies a button exists, that it's reachable, that its tap handler runs. It can't verify the handler does the right thing.
- **Novel bug classes.** A clean audit means zero matches for the patterns the skills know to look for. New bug shapes that haven't been added to any radar's domain list won't be caught until the next release.
- **Issues that only appear at runtime.** Memory pressure under specific conditions, threading issues that only manifest under load, OS-version-specific bugs. Static analysis has structural limits.

Treat findings as leads to investigate, not items to fix blindly. Verify critical findings before committing.

---

## Updates

```
/plugin update radar-suite
```

Or check [CHANGELOG.md](CHANGELOG.md). I update these often enough that re-checking before a major audit is worthwhile.

---

## Other Claude Code skills I've built

- [code-smarter](https://github.com/Terryc21/code-smarter) — turns a file from your project into an annotated tutorial with vocabulary tracking, pre/post tests, and prerequisite gap analysis. Works for any language.
- [prompter](https://github.com/Terryc21/prompter) — rewrites your Claude Code prompt for clarity (resolves ambiguous references, tightens vague verbs, restructures stacked questions) before acting.
- [bug-echo](https://github.com/Terryc21/bug-echo) — after you fix a bug, infers the anti-pattern from your diff, validates against the pre-fix file, and scans for sibling instances.
- [workflow-audit](https://github.com/Terryc21/workflow-audit) — 5-layer audit of SwiftUI user flows. Pairs naturally with `ui-path-radar`; the radar enumerates routes while workflow-audit traces what a user trying to do something would experience step by step.

All free, all Apache 2.0, all built while shipping Stuffolio.

---

## Requirements

- Claude Code (any tier; Pro works, Max is comfier for `--full` runs)
- A Swift codebase (iOS, macOS, or Catalyst)

That's the entire requirements list.

---

## Deeper documentation

Two longer docs:

- [README-v2-detailed.md](README-v2-detailed.md) — the full reference: 3-axis classification spec, schema gate behavior, scoping strategies for monorepos, run-order recommendations, release history per skill (v2.0 → v2.3), and the design philosophy behind each radar's domain selection.
- [README-newer-dev.md](README-newer-dev.md) — gentler walk-through aimed at readers new to Claude Code skills and audit tooling. Skips the technical depth above in favor of a "what is a skill, here's a small first run" framing.

---

## License

Apache 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Author

Terry Nyberg, [Coffee & Code LLC](https://stuffolio.app/).
