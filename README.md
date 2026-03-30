# Radar Suite

![GitHub stars](https://img.shields.io/github/stars/Terryc21/radar-suite?style=flat)
![GitHub forks](https://img.shields.io/github/forks/Terryc21/radar-suite?style=flat)

**6 audit skills for Claude Code that find bugs in your Swift/SwiftUI app before your users do.**

One install gives you a complete audit pipeline — from data model integrity to visual quality to release readiness.

## What's New in v2.0

**Major architecture overhaul** focused on UX and token efficiency:

- **Unified entry point** — `/radar-suite` routes to any skill or runs the full audit sequence
- **Session persistence** — Preferences carry across skills and sessions (no re-answering setup questions)
- **Checkpoint & resume** — Audits auto-save progress; resume after interruption or context exhaustion
- **Batch mode** — Approve fixes in waves instead of one-by-one
- **Fix timing control** — Choose when fixes happen: after each skill, recommended-only per skill, or all after capstone
- **Post-capstone fix session** — Deferred findings are never dropped; presented as a backlog after the final grade
- **Accepted risks** — Mark findings as "accept risk" to suppress in future audits
- **Shared core** — ~530 lines of duplication removed; consistent behavior across all skills
- **Streamlined setup** — One 4-question prompt instead of multiple scattered questions

## What's New in v2.1

- **Fix-Forward Bias** — Skills now recommend fixing over deferring by default. "Defer" is only recommended for Large effort items requiring architectural discussion. Prevents the pattern where following recommendations creates a growing backlog that never gets resolved.
- **Test Hygiene** — Pattern sweep now includes stale test detection. After fixing code, the skill scans corresponding test files for assertions on changed values, tests for removed behavior, and tests that enforce old defaults. Stale tests are updated or removed alongside the fix.

## How is Radar Suite different from other code auditing skills?

Most code auditing skills are pattern matchers. They look at code in isolation — this file, this function, this line — and compare it against known-good patterns. *"You used `@StateObject` where `@State` works." "This `try?` swallows an error."* They're fast, precise, and context-free. They don't need to know what your app does.

Radar Suite traces behavior. It starts from what the user sees — a button, a flow, a journey — and follows the data through views, view models, managers, and persistence to see if the round trip actually works. A file can pass every pattern check and still contain a bug that only appears when you trace the full path.

Pattern matching catches wrong code. Behavior tracing catches wrong outcomes.

Most auditors are the building code. Radar Suite is the home inspector.

## What's Included

| Skill | What It Checks |
|-------|---------------|
| **radar-suite** | Unified entry point — routes to any skill or runs full audit sequence |
| **data-model-radar** | Your data definitions — are fields backed up correctly? Does CSV export lose data? Are database relationships safe? |
| **ui-path-radar** | Navigation flows — can users reach every feature? Are there dead ends or broken links? |
| **roundtrip-radar** | Data round-trips — does data survive backup→restore, export→import, create→edit→save? |
| **ui-enhancer-radar** | Visual quality — requires you to view each screen before changes, walks through recommendations collaboratively, then finds similar patterns across views |
| **capstone-radar** | Overall grade (A-F) and release recommendation — aggregates findings from all other skills |

## Install

```bash
git clone https://github.com/Terryc21/radar-suite.git
cd radar-suite
./install.sh
```

That's it. All 5 skills are now available in Claude Code.

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
/radar-suite full    # Runs all 5 skills in optimal order
/radar-suite         # Interactive menu to choose skill or full audit
/radar-suite resume  # Continue from last checkpoint
```

**Manual order:** Each skill writes findings that the next one can read:

```
1. /data-model-radar      Checks data definitions (the foundation)
        ↓ findings flow to...
2. /roundtrip-radar        Verifies data survives complete cycles
        ↓ findings flow to...
3. /ui-path-radar          Traces navigation and user flows
        ↓ findings flow to...
4. /ui-enhancer-radar      Reviews visual quality of each screen
        ↓ findings flow to...
5. /capstone-radar         Gives overall grade + ship/no-ship decision
        ↓ deferred findings flow to...
6. Post-capstone fixes     Fix deferred backlog from all skills
```

You can also run any skill individually — they work standalone. The findings handoff just makes them smarter when run together.

## What Each Skill Finds (Examples)

**data-model-radar** found that InsuranceProfile and DonationRecord weren't included in backups — meaning users would lose their insurance settings and tax records on restore.

**ui-path-radar** found 3 dead-end screens where users could navigate in but had no way to navigate out.

**roundtrip-radar** found that CSV export included Room and UPC columns, but CSV import silently dropped them — data loss on round-trip.

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

## Previous Individual Repos

The skills were originally published as separate repos. Those repos now redirect here — this monorepo is the single source of truth. The skills are deeply interdependent (cross-skill handoffs, shared DEFERRED.md, unified grading) and are designed to be installed together.

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- A Swift/SwiftUI project (iOS, macOS, iPadOS, tvOS, or visionOS)

## License

MIT — see [LICENSE](LICENSE)
