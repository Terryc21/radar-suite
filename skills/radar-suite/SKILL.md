---
name: radar-suite
description: 'Unified entry point for the 5-skill radar family. Routes to individual skills or runs full audit sequence. Triggers: "radar suite", "full audit", "run all radars", "/radar-suite".'
version: 3.0.0
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
| `/radar-suite [skill]` | Run specific skill (data-model, time-bomb, roundtrip, ui-path, ui-enhancer, capstone) |
| `/radar-suite ledger` | View unified finding ledger with optional filters |
| `/radar-suite ledger --open` | Show open findings only |
| `/radar-suite ledger --deferred` | Show deferred findings only |
| `/radar-suite ledger --impact crash` | Filter by impact category (crash, data-loss, ux-broken, ux-degraded, polish, hygiene) |
| `/radar-suite ledger --skill [name]` | Filter by source skill |
| `/radar-suite deferred` | Generate DEFERRED.md from ledger |
| `/radar-suite verify` | Re-verify all fixed findings |
| `/radar-suite verify RS-NNN` | Re-verify a single finding |
| `/radar-suite verify --changed` | Re-verify only findings in changed files |
| `/radar-suite link RS-NNN --root-cause-of RS-NNN [RS-NNN...]` | Link findings as root cause/symptom |
| `/radar-suite link RS-NNN --duplicate-of RS-NNN` | Mark finding as duplicate |
| `/radar-suite link RS-NNN --supersedes RS-NNN` | Mark finding as superseding another |
| `/radar-suite audit --changed` | Partial re-audit of files changed since last session |
| `/radar-suite audit --changed --since YYYY-MM-DD` | Partial re-audit since specific date |

## Available Skills

| Skill | Purpose | Est. Time |
|-------|---------|-----------|
| **data-model-radar** | Audit @Model layer for completeness, serialization, relationships | ~30-60 min |
| **time-bomb-radar** | Find deferred operations that crash on aged data | ~15-25 min |
| **roundtrip-radar** | Trace user workflows end-to-end for data safety | ~20-40 min |
| **ui-path-radar** | Find dead ends, broken promises, navigation issues | ~15-30 min |
| **ui-enhancer-radar** | Visual UI audit with design intent interview | ~20-45 min |
| **capstone-radar** | Aggregate grades, ship/no-ship decision | ~15-30 min |

---

## Session Setup (MANDATORY -- runs before anything else)

On EVERY `/radar-suite` invocation, check `.radar-suite/session-prefs.yaml`:

**If file exists AND has `experience_level` set:** Show stored preferences and ask `[Enter to continue] or type "change" to adjust settings.` Then proceed to Stale-Deferred Check, then Interactive Menu.

**If file does not exist OR `experience_level` is missing:** Run full setup below before presenting the menu, fix timing, or any audit work. Do NOT skip this. Do NOT jump to exploration.

### Setup Questions (single AskUserQuestion, 4 questions)

**Q1 — Experience level?**
- **Experienced (Recommended)** -- Concise, no definitions
- **Senior/Expert** -- Terse, file:line only
- **Intermediate** -- Standard terms, explain non-obvious
- **Beginner** -- Plain language, define terms

**Q2 — Table format?**
- **Full tables (Recommended)** -- 8-column Issue Rating Tables
- **Compact tables** -- 3-column with details below

**Q3 — Fix handling?**
- **Auto-fix safe items (Recommended)** -- Apply isolated, low-blast-radius fixes automatically
- **Review first** -- Present all findings, approve each wave
- **Batch mode** -- Approve all fixes in each wave at once

**Q4 — Explain what this skill does?**
- **No, let's go (Recommended)** -- Skip explanation
- **Yes, briefly** -- 3-5 sentence explanation

Store answers in `.radar-suite/session-prefs.yaml` as `experience_level`, `table_format`, `fix_mode`. See `radar-suite-core.md` for experience-level output rules.

### Execution Order

The invocation flow is strictly:
1. **Session Setup** (this section) -- configure or confirm preferences
2. **Stale-Deferred Check** -- check for overdue findings
3. **Fix Timing** -- ask when fixes should be applied (fresh audits only)
4. **Interactive Menu** -- choose what to audit
5. **Skill execution** -- run the selected skill(s)

Never skip steps 1-3. Never start exploration or scanning before completing them.

---

## Interactive Menu

On invocation without arguments, present:

