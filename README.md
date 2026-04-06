# Radar Suite

![Visitors](https://komarev.com/ghpvc/?username=Terryc21&repo=radar-suite&label=visitors&color=blue) ![GitHub stars](https://img.shields.io/github/stars/Terryc21/radar-suite?style=flat) ![GitHub forks](https://img.shields.io/github/forks/Terryc21/radar-suite?style=flat)

![GitHub stars](https://img.shields.io/github/stars/Terryc21/radar-suite?style=flat)
![GitHub forks](https://img.shields.io/github/forks/Terryc21/radar-suite?style=flat)

**7 audit skills for Claude Code that find bugs in your Swift/SwiftUI app before your users do.**

Built for [Stuffolio](https://stuffolio.app), an iOS/macOS inventory management app.

One install gives you a complete audit pipeline — from data model integrity to visual quality to release readiness.

## Recent Changes

| Version | Highlight |
|---------|-----------|
| **v2.4** | **roundtrip-radar v1.6.0** -- new "bridge parity" check compares multiple consumers of the same model type and flags when one reads fewer fields than the others |
| **v2.3** | **roundtrip-radar v1.5.0** -- new "collection narrowing" check finds arrays silently reduced to single elements at handoff points |
| **v2.2** | **time-bomb-radar** -- new skill that finds deferred operations crashing on aged data (6 patterns) |
| **v2.1** | Fix-forward bias (recommend fixing over deferring) + stale test detection |
| **v2.0** | Unified entry point, checkpoint/resume, batch mode, session persistence |

Full details in [CHANGELOG.md](CHANGELOG.md).

## How is Radar Suite different from other code auditing skills?

Most code auditing skills are pattern matchers. They look at code in isolation — this file, this function, this line — and compare it against known-good patterns. *"You used `@StateObject` where `@State` works." "This `try?` swallows an error."* They're fast, precise, and context-free. They don't need to know what your app does.

Radar Suite traces behavior. It starts from what the user sees — a button, a flow, a journey — and follows the data through views, view models, managers, and persistence to see if the round trip actually works. A file can pass every pattern check and still contain a bug that only appears when you trace the full path.

Pattern matching catches wrong code. Behavior tracing catches wrong outcomes.

Most auditors are the building code. Radar Suite is the home inspector.

## What's Included

| Skill | What It Checks |
|-------|---------------|
| **radar-suite** | Unified entry point — routes to any skill or runs full audit sequence |
| **data-model-radar** | Your data definitions -- are fields backed up correctly? Does CSV export lose data? Are database relationships safe? |
| **time-bomb-radar** | Deferred operations -- will your app crash 30 days after release? Cascade deletes, cache expiry, trial paths, background tasks, date transitions, scheduled side effects |
| **ui-path-radar** | Navigation flows -- can users reach every feature? Are there dead ends or broken links? |
| **roundtrip-radar** | Data round-trips — does data survive backup→restore, export→import, create→edit→save? Detects collection narrowing (arrays silently lose elements) and bridge parity gaps (multiple consumers of the same model read different field subsets). |
| **ui-enhancer-radar** | Visual quality — requires you to view each screen before changes, walks through recommendations collaboratively, then finds similar patterns across views |
| **capstone-radar** | Overall grade (A-F) and release recommendation — aggregates findings from all other skills |

## Install

```bash
git clone https://github.com/Terryc21/radar-suite.git
cd radar-suite
./install.sh
```

That's it. All 7 skills are now available in Claude Code.

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

**Easiest:** Use the unified entry point:

```
/radar-suite full    # Runs all 7 skills in optimal order
/radar-suite         # Interactive menu to choose skill or full audit
/radar-suite resume  # Continue from last checkpoint
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

You can also run any skill individually — they work standalone. The findings handoff just makes them smarter when run together.

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
| **Fix all after capstone** | Run all 5 skills first for the full picture, then fix everything in one session using the capstone report as a punch list. Fastest audit, largest fix backlog. |

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

- [Stuffolio](https://stuffolio.app) -- the iOS/macOS app these skills were built for
- [Workflow Audit](https://github.com/Terryc21/workflow-audit) -- 5-layer SwiftUI user flow audit
- [code-smarter](https://github.com/Terryc21/code-smarter) -- Prompt rewriting + personalized coding tutorials from your codebase

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
