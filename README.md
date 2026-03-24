# Radar Suite

**5 audit skills for Claude Code that find bugs in your Swift/SwiftUI app before your users do.**

One install gives you a complete audit pipeline — from data model integrity to visual quality to release readiness.

## What's Included

| Skill | What It Checks |
|-------|---------------|
| **data-model-radar** | Your data definitions — are fields backed up correctly? Does CSV export lose data? Are database relationships safe? |
| **ui-path-radar** | Navigation flows — can users reach every feature? Are there dead ends or broken links? |
| **roundtrip-radar** | Data round-trips — does data survive backup→restore, export→import, create→edit→save? |
| **ui-enhancer-radar** | Visual quality — spacing, typography, color contrast, accessibility, empty states |
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

## Individual Repos

Each skill also has its own repo if you prefer to install individually:

- [data-model-radar](https://github.com/Terryc21/data-model-radar)
- [ui-path-radar](https://github.com/Terryc21/ui-path-radar)
- [roundtrip-radar](https://github.com/Terryc21/roundtrip-radar)
- [ui-enhancer-radar](https://github.com/Terryc21/ui-enhancer-radar)
- [capstone-radar](https://github.com/Terryc21/capstone-radar)

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- A Swift/SwiftUI project (iOS, macOS, iPadOS, tvOS, or visionOS)

## License

MIT — see [LICENSE](LICENSE)