```
Radar Suite — What would you like to audit?

1. **Full audit** — Run all 6 skills in recommended order (~2.5-4 hours)
2. **Data models** — Check @Model layer for gaps and inconsistencies
3. **Time bombs** — Find deferred operations that crash on aged data
4. **User workflows** — Trace data through complete user journeys
5. **Navigation paths** — Find dead ends and broken navigation
6. **UI polish** — Visual audit of specific views
7. **Release readiness** — Aggregate grades and ship/no-ship decision
8. **Resume** — Continue from last checkpoint
9. **Status** — Show current audit progress
10. **Ledger** — View all findings across skills with filters
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

## Stale-Deferred Check (v3.0 — MANDATORY on every invocation)

At every `/radar-suite` invocation (any command), read `.radar-suite/ledger.yaml` and check for deferred findings past their `review_by` date:

```
⚠️ 3 deferred findings are past their review date:
  RS-002 [CRITICAL] Cascade delete crash — review by Apr 8 (overdue 7 days)
  RS-011 [MEDIUM] DonationRecord FMV — review by Apr 10 (overdue 5 days)
  RS-019 [LOW] Spacing in SettingsView — review by Apr 12 (overdue 3 days)

Review now? [Yes / Snooze 7 days / Dismiss]
```

**On "Yes":** Present each overdue finding with options: Fix now, Re-defer (with new review date), Accept risk, Dismiss.

**On "Snooze":** Update `review_by` to today + 7 days for all overdue findings.

**On "Dismiss":** Proceed without reviewing. The check will fire again next invocation.

---

## DEFERRED.md Generation (v3.0)

`/radar-suite deferred` generates a markdown file from the ledger:

```markdown
# Deferred Findings

Auto-generated from .radar-suite/ledger.yaml. Do not edit directly.
Generated: 2026-04-08

