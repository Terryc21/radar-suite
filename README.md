# Radar Suite

![Visitors](https://komarev.com/ghpvc/?username=Terryc21&repo=radar-suite&label=visitors&color=blue) ![GitHub stars](https://img.shields.io/github/stars/Terryc21/radar-suite?style=flat) ![GitHub forks](https://img.shields.io/github/forks/Terryc21/radar-suite?style=flat)

<a href="https://buymeacoffee.com/stuffolio">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="150">
</a>

**8 audit skills for Claude Code that find bugs in your Swift/SwiftUI app before your users do. Every finding cites a real file:line pattern in your own codebase — not generic advice. Heavy audits; see [Session Strategy](#session-strategy-read-this-before-your-first-run) before your first run.**

Built during the development of [Stuffolio](https://stuffolio.app), an iOS/macOS app that tracks the things you own across their full life cycle — warranty, repair, and legacy. The audit skills came out of shipping real features like Legacy Wishes and Stuff Scout on a 600-file codebase.

One install gives you a complete audit pipeline — from data model integrity to visual quality to release readiness.

## What's New in v2.1 (2026-04-11)

**3-tier depth model.** You now choose how deep to audit:

| Tier | Command | What It Does | Time |
|------|---------|-------------|------|
| **1 (Quick)** | `/radar-suite data-model` | Single skill, own rating table, no pipeline | 20-60 min |
| **2 (Targeted)** | `/radar-suite --skills dmr,tbr` | 2-3 skills with cross-skill handoffs | 1-2 hours |
| **2 (Auto)** | `/radar-suite --changed` | Auto-select skills from git diff | varies |
| **3 (Full)** | `/radar-suite --full` | All 6 skills + capstone + UX enhancements | 2.5-4 hours |

Tier 1 is the new default. The full pipeline is now opt-in via `--full`, not the implicit behavior.

**6 pipeline UX enhancements** for Tier 3: progress banners at every skill transition, per-skill mini rating tables (marked "PRELIMINARY"), audit-only mode statement, duration estimates, pre-capstone summary, and `short_title` on every finding ID (e.g., `RS-002 (cascade delete crash)` instead of bare `RS-002`).

**Skill abbreviations** for `--skills`: `dmr` (data-model), `tbr` (time-bomb), `rtr` (roundtrip), `upr` (ui-path), `uer` (ui-enhancer).

## What Shipped in v2.0 (2026-04-10)

**Every finding now cites a real pattern in your own codebase.** Not generic advice — a specific file and line number you can open, read, and copy. The schema gate rejects findings without citations, so "consider adding error handling" never reaches you; "follow the pattern at `CloudSyncManager.swift:104-112`" does.

The 3-axis classification framework (bug / scatter / dead) keeps hygiene out of your ship grade so you can focus on what actually blocks release. axis_1 findings count toward the A-F grade; axis_2 and axis_3 findings live in a separate Hygiene Backlog and do not.

The verification checklist caught 4 false positives across the first two audit runs that would have reached users under the pre-v2.0 radars — documented in the 2026-04-10 dry-run and capstone reports. Silent catches are the framework's biggest win.

v2.0 also ships as a Claude Code plugin via `/plugin install`, replacing the hand-maintained `install.sh` distribution path (which still works as a fallback — see the Install section below).

> **Note on the version number reset.** The skills were previously versioned individually (per-skill v3.1, v3.0, v2.4, etc.). v2.0 is the first unified plugin version. Older per-skill version history is preserved in [CHANGELOG.md](CHANGELOG.md).

## How is Radar Suite different from other code auditing skills?

Most code auditing skills are pattern matchers. They look at code in isolation — this file, this function, this line — and compare it against known-good patterns. *"You used `@StateObject` where `@State` works." "This `try?` swallows an error."* They're fast, precise, and context-free. They don't need to know what your app does.

Radar Suite traces behavior. It starts from what the user sees — a button, a flow, a journey — and follows the data through views, view models, managers, and persistence to see if the round trip actually works. A file can pass every pattern check and still contain a bug that only appears when you trace the full path.

Most auditors are the building code. Radar Suite is the home inspector.

## What's Included

| Skill | What It Checks |
|-------|---------------|
| **radar-suite** | Unified entry point — routes to any skill or runs full audit sequence |
| **radar-suite-axis-classification** | Foundation skill. Invoked automatically by every other radar before findings are emitted. Provides the 3-axis framework, verification checklist (reachability trace, whole-file scan, branch enumeration, pattern citation lookup), coaching schema, and schema gate that rejects findings without file:line citations. |
| **data-model-radar** | Your data definitions -- are fields backed up correctly? Does CSV export lose data? Are database relationships safe? |
| **time-bomb-radar** | Deferred operations -- will your app crash 30 days after release? Cascade deletes, cache expiry, trial paths, background tasks, date transitions, scheduled side effects |
| **ui-path-radar** | Navigation flows -- can users reach every feature? Are there dead ends or broken links? Every one of the 30 issue categories has a default axis with reclassification rules. |
| **roundtrip-radar** | Data round-trips — does data survive backup→restore, export→import, create→edit→save? Every finding cites the full UI→manager→model→persistence→UI path in its verification log. Detects collection narrowing (arrays silently lose elements) and bridge parity gaps (multiple consumers of the same model read different field subsets). |
| **ui-enhancer-radar** | Visual quality — requires you to view each screen before changes, walks through recommendations collaboratively, then finds similar patterns across views |
| **capstone-radar** | Two-section report: "Fix Before Shipping" (axis_1 findings, A-F grade), "Hygiene Backlog" (axis_2/3, no grade impact). Aggregates findings from all other skills with axis-split rendering and audit coverage reporting. |

## Session Strategy (Read This Before Your First Run)

Radar Suite is deliberately thorough. It reads whole files to catch handlers the grep missed, walks call sites to verify reachability, and cites real patterns from your own codebase instead of generic advice. That thoroughness costs tokens — meaningfully more than a single-file linting skill.

**What this means for you:** a full `/radar-suite full` run on a medium Swift project (200-600 files) will consume a substantial chunk of your Claude Code session. Users on Pro tier should expect to use a noticeable fraction of their weekly allocation on a single full run. Users on Max tier are fine.

**Choose the right tier for your budget and task:**

1. **Tier 1 (default): Single skill.** Run one skill at a time. `/radar-suite data-model` or `/radar-suite ui-path` gives you focused output without committing to a pipeline. Best during development or after a focused refactor.

2. **Tier 2: Targeted pipeline.** Run 2-3 related skills. `/radar-suite --changed` auto-selects skills from your git diff (typically 1-2 hours). `/radar-suite --skills dmr,tbr` for manual selection. Best before opening a PR.

3. **Tier 3: Full pipeline.** `/radar-suite --full` runs all 6 skills with pipeline UX enhancements. Reserve for pre-release audits or quarterly health checks. Half-day commitment.

4. **Capstone first.** Run `/capstone-radar` alone to see the high-level grade and which domains need attention. Then run only the radars capstone flagged via Tier 2.

5. **Defer fixes to after capstone.** Switching to "fix all after capstone" runs all the scans first, then fixes in one batch -- fewer build invocations, less total cost.

**Why the cost is what it is:** the alternative — cheaper audits that skip the whole-file scans and pattern citations — is exactly the pre-v2.0 behavior that produced the false positives the axis framework was built to catch. You're paying for verification checks that prevent findings like "your empty-state handler is missing" from reaching you when the handler exists 500 lines down in the same file. Spending 10 minutes of session time to avoid spending 30 minutes of human time disproving a false positive is the trade Radar Suite is built around.

**If a full audit kills your session:** [file an issue](https://github.com/Terryc21/radar-suite/issues) with the project size (Swift file count, total LOC) and which skill was running when the session cratered. I'll update this section with data from real runs.

## Install

**Recommended: Claude Code plugin**

Run these two commands **one at a time** in Claude Code. Wait for Step 1 to confirm "Successfully added marketplace" before running Step 2.

Step 1 — add the marketplace:

```
/plugin marketplace add Terryc21/radar-suite
```

Step 2 — install the plugin:

```
/plugin install radar-suite@radar-suite
```

All 8 skills are now available in Claude Code. The plugin manifest at `.claude-plugin/plugin.json` is the single source of truth for what ships, and `.claude-plugin/verify-manifest.sh` detects drift between the manifest and disk.

> **Why two separate blocks?** If you copy both `/plugin` lines at once and paste them into Claude Code, the slash-command dispatcher treats the first `/plugin` as the command and the rest of the paste (including the second `/plugin install...`) as its arguments. Claude Code then tries to clone a repo literally named `Terryc21/radar-suite /plugin install radar-suite` and fails with a misleading SSH authentication error. Running them one at a time avoids the trap.

**Fallback: clone and install.sh (deprecated as of v2.0)**

If you can't use the plugin path yet, `install.sh` still works:

```bash
git clone https://github.com/Terryc21/radar-suite.git
cd radar-suite
./install.sh
```

The script now includes a drift guardrail that verifies its internal `SKILLS` array matches disk before installing. It will warn if drift is detected.

### Installed between 2026-03-24 and 2026-04-10? Re-run `install.sh` or switch to the plugin

If you cloned this repo and ran `./install.sh` between **2026-03-24** and **2026-04-10**, your install was silently incomplete. The installer was missing two skills: `time-bomb-radar` (the 30-day crash detector) and `radar-suite` (the orchestrator). The `/time-bomb-radar` and `/radar-suite` commands would have returned "skill not found" errors even though the skill files existed in the repo.

The bug was fixed on 2026-04-10. To backfill the missing skills:

```bash
cd radar-suite
git pull
./install.sh
```

`install.sh` is idempotent and safe to re-run. Existing symlinks are updated in place; missing symlinks are created. Nothing else in your Claude Code install is touched.

The root cause: `install.sh` was a hand-maintained shell script with a hardcoded `SKILLS=()` array. When new skills were added to `skills/` in later commits, the array was not updated to match. Documentation (this README) said "7 skills" while the installer shipped 5. This class of drift is exactly what a plugin manifest prevents -- which is why Radar Suite is moving to one. See the next section.

### v2.0 deep dive: the 3 axes, the schema gate, and the plugin manifest

**The three axes.** Every finding from every radar is classified before it can be emitted:

- **axis_1_bug** — real user-facing defect. Counts toward the A-F grade. Fix before shipping.
- **axis_2_scatter** — correct code, poor structure. Fix opportunistically. Does not affect grade.
- **axis_3_dead_code / axis_3_smelly** — unreachable branches or reachable-but-unjustified code. Delete or document.

**The schema gate.** Every finding must populate `current_approach`, `suggested_fix`, `better_approach`, and `better_approach_tradeoffs` — and the `better_approach` field must contain a `file:line` citation matching a real pattern in your codebase. The gate enforces this with a regex check. Findings that don't cite are either fixed by the radar (run the missing verification checks, populate the missing fields) or downgraded to `possible` confidence and tagged "coaching incomplete" so they're visible as low-confidence entries rather than silently dropped.

**The verification checklist.** Before a radar emits a finding, it runs the applicable checks: reachability trace (is this branch reachable from a production call site?), whole-file scan (is there a handler elsewhere in the same file?), branch enumeration (did we read both sides of every `#if os(iOS)` / `#else`?), pattern citation lookup (does the cited pattern actually exist?), and source root introspection (did we scan all the project's source roots, not just `Sources/`?). Every check that runs is logged in the finding's `verification_log` so a reader can see what the radar actually checked.

**The plugin manifest.** `.claude-plugin/plugin.json` declares every skill the plugin ships. `.claude-plugin/verify-manifest.sh` diffs the manifest against `ls skills/` and fails if they disagree. The 17-day silent install drift bug that shipped only 5 of 7 skills between 2026-03-24 and 2026-04-10 is structurally impossible under the manifest — not "hard to hit" but impossible — as long as CI runs the verify script. `install.sh` is kept as a fallback and now runs the same verify check at install time.

## Updates

Each skill checks for updates on startup. If a newer version is available, you'll see a one-line notice — it never blocks your audit.

To update manually:

```bash
cd radar-suite
git pull
```

If you installed via `install.sh` (symlinks), the update takes effect immediately. If you copied the files, re-run `./install.sh` after pulling.

Each skill has a `VERSION` file and a `version:` field in its SKILL.md frontmatter. [GitHub Releases](https://github.com/Terryc21/radar-suite/releases) include changelogs for each version.

## Recommended Run Order

> **Skill 0:** `radar-suite-axis-classification` is invoked automatically by every other radar before findings are emitted. You never run it directly — it provides the verification checklist, coaching schema, and schema gate that the other skills depend on. The run order below covers the 6 skills you actually invoke plus capstone.

**Easiest:** Use the unified entry point:

```
/radar-suite full            # Runs the audit skills in optimal order
/radar-suite                 # Interactive menu to choose skill or full audit
/radar-suite resume          # Continue from last checkpoint
/radar-suite audit --changed # Quick re-audit of files changed since last session
/radar-suite ledger          # View all findings across skills
/radar-suite verify          # Re-verify all fixed findings
```

**Manual order:** Each skill writes findings that the next one can read:

```
1. /data-model-radar      Checks data definitions (the foundation)
        ↓ findings flow to...
2. /time-bomb-radar        Checks deferred operations on aged data
        ↓ findings flow to...
3. /roundtrip-radar        Verifies data survives complete cycles
        ↓ findings flow to...
4. /ui-path-radar          Traces navigation and user flows
        ↓ findings flow to...
5. /ui-enhancer-radar      Reviews visual quality of each screen
        ↓ findings flow to...
6. /capstone-radar         Gives overall grade + ship/no-ship decision
        ↓ deferred findings flow to...
7. Post-capstone fixes     Fix deferred backlog from all skills
```

You can also run any skill individually -- they work standalone. The findings handoff just makes them smarter when run together.

## Finding Management

Every finding gets a unique RS-NNN ID and lives in a unified ledger (`.radar-suite/ledger.yaml`). This enables:

- **Cross-skill visibility** -- see all findings from all skills in one place, organized by impact (crash, data loss, UX broken, etc.)
- **Deduplication** -- when two skills find the same issue from different angles, the ledger merges them instead of creating duplicates
- **Regression detection** -- file hashes track whether fixed files have changed; `/radar-suite verify` confirms fixes still hold
- **Finding relationships** -- link root causes to symptoms; fixing a root cause auto-flags symptoms for re-check
- **Confidence decay** -- accepted findings resurface after 180 days so you re-evaluate with fresh context
- **Partial re-audit** -- `/radar-suite audit --changed` scopes to modified files only (15-30 min vs 2.5-4 hours)

The per-skill handoff YAMLs are still written for backward compatibility. The ledger is the cross-skill view that ties everything together.

## What Each Skill Finds (Examples)

**data-model-radar** found that InsuranceProfile and DonationRecord weren't included in backups — meaning users would lose their insurance settings and tax records on restore. Its time bomb audit found a deferred deletion that would crash the app 30 days after archiving items — invisible during development because no test data was old enough to trigger it.

**ui-path-radar** found 3 dead-end screens where users could navigate in but had no way to navigate out.

**roundtrip-radar** found that CSV export included Room and UPC columns, but CSV import silently dropped them — data loss on round-trip. Its collection narrowing check found that selecting 4 photos for AI analysis only passed the first photo through — the flow worked, types were correct, but 75% of input data was silently discarded at each handoff point. Its bridge parity check found 3 functions that built notes from the same scout data model — two included all 6 narrative sections, one included only 3. No type error, no crash — users silently lost research data on one code path.

**ui-enhancer-radar** found spacing inconsistencies, missing empty states, and color contrast issues that would cause App Store accessibility rejection.

**capstone-radar** aggregated all findings into a B+ grade with 2 critical blockers preventing release.

## When Fixes Happen

At the start of every audit, you choose when findings get fixed:

| Option | What Happens |
|--------|-------------|
| **Fix recommended after each skill** (default) | After each skill, fix high-urgency + low-effort findings immediately. Defer the rest to a post-capstone fix session. Best balance of speed and thoroughness. |
| **Fix all after each skill** | Fix every finding before moving to the next skill. Most thorough, but slower. |
| **Fix all after capstone** | Run the full audit first for the full picture, then fix everything in one session using the capstone report as a punch list. Fastest audit, largest fix backlog. |

The default option uses a simple rule: fix now if the finding is high urgency, low effort, and touches 2 files or fewer. Everything else benefits from the full audit picture — capstone might reveal it's part of a larger pattern, or deprioritize it entirely.

**No finding is silently dropped.** After capstone completes, the suite presents all deferred findings as a fix backlog. Each one either gets fixed, explicitly deferred to `DEFERRED.md`, or accepted as a design choice.

## Finding Resolution

Every finding from every skill must reach a terminal state before release:

- **Fixed** — code changed, verified
- **Planned** — added to `DEFERRED.md` with a release gate (pre-release, post-release, or next major) and review-by date
- **Accepted** — intentional design choice, documented with rationale

capstone-radar enforces this with a **Resolution Gate** — it won't recommend shipping while unresolved findings exist.

## Audit Methodology

Every skill follows three scanning principles to minimize false negatives:

1. **Enumerate-then-verify** — For domains where violations can lack searchable code signatures, the skill lists all candidate files and verifies each one rather than relying on grep alone. This addresses the 57% miss rate observed in grep-only audits. Each skill's domains are tagged `grep-sufficient`, `enumerate-required`, or `mixed` to guide scan depth.
2. **File-scoped skip lists** — A resolved finding applies to that file only. Callers and dependents of a fixed file need independent verification.
3. **Negative pattern matching** — The skill searches for subjects, then verifies the correct pattern exists around them. Findings from absent patterns are ranked into three confidence tiers (Almost certain / Probable / Possible) and presented separately from verified findings.

## Fidelity

AI audit tools can sound confident while being shallow. The radar skills include structural constraints that make deep work easier than shortcuts, and make shallow work visible when it happens. See [FIDELITY.md](FIDELITY.md) for the full philosophy and roadmap.

## See Also

- [Workflow Audit](https://github.com/Terryc21/workflow-audit) -- 5-layer behavioral audit of SwiftUI user journeys
- [code-smarter](https://github.com/Terryc21/code-smarter) -- Prompt rewriting and personalized coding tutorials from your own codebase

## Previous Individual Repos

The skills were originally published as separate repos. Those repos now redirect here -- this monorepo is the single source of truth. The skills are deeply interdependent (cross-skill handoffs, shared DEFERRED.md, unified grading) and are designed to be installed together.

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- A Swift/SwiftUI project (iOS, macOS, iPadOS, tvOS, or visionOS)

## Optional: Dippy (recommended for paths with spaces)

If your project lives on a path with spaces (e.g., `/Volumes/My Drive/Projects/...`), Claude Code triggers a security warning — "Command contains backslash-escaped whitespace that could alter command parsing" — on routine commands like `grep`, `git log`, and `ls`. Each warning requires manual permission approval, which interrupts audit flow repeatedly.

There is no Claude Code setting to suppress this warning. It's a hardcoded security check.

[Dippy](https://github.com/ldayton/Dippy) solves this by acting as a PreToolUse hook that auto-approves safe, read-only commands while blocking destructive operations (force push, `rm -rf`, `git reset --hard`). It uses a custom bash parser with 14,000+ tests to understand what each command actually does — it's not a blanket auto-approve.

```bash
brew tap ldayton/dippy
brew install dippy
```

Then add the hook to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "dippy" }]
      }
    ]
  }
}
```

Radar Suite includes Dippy integration at two levels:

- **Pre-flight check** — At audit startup, if your project path contains spaces and Dippy isn't installed, the skill prints a one-line recommendation. Non-blocking — the audit continues either way.
- **Bundled `.dippy` config** — A reference config tuned for audit workflows is included in this repo. Copy it to your project root to customize which commands are auto-approved during audits.

If your project path has no spaces, none of this applies and you won't see any Dippy-related messages.

Dippy is [MIT licensed](https://github.com/ldayton/Dippy/blob/main/LICENSE).

## License

MIT — see [LICENSE](LICENSE)
