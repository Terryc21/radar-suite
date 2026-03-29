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

## Fix Timing (MANDATORY — ask during session setup)

Before starting any audit, ask the user when fixes should be applied. Use `AskUserQuestion` with this question:

**"When should findings be fixed?"**

| Option | Description |
|--------|-------------|
| **Fix recommended after each skill (Recommended)** | After each skill completes, fix findings that are high urgency + low effort + small blast radius. Defer the rest to a post-capstone fix session. Best balance of momentum and thoroughness. |
| **Fix all after each skill** | Fix every finding before moving to the next skill. Thorough but slower — you may fix issues that capstone would deprioritize. |
| **Fix all after capstone** | Run all 5 skills first for the complete picture, then fix everything in one focused session using the capstone report as a punch list. Fastest audit but largest fix backlog. |

### Fix-Now Recommendation Logic

When the user selects "Fix recommended after each skill," the skill determines which findings to fix immediately vs. defer using these rules:

**Fix now** (all three must be true):
- `urgency >= HIGH`
- `fix_effort` is `trivial` or `small`
- `blast_radius <= 2 files`

**Defer to post-capstone:**
- Everything else — medium+ effort, 3+ file blast radius, or medium/low urgency
- Findings that require design decisions (multiple valid approaches)
- Findings where the full audit picture might change the recommended fix

### Post-Capstone Fix Session

After capstone-radar completes, **always present the deferred findings** as a fix backlog:

1. Read all handoff YAMLs for deferred findings
2. Present a unified table sorted by urgency, grouped by source skill
3. Ask: "Ready to fix deferred findings?" with options:
   - **Fix all now** — Work through the backlog in waves
   - **Fix critical/high only** — Skip medium/low for a later session
   - **Save for later** — Write the backlog to `Deferred.md` with ratings

This ensures **no finding is silently dropped**. Every deferred item either gets fixed or explicitly saved.

### Persist Fix Timing Choice

Save the user's choice in `.radar-suite/session-prefs.yaml` as `fix_timing: recommended | all_per_skill | all_after_capstone`. Each individual skill reads this to know whether to enter fix mode after scanning.

---

## Full Audit Sequence

When running full audit, execute skills in this order:

1. **data-model-radar** — Foundation layer, feeds findings to others
2. **roundtrip-radar** — Uses data-model findings to focus on high-risk workflows
3. **ui-path-radar** — Navigation audit, independent of data layer
4. **ui-enhancer-radar** — Visual audit, runs on specific views
5. **capstone-radar** — Aggregates all findings, produces final grade
6. **Post-capstone fix session** — Fix deferred findings from all skills (see Fix Timing above)

**Between skills:** Write handoff YAML, show progress, present fixes per fix timing preference, ask to continue or pause.

**On pause:** Save checkpoint so user can resume later.

---

## Status Command

Show audit progress across all skills:

```
Radar Suite Status:
Fix timing: Fix recommended after each skill

| Skill | Last Run | Findings | Fixed | Deferred |
|-------|----------|----------|-------|----------|
| data-model-radar | 2 days ago | 12 | 10 | 2 |
| roundtrip-radar | 2 days ago | 8 | 6 | 2 |
| ui-path-radar | not run | — | — | — |
| ui-enhancer-radar | not run | — | — | — |
| capstone-radar | not run | — | — | — |

Deferred backlog: 4 findings awaiting post-capstone fix session
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