| ID | Finding | Impact | Severity | Release Gate | Review By | Age |
|----|---------|--------|----------|-------------|-----------|-----|
| RS-002 | Cascade delete crash | crash | CRITICAL | pre-release | Apr 8 ⚠️ OVERDUE | 30d |
| RS-011 | DonationRecord FMV | data-loss | MEDIUM | post-release | Apr 10 | 28d |
| RS-019 | Spacing in SettingsView | polish | LOW | next-major | May 8 | 14d |
```

**Overdue items** are marked with ⚠️ OVERDUE.

**Age** is calculated from `discovered` date.

The file is written to the project root as `DEFERRED.md` (or `.radar-suite/DEFERRED.md` if the project root is not appropriate).

---

## Link Command (v3.0)

`/radar-suite link` creates relationships between findings in the ledger.

### Syntax

```
/radar-suite link RS-002 --root-cause-of RS-003 RS-004 RS-005
/radar-suite link RS-009 --duplicate-of RS-007
/radar-suite link RS-015 --supersedes RS-001
/radar-suite link RS-010 --symptom-of RS-002
```

### Behavior

1. Read the ledger
2. Validate that all referenced RS-NNN IDs exist
3. Create bidirectional relationships (root_cause ↔ symptom_of, duplicate_of is one-way)
4. Append history entries to all affected findings
5. Write the updated ledger

### Fix Cascade

When linking `--root-cause-of`, the system records the relationship so that when the root cause is later marked `fixed`, all symptoms automatically move to `pending_recheck`. See Finding Relationships in `radar-suite-core.md`.

---

## Verify Command (v3.0)

`/radar-suite verify` re-verifies fixed findings to catch regressions.

### How It Works

1. Read `.radar-suite/ledger.yaml`
2. Filter findings with status `fixed`
3. For each:
   - Compute current file hash (`shasum -a 256`)
   - Compare against `fixed.file_hash_at_fix`
   - If hash matches: file unchanged, skip (still fixed)
   - If hash differs: re-run `fixed.verification_pattern`
     - Pattern returns no match → confirmed still fixed (update hash)
     - Pattern matches → **regression detected** (reopen finding)

### Known-Intentional Cleanup

As part of verification, also check `.radar-suite/known-intentional.yaml` for orphaned entries:
1. For each entry, verify the `file` path still exists (glob match)
2. If the file has been deleted, flag the entry as orphaned
3. Report orphaned entries so the user can clean them up

```
Orphaned known-intentional entries:
  KI-003: Sources/Old/RemovedFile.swift — file no longer exists
  KI-007: Sources/Legacy/*.swift — no matching files

Options:
1. **Remove orphaned entries (Recommended)**
2. **Keep all** — leave for manual review
```

### Output

```
═══════════════════════════════════════════════
  RADAR SUITE VERIFY — [N] fixed findings checked
═══════════════════════════════════════════════

✓ RS-001 CSVManager.swift — still fixed (file unchanged)
✓ RS-003 BackupManager.swift — still fixed (re-verified)
✗ RS-014 PhotoManager.swift — REGRESSION DETECTED (force unwrap returned)
⚠ RS-019 SafeDeletionManager.swift — needs manual review (no grep pattern)

Summary: [N] confirmed, [N] regressions, [N] need manual review

Options:
1. **Fix regressions now (Recommended)** — address the [N] reopened findings
2. **Show regression details** — see what changed in each file
3. **Done** — exit verification
```

---

## Full Audit Sequence

When running full audit, execute skills in this order:

1. **data-model-radar** — Foundation layer, feeds model/relationship info to others
2. **time-bomb-radar** — Uses data-model findings to check deferred operations on aged data
3. **roundtrip-radar** — Uses data-model + time-bomb findings to focus on high-risk workflows
4. **ui-path-radar** — Navigation audit, independent of data layer
5. **ui-enhancer-radar** — Visual audit, runs on specific views
6. **capstone-radar** — Aggregates all findings, produces final grade
7. **Post-capstone fix session** — Fix deferred findings from all skills (see Fix Timing above)

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

## Ledger Command

`/radar-suite ledger` displays findings from `.radar-suite/ledger.yaml` -- the unified cross-skill finding store.

### Filters

| Flag | Description |
|------|-------------|
| `--open` | Show open findings only |
| `--deferred` | Show deferred findings only |
| `--fixed` | Show fixed findings only |
| `--accepted` | Show accepted findings only |
| `--impact [category]` | Filter by impact category: crash, data-loss, ux-broken, ux-degraded, polish, hygiene |
| `--skill [name]` | Filter by source skill (e.g., roundtrip-radar) |
| `--severity [level]` | Filter by severity: CRITICAL, HIGH, MEDIUM, LOW |

### Output Format

```
═══════════════════════════════════════════════
  RADAR SUITE LEDGER — [N] findings ([N] open, [N] fixed, [N] deferred)
  Last session: [skill] on [date]
═══════════════════════════════════════════════

CRASH RISK ([N] findings)
  RS-002 [CRITICAL] Cascade delete on archived items (time-bomb-radar) — open
  RS-014 [HIGH] Force unwrap on nil photo data (roundtrip-radar) — fixed 2026-04-10

DATA LOSS ([N] findings)
  RS-001 [HIGH] CSV export drops Room and UPC (roundtrip-radar) — open
  RS-007 [HIGH] InsuranceProfile not in backup (data-model-radar) — deferred (review by May 8)

UX BROKEN ([N] findings)
  RS-009 [HIGH] Settings > Export has no back button (ui-path-radar) — fixed 2026-04-09

POLISH ([N] findings)
  ...

Options:
1. **Filter** — apply additional filters
2. **Details [RS-NNN]** — show full finding details with history
3. **Fix [RS-NNN]** — mark a finding as fixed
4. **Defer [RS-NNN]** — defer a finding with reason and review date
5. **Done** — exit ledger view
```

### Finding Details

`/radar-suite ledger RS-001` shows full details:

```
RS-001 [HIGH] CSV export drops Room and UPC columns on import
  Status: open
  Impact: data-loss
  Source: roundtrip-radar (also flagged by: data-model-radar)
  File: Sources/Managers/CSVManager.swift:142
  Confidence: verified
  Evidence: grep confirmed importCSV reads 25 fields, exportCSV writes 27
  Discovered: 2026-04-08
  Related: RS-007, RS-011

  History:
    2026-04-08 discovered by roundtrip-radar
    2026-04-08 also flagged by data-model-radar
```

### No Ledger

If `.radar-suite/ledger.yaml` doesn't exist:

```
No finding ledger found. Run an audit skill to create one.
Recommended: /radar-suite full (run all skills) or /radar-suite data-model (start with foundation)
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

See `radar-suite-core.md` for: Experience-Level Output Rules, Session Persistence, Checkpoint & Resume, Accepted Risks, Wave-Based Fix Presentation, Table Format, Issue Rating Tables, Unified Finding Ledger Protocol.
