# Radar-Suite Optimization Plan

**Created:** 2026-03-29
**Goal:** Reduce token usage ~35%, improve UX, maintain accuracy

---

## Phase 1: Quick Wins (No Risk)
**Est. Time:** 30 min | **Token Savings:** ~15%

### 1.1 Fix Naming Inconsistency
- [ ] Rename roundtrip-radar header from "Workflow Code Audit" to "Roundtrip Radar"
- [ ] Standardize terminology table in each skill header

### 1.2 Remove Unnecessary Warnings
- [ ] Remove "YOU MUST EXECUTE THIS WORKFLOW" from all 5 skills
- [ ] Trim end-of-file reminders to 2 lines each

### 1.3 Condense Finding Classification
- [ ] Replace ~45-line section with ~12-line table version in all 5 skills

### 1.4 Simplify Progress Banners
- [ ] Replace verbose box-drawing format with simple 2-line format
- [ ] Update all 5 skills

### 1.5 Add Calibrated Fix Effort Definitions
- [ ] Add once in radar-suite-core.md (created in Phase 2)
- [ ] Remove subjective "Trivial/Small/Medium/Large" without criteria

---

## Phase 2: Extract Shared Boilerplate
**Est. Time:** 1 hour | **Token Savings:** ~20%

### 2.1 Create radar-suite-core.md
Location: `/Volumes/2 TB Drive/Coding/GitHub/radar-suite/radar-suite-core.md`

Extract these sections (appear identically in all 5 skills):
- [ ] Work Receipts (~25 lines)
- [ ] Contradiction Detection (~20 lines)
- [ ] Finding Classification (condensed ~12 lines)
- [ ] Audit Methodology - 3 Principles (~55 lines)
- [ ] Table Format section (~15 lines, already updated)
- [ ] Permission Modes (~20 lines)
- [ ] Issue Rating Table format + Indicator Scale (~30 lines)
- [ ] Fix Effort Definitions (~8 lines)
- [ ] Progress Banner rules (~10 lines)

### 2.2 Add Import Mechanism
Each skill header gets:
```yaml
imports:
  - radar-suite-core
```

### 2.3 Update All 5 Skills
- [ ] capstone-radar: Remove duplicated sections, add import
- [ ] data-model-radar: Remove duplicated sections, add import
- [ ] roundtrip-radar: Remove duplicated sections, add import
- [ ] ui-path-radar: Remove duplicated sections, add import
- [ ] ui-enhancer-radar: Remove duplicated sections, add import

### 2.4 Verify No Functionality Lost
- [ ] Diff before/after to confirm only formatting changes
- [ ] Test one skill invocation to verify import works

---

## Phase 3: UX Improvements
**Est. Time:** 45 min | **Token Savings:** ~5%

### 3.1 Consolidate Setup Questions
Replace 4 separate questions with 1 smart-default question:
```markdown
## Quick Start (ask once)

**Question:** "How should I run this audit?"
- **Quick start (Recommended)** — Experienced mode, auto-fix safe items, display results
- **Customize** — Choose experience level, fix mode, output format
- **Hands-free** — Read-only analysis, no prompts
```

Update in all 5 skills.

### 3.2 Add Batch Mode Option
After presenting fix plan:
```markdown
- **Fix all (Recommended)** — Run all waves, stop only for design decisions
- **Wave by wave** — Approve each wave before proceeding
- **Pick specific** — Choose which findings to fix: [1, 3, 5]
```

### 3.3 Conditional "Explain More"
Only show "Explain more" option if `USER_EXPERIENCE` is Beginner or Intermediate.

### 3.4 Remove Verbose Experience Explanations
Replace 4 pre-written explanation variants with instruction to generate on-the-fly.

---

## Phase 4: Session Persistence
**Est. Time:** 1 hour | **New Feature**

### 4.1 Session Preferences File
Create `.agents/ui-audit/.session-prefs.yaml` on first skill run:
```yaml
experience_level: experienced
table_format: full
fix_mode: auto-fix
last_skill: data-model-radar
last_run: 2026-03-29T14:30:00Z
```

### 4.2 Read Preferences on Skill Start
- [ ] Check for .session-prefs.yaml before asking setup questions
- [ ] If exists and <4 hours old, use stored prefs
- [ ] Show one-line confirmation: "Using: Experienced, Full tables, Auto-fix. Say 'adjust' to change."

### 4.3 Update All Skills
- [ ] Add session-prefs read/write to all 5 skills

---

## Phase 5: Checkpoint & Resume
**Est. Time:** 1.5 hours | **New Feature**

### 5.1 Checkpoint File Format
`.agents/ui-audit/.checkpoint.yaml`:
```yaml
skill: roundtrip-radar
step: 3
total_steps: 5
findings_so_far: 7
workflows_completed: ["Backup", "Add Item"]
workflows_remaining: ["Export", "Sync"]
started: 2026-03-29T14:30:00Z
last_update: 2026-03-29T15:45:00Z
```

### 5.2 Write Checkpoint After Each Step
- [ ] Add checkpoint write after each step/layer/phase completion
- [ ] Include enough state to resume

