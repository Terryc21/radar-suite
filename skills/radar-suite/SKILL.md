---
name: radar-suite
description: 'Unified entry point for the 5-skill radar family. Routes to individual skills or runs full audit sequence. Triggers: "radar suite", "full audit", "run all radars", "/radar-suite".'
version: 1.0.0
author: Terry Nyberg
license: MIT
inherits: radar-suite-core.md
---

# Radar Suite — Unified Entry Point

> Single command to run any radar skill or the full audit sequence.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/radar-suite` | Interactive menu — choose skill or full audit |
| `/radar-suite full` | Run all 5 skills in sequence |
| `/radar-suite status` | Show audit progress across all skills |
| `/radar-suite resume` | Resume from last checkpoint |
| `/radar-suite [skill]` | Run specific skill (data-model, roundtrip, ui-path, ui-enhancer, capstone) |

## Available Skills

| Skill | Purpose | Est. Time |
|-------|---------|-----------|
| **data-model-radar** | Audit @Model layer for completeness, serialization, relationships | ~30-60 min |
| **roundtrip-radar** | Trace user workflows end-to-end for data safety | ~20-40 min |
| **ui-path-radar** | Find dead ends, broken promises, navigation issues | ~15-30 min |
| **ui-enhancer-radar** | Visual UI audit with design intent interview | ~20-45 min |
| **capstone-radar** | Aggregate grades, ship/no-ship decision | ~15-30 min |

---

## Interactive Menu

On invocation without arguments, present:

```
Radar Suite — What would you like to audit?

1. **Full audit** — Run all 5 skills in recommended order (~2-3 hours)
2. **Data models** — Check @Model layer for gaps and inconsistencies
3. **User workflows** — Trace data through complete user journeys
4. **Navigation paths** — Find dead ends and broken navigation
5. **UI polish** — Visual audit of specific views
6. **Release readiness** — Aggregate grades and ship/no-ship decision
7. **Resume** — Continue from last checkpoint
8. **Status** — Show current audit progress
```

---

## Full Audit Sequence

When running full audit, execute skills in this order:

1. **data-model-radar** — Foundation layer, feeds findings to others
2. **roundtrip-radar** — Uses data-model findings to focus on high-risk workflows
3. **ui-path-radar** — Navigation audit, independent of data layer
4. **ui-enhancer-radar** — Visual audit, runs on specific views
5. **capstone-radar** — Aggregates all findings, produces final grade

**Between skills:** Write handoff YAML, show progress, ask to continue or pause.

**On pause:** Save checkpoint so user can resume later.

---

## Status Command

Show audit progress across all skills:

```
Radar Suite Status:

| Skill | Last Run | Findings | Fixed | Remaining |
|-------|----------|----------|-------|-----------|
| data-model-radar | 2 days ago | 12 | 10 | 2 |
| roundtrip-radar | 2 days ago | 8 | 6 | 2 |
| ui-path-radar | not run | — | — | — |
| ui-enhancer-radar | not run | — | — | — |
| capstone-radar | not run | — | — | — |

Overall: 4 open findings, 2 skills remaining
Next recommended: ui-path-radar
```

---

## Handoff Flow

Each skill writes `.radar-suite/[skill]-handoff.yaml` on completion.

Capstone-radar reads all handoffs to:
1. Aggregate findings
2. Detect cross-skill patterns
3. Produce unified grades
4. Make ship/no-ship recommendation

---

## Shared Patterns

See `radar-suite-core.md` for: Session Setup, Session Persistence, Checkpoint & Resume, Accepted Risks, Wave-Based Fix Presentation, Table Format, Issue Rating Tables.
