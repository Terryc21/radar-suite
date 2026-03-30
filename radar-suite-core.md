# Radar Suite Core — Shared Patterns

> All radar-suite skills inherit these patterns. Do NOT duplicate in individual skills.

---

## Session Setup (MANDATORY — first invocation only)

Ask all setup questions in ONE `AskUserQuestion` call with 4 questions:

**Question 1: "Experience level?"**
- **Experienced (Recommended)** — Concise, no definitions
- **Senior/Expert** — Terse, file:line only
- **Intermediate** — Standard terms, explain non-obvious
- **Beginner** — Plain language, define terms

**Question 2: "Table format?"**
- **Full tables (Recommended)** — 8-column Issue Rating Tables
- **Compact tables** — 3-column with details below

**Question 3: "Fix handling?"**
- **Auto-fix safe items (Recommended)** — Apply isolated, low-blast-radius fixes automatically
- **Review first** — Present all findings, approve each wave
- **Batch mode** — Approve all fixes in each wave at once

**Question 4: "Explain what this skill does?"**
- **No, let's go (Recommended)** — Skip explanation
- **Yes, briefly** — 3-5 sentence explanation

Store as: `USER_EXPERIENCE`, `TABLE_FORMAT`, `FIX_MODE`. Apply to ALL output for session.

**Batch mode behavior:** When enabled, group findings by `group_hint` and present one approval prompt per group instead of per-finding. User can still override individual items by typing "except [N]".

---

## Session Persistence (.session-prefs.yaml)

On first radar-suite skill invocation, check for `.radar-suite/session-prefs.yaml` in project root:

```yaml
# .radar-suite/session-prefs.yaml
experience_level: experienced  # beginner|intermediate|experienced|senior
table_format: full             # full|compact
fix_mode: auto                 # auto|review|batch
last_skill: data-model-radar
last_session: 2026-03-29T10:30:00Z
accepted_risks: []             # finding IDs marked "accept risk"
```

**If file exists:** Show one-line summary and ask to confirm or change:
```
Using: Experienced, Full tables, Auto-fix. Last session: data-model-radar (2 days ago).
[Enter to continue] or type "change" to adjust settings.
```

**If file doesn't exist:** Run full Session Setup, then create the file.

**On session end:** Update `last_skill` and `last_session` timestamps.

**Cross-skill persistence:** All radar-suite skills read/write the same file, so preferences carry across skill transitions.

---

## Checkpoint & Resume

After completing each major phase/domain, write checkpoint to `.radar-suite/checkpoint.yaml`:

```yaml
# .radar-suite/checkpoint.yaml
skill: roundtrip-radar
version: 1.4.0
timestamp: 2026-03-29T10:45:00Z
phase_completed: 2
next_phase: 3
domains_completed: [1, 2]
domains_remaining: [3, 4, 5]
findings_so_far: 7
tool_calls: 42
can_resume: true
resume_instructions: "Continue with Domain 3: Relationship Integrity"
```

**On skill invocation:** Check for checkpoint. If exists and `can_resume: true`:
```
Found checkpoint from [timestamp]: [skill] Phase [N] completed.
1. **Resume** — continue from Phase [N+1]
2. **Start fresh** — discard checkpoint and restart
3. **View checkpoint** — show what was completed
```

**Context exhaustion guard:** When tool_calls approaches 50, write checkpoint immediately with `resume_instructions` describing exactly where to continue.

**On completion:** Delete checkpoint file (audit is done).

**On abort:** Keep checkpoint so next session can resume.

---

## Accepted Risks

Users can mark findings as "accept risk" to suppress them in future audits.

**When presenting findings, include option:**
```
5. **Accept risk** — I understand this issue; don't report it again
```

**On accept:** Add finding ID to `accepted_risks` in session-prefs.yaml:
```yaml
accepted_risks:
  - id: "roundtrip-csv-room-missing"
    reason: "Room field intentionally excluded from CSV export"
    accepted_on: 2026-03-29
    expires: null  # or YYYY-MM-DD for temporary acceptance
```

**On future audits:**
1. Check if finding matches an accepted risk (by ID or file+pattern)
2. If matched and not expired: skip silently
3. If matched but expired: re-present with note "Previously accepted risk expired"

**Audit report footer:**
```
Suppressed: 3 previously accepted risks (type "show accepted" to review)
```

**Commands:**
- `show accepted` — list all accepted risks
- `clear accepted [id]` — remove specific acceptance
- `clear all accepted` — reset all acceptances

---

## Wave-Based Fix Presentation