### 5.3 Resume Detection on Start
```markdown
Found incomplete audit from 1 hour ago:
  Skill: roundtrip-radar
  Progress: Step 3/5 (7 findings, 2 workflows done)

Resume or start fresh?
```

### 5.4 Clear Checkpoint on Completion
- [ ] Delete checkpoint file when audit completes successfully

---

## Phase 6: Accepted Risks
**Est. Time:** 45 min | **New Feature**

### 6.1 Accepted Risks File Format
`.agents/ui-audit/.accepted-risks.yaml`:
```yaml
risks:
  - file: BackupManager.swift
    pattern: "try! in production"
    line: 142
    reason: "File existence guaranteed by app bundle"
    accepted_by: Terry
    accepted_date: 2026-03-15

  - file: CloudSyncManager.swift
    pattern: "force unwrap"
    line: 89
    reason: "Guarded by if-let on line 87"
    accepted_by: Terry
    accepted_date: 2026-03-20
```

### 6.2 Check Accepted Risks During Scan
- [ ] Before reporting a finding, check if it matches an accepted risk
- [ ] If file changed since acceptance, flag for re-review
- [ ] Skip silently if file unchanged

### 6.3 Add "Accept Risk" Action
After presenting findings:
```markdown
- Accept as intentional — Add to accepted risks, skip in future audits
```

---

## Phase 7: Unified Entry Point
**Est. Time:** 30 min | **New Feature**

### 7.1 Create radar-suite Skill
`/Volumes/2 TB Drive/Coding/GitHub/radar-suite/skills/radar-suite/SKILL.md`

```markdown
# Radar Suite

Entry point for the 5-skill radar family.

## Commands
- `/radar-suite` — Run recommended audit sequence
- `/radar-suite [skill]` — Run a specific skill
- `/radar-suite status` — Show audit coverage
- `/radar-suite history` — List past audits
- `/radar-suite cleanup` — Remove old files from .agents/
```

### 7.2 Recommended Sequence
```
1. data-model-radar (foundation)
2. ui-path-radar (navigation)
3. roundtrip-radar (data flows)
4. ui-enhancer-radar (visual)
5. capstone-radar (ship decision)
```

### 7.3 Create Command Wrapper
`~/.claude/commands/radar-suite.md`

---

## Phase 8: Handoff Improvements
**Est. Time:** 30 min | **Enhancement**

### 8.1 Lazy Handoff Loading
Before reading all 4 handoffs:
```bash
ls .agents/ui-audit/*-handoff.yaml 2>/dev/null | wc -l
```
Only read if count > 0.

### 8.2 Handoff Status Updates
After fixing an issue from a companion handoff:
```yaml
blockers:
  - finding: "Force unwrap in error path"
    urgency: HIGH
    status: fixed  # ← added
    fixed_commit: abc123
    fixed_date: 2026-03-29
```

### 8.3 Stale Handoff Detection
Compare `file_timestamps` against current file mod dates. Flag if source changed since handoff was written.

---

## Phase 9: Structural Refactoring (Optional)
**Est. Time:** 2 hours | **Low Priority**

### 9.1 Split ui-enhancer-radar
Only if skills support file imports. Otherwise defer.

- `ui-enhancer-radar/SKILL.md` — Core workflow (~800 lines)
- `ui-enhancer-radar/domains.md` — 11 domain definitions (~1000 lines)
- `ui-enhancer-radar/color-audit.md` — Color-specific logic (~500 lines)

### 9.2 Add Trace Command to ui-path-radar
Port trace command from roundtrip-radar for consistency.

### 9.3 Add History Command to capstone-radar
```markdown
/capstone-radar history — List past audits with grades
```

---

## Implementation Order

| Phase | Priority | Effort | Impact | Dependencies |
|-------|----------|--------|--------|--------------|
| 1 | 🔴 HIGH | 30 min | ~15% tokens | None |
| 2 | 🔴 HIGH | 1 hr | ~20% tokens | Phase 1 |
| 3 | 🟡 MED | 45 min | UX improvement | Phase 2 |
| 4 | 🟡 MED | 1 hr | Cross-skill memory | Phase 3 |
| 5 | 🟡 MED | 1.5 hr | Context resilience | Phase 4 |
| 6 | 🟢 LOW | 45 min | Noise reduction | None |
| 7 | 🟢 LOW | 30 min | Discoverability | Phase 2 |
| 8 | 🟢 LOW | 30 min | Efficiency | None |
| 9 | ⚪ OPT | 2 hr | Modularity | Phase 2 |

**Total estimated time:** ~8.5 hours (excluding Phase 9)

---

## Success Metrics

| Metric | Before | Target |
|--------|--------|--------|
| Avg skill file size | ~1,200 lines | ~700 lines |
| Setup questions per skill | 4 | 1 |
| Duplicate sections | 8 | 0 |
| Time to first output | ~30s | ~10s |
| Prompts per full audit | ~15 | ~5 |

---

## Rollback Plan

Each phase is independent. If a change causes problems:
1. Git revert the phase commit
2. Verify skills still work
3. Document what went wrong
4. Revise approach

---

## Notes

- Phase 2 (shared boilerplate) requires testing import mechanism
- Phase 5 (checkpoint) is most complex; may need iteration
- Phase 9 is optional pending import support verification
