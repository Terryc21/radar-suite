# Radar Suite

**5 audit skills for Claude Code that find bugs in your Swift/SwiftUI app before your users do.**

One install gives you a complete audit pipeline — from data model integrity to visual quality to release readiness.

## How is Radar Suite different from other code auditing skills?

Most code auditing skills are pattern matchers. They look at code in isolation — this file, this function, this line — and compare it against known-good patterns. *"You used `@StateObject` where `@State` works." "This `try?` swallows an error."* They're fast, precise, and context-free. They don't need to know what your app does.

Radar Suite traces behavior. It starts from what the user sees — a button, a flow, a journey — and follows the data through views, view models, managers, and persistence to see if the round trip actually works. A file can pass every pattern check and still contain a bug that only appears when you trace the full path.

Pattern matching catches wrong code. Behavior tracing catches wrong outcomes.

Most auditors are the building code. Radar Suite is the home inspector.

## What's Included

| Skill | What It Checks |
|-------|---------------|
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

## Recommended Run Order

Each skill writes findings that the next one can read, so running them in order gives the best results:

```
1. /data-model-radar      Checks data definitions (the foundation)
        ↓ findings flow to...
2. /ui-path-radar          Traces navigation and user flows
        ↓ findings flow to...
3. /roundtrip-radar        Verifies data survives complete cycles
        ↓ findings flow to...
4. /ui-enhancer-radar      Reviews visual quality of each screen
        ↓ findings flow to...
5. /capstone-radar         Gives overall grade + ship/no-ship decision
```

You can also run any skill individually — they work standalone. The findings handoff just makes them smarter when run together.

## What Each Skill Finds (Examples)

**data-model-radar** found that InsuranceProfile and DonationRecord weren't included in backups — meaning users would lose their insurance settings and tax records on restore.

**ui-path-radar** found 3 dead-end screens where users could navigate in but had no way to navigate out.

**roundtrip-radar** found that CSV export included Room and UPC columns, but CSV import silently dropped them — data loss on round-trip.

**ui-enhancer-radar** found spacing inconsistencies, missing empty states, and color contrast issues that would cause App Store accessibility rejection.

**capstone-radar** aggregated all findings into a B+ grade with 2 critical blockers preventing release.

## Finding Resolution

Every finding from every skill must reach a terminal state before release:

- **Fixed** — code changed, verified
- **Planned** — added to `DEFERRED.md` with a release gate (pre-release, post-release, or next major) and review-by date
- **Accepted** — intentional design choice, documented with rationale

capstone-radar enforces this with a **Resolution Gate** — it won't recommend shipping while unresolved findings exist.

## Fidelity

AI audit tools can sound confident while being shallow. The radar skills include structural constraints that make deep work easier than shortcuts, and make shallow work visible when it happens. See [FIDELITY.md](FIDELITY.md) for the full philosophy and roadmap.

## Previous Individual Repos

The skills were originally published as separate repos. Those repos now redirect here — this monorepo is the single source of truth. The skills are deeply interdependent (cross-skill handoffs, shared DEFERRED.md, unified grading) and are designed to be installed together.

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- A Swift/SwiftUI project (iOS, macOS, iPadOS, tvOS, or visionOS)

## License

MIT — see [LICENSE](LICENSE)