Present fixes in waves, not one-by-one. Group by `group_hint` from handoff YAML.

**Per-wave prompt (replaces per-finding prompts):**
```
Wave [N]: [group_hint description] — [count] fixes

| # | Finding | Urgency | Blast Radius | Fix Effort |
|---|---------|---------|--------------|------------|
| 1 | ... | 🟡 HIGH | 2 files | Small |
| 2 | ... | 🟢 MED | 1 file | Trivial |

Options:
1. **Apply all** — fix all [N] items in this wave
2. **Apply except [N,N]** — skip specific items (type numbers)
3. **Review individually** — switch to per-item approval for this wave
4. **Skip wave** — defer all to next session
```

**When FIX_MODE = "Batch mode":** Apply all unless user objects within 5 seconds (print countdown).

**When FIX_MODE = "Auto-fix safe":** Auto-apply if ALL items in wave have Blast Radius ≤ 2 files AND Fix Effort = Trivial/Small.

---

## Fix-Forward Bias (MANDATORY)

When presenting options with a "(Recommended)" label, **default to fixing over deferring** for any finding that is:
- **In scope** — part of the current workflow/file being audited
- **Reasonable effort** — Fix Effort is Trivial, Small, or Medium
- **User is present** — not in hands-free mode

### Why This Matters

A pattern of "Recommended: Defer" teaches users to always defer, creating a growing backlog that makes the skill feel unproductive. Users — especially less experienced ones — will follow the recommended option. If that option is always "defer," they accumulate findings across multiple sessions without resolving them, and eventually conclude the skill isn't worth running.

### Rules

1. **Recommend fixing** when the finding is in scope and effort ≤ Medium. This is the default.
2. **Recommend deferring** only when the fix requires:
   - Large effort (60+ min)
   - Architectural discussion or schema migration
   - Cross-team coordination
   - Changes outside the audited workflow that could destabilize unrelated features
3. **Between-workflow prompts:** Recommend proceeding to the next workflow, not stopping. Only recommend stopping when context is genuinely running low or the session has been long.
4. **Design decisions:** Recommend the most productive option (usually "fix now"), not the most conservative ("defer and discuss later"). Present the tradeoffs honestly, but don't default to caution when the fix is straightforward.
5. **Never label "defer" or "stop" as Recommended** unless one of the conditions in rule 2 applies.

### Wave Prompt Adjustment

In the per-wave prompt, option ordering communicates priority:
1. **Apply all (Recommended)** — always first, always recommended
2. **Apply except [N,N]** — selective fix
3. **Review individually** — more control
4. **Skip wave** — last resort, never recommended

---

## Plain Language Communication (MANDATORY)

All user-facing prompts must be understandable by first-time users:

1. Describe findings in plain terms ("2 critical backup gaps") — not categories ("2 Domain 2 findings")
2. Describe next steps by what they DO ("check UI flows for dead ends") — not skill names
3. Describe options by outcome and time ("Fix backup gaps now (~15 min)")
4. Add "Explain more" option to transition prompts
5. Define jargon on first use:
   - "Domain" → check area / audit category
   - "Wave" → fix batch
   - "Handoff" → file so other skills can continue
   - "Serialization" → saving/loading data (backup, CSV, cloud)
   - "Blast radius" → how many files a fix touches
6. **Exception:** Senior/Expert level = terse references acceptable

---

## Work Receipts (MANDATORY — every verified finding)

Every `verified` finding must include proof of what was checked. No receipt = automatic downgrade to `probable`.

A work receipt includes:
- **File read:** specific file path and line range
- **Pattern searched:** grep pattern or search term
- **Evidence found:** 1-3 lines of code confirming the finding

**Example (verified):**
```
Finding: Room column not imported in CSV
Receipt: Read CSVImportManager.swift:420-447. Searched for `item.room =` — 0 matches.
Confidence: verified
```

**Example (downgraded):**
```
Finding: Room column not imported in CSV
Receipt: none (structural analysis only)
Confidence: probable (upgrade by reading CSVImportManager.swift)
```

---

## Contradiction Detection (MANDATORY — before final grades)

Run these mechanical checks before presenting grades:

1. **Findings vs grade:** CRITICAL findings cap grade at C. HIGH findings cap at B+. Note: "Grade capped from [X] to [Y] due to [N] [severity] findings."

2. **Handoff vs grade:** Blockers in handoff = grade cannot be A.

3. **Self-consistency:** Contradicting findings in same report must be flagged and resolved.

---

## Finding Classification

| Type | Criteria | How to Verify |
|------|----------|---------------|
| **Bug** | Code does wrong thing | Behavior contradicts intent |
| **Stale Code** | Was correct, codebase outgrew it | `git log -1 -- <file>` shows old date; model grew since |
| **Design Choice** | Documented intentional limitation | Requires evidence: CLAUDE.md, code comment, or pattern |

**Default to Stale Code** if no documentation exists. Frame as growth, not criticism.

---

## Audit Methodology (governs scanning)

### Principle 1: Enumerate-Then-Verify

For `enumerate-required` domains: list ALL candidate files first, then verify each.

```
WRONG: Grep for anti-pattern → Report matches → Grade
RIGHT: Enumerate ALL files → Subtract skip list → Verify each → Report missing patterns
```

### Principle 2: File-Scoped Skip Lists

A resolved finding applies to THAT FILE ONLY. Do not propagate "clean" across call graphs.

### Principle 3: Negative Pattern Matching

To find "X without Y": search for X first, verify Y exists around it.

| Tier | Name | Criteria |
|------|------|----------|
| A | Almost certain | Same file has verified violations |
| B | Probable | View type implies pattern applies |
| C | Possible | Subject exists without pattern, context ambiguous |

---

## Context Exhaustion (50+ tool calls)

After 50 tool calls:
1. Downgrade new findings from `verified` to `probable (long context)`
2. Print warning suggesting session split
3. Tag findings with `confidence_note`
4. Add `context_exhaustion_after: [N]` to handoff YAML
5. Next session re-verifies those findings FIRST

---

## Progress Banner (after every phase/commit)

```
═══════════════════════════════════════════════
  [SKILL NAME] — Phase [N]: [Phase Name]
  ✓ [completed items]
  → [current/next item]
  [N] findings | [N] fixed | [N] remaining
═══════════════════════════════════════════════
```

Always follow with `AskUserQuestion`. Never leave blank prompt.

---

## Issue Rating Table Format

**8 columns required (no exceptions):**

| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|---------|-----------|--------------|-----|--------------|------------|

**Indicator scale:**
- 🔴 Critical/high concern (ROI: poor return)
- 🟡 High/notable (ROI: marginal)
- 🟢 Medium/moderate (ROI: good)
- ⚪ Low/negligible
- 🟠 Pass/positive (ROI: excellent)

**Urgency scale:**
- 🔴 CRITICAL — pre-launch blocker OR data loss/crash risk
- 🟡 HIGH — user-visible or stability risk; fix before release
- 🟢 MEDIUM — real issue; acceptable to schedule
- ⚪ LOW — nice-to-have; minimal impact

---

## Handoff YAML Schema (common fields)

```yaml
# .radar-suite/[skill]-handoff.yaml
skill: [skill-name]
version: [skill-version]
timestamp: [ISO-8601]
session_id: [unique-id]
experience_level: [USER_EXPERIENCE]
table_format: [TABLE_FORMAT]
fix_mode: [FIX_MODE]

# Audit summary
domains_audited: [count]
domains_clean: [count]
overall_grade: [A-F or null if incomplete]

# Cross-skill suspects (for downstream skills to investigate)
suspects:
  - file: [path]
    reason: "High-risk serialization gap — verify in roundtrip-radar"
    from_domain: "Domain 2: Serialization"
    priority: high

# Findings with enhanced fields
findings:
  - id: [unique-hash]
    description: [plain language]
    confidence: verified|probable|possible
    urgency: critical|high|medium|low
    status: open|fixed|deferred|accepted
    file: [path]
    line: [number]
    file_last_modified: [ISO-8601]
    group_hint: [category for batch operations]
    related_findings: [list of IDs this finding connects to]
    fix_applied: [description of fix if status=fixed]
    test_added: [test file path if applicable]

# Session metadata
context_exhaustion_after: [N or null]
tool_calls: [count]
duration_minutes: [number]
accepted_risks_suppressed: [count]
```

**Cross-skill handoff rules:**
1. data-model-radar → roundtrip-radar: Pass `suspects` for serialization gaps
2. roundtrip-radar → capstone-radar: Pass workflow-level findings
3. ui-path-radar → ui-enhancer-radar: Pass dead-end views for visual audit
4. All → capstone-radar: Pass `overall_grade` for aggregation

---

## Completion Prompt Pattern

```
I found [X] issues:
- [N] critical (brief description)
- [N] high / [N] medium / [N] low

You can:
1. **Fix critical issues now** (~[time]) — [description]
2. **Fix quick wins only** (~[time]) — [description]
3. **Keep auditing other areas** — [description of next area]
4. **Explain more** — walk through what each issue means
```
