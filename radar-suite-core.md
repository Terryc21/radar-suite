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

## Environment Pre-flight (runs silently during setup)

After session setup completes, check the project environment:

1. Run `pwd` — if output contains no space character, skip this section entirely
2. If path has spaces, run `command -v dippy` to check if Dippy is installed
3. If Dippy is NOT installed, print this note (do not block the audit):

> **Note:** Your project path contains spaces, which triggers extra permission prompts during audits. Install [Dippy](https://github.com/ldayton/Dippy) to auto-approve safe commands:
> ```
> brew tap ldayton/dippy && brew install dippy
> ```
> A sample `.dippy` config for audit workflows is included in the radar-suite repo.

4. Store result in `.radar-suite/session-prefs.yaml` under `dippy_check`:
   ```yaml
   dippy_check:
     path_has_spaces: true
     dippy_installed: false
     checked_on: 2026-03-30
   ```
5. Skip this check on subsequent skill invocations if `checked_on` matches today

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

## Test Hygiene (MANDATORY)

Fixes without tests are unverified code. But new tests alongside stale tests create a false sense of coverage.

### Adding Tests

Every fix must have a test. The test verifies the fix works — without it, you're shipping a code change you can't prove is correct. If the fix is in logic (not pure UI), write the test before moving to the next wave.

### Removing or Revising Stale Tests

During the pattern sweep (after fixes, before commit), scan test files that correspond to modified source files for:

1. **Assertions on changed values** — a test that checks `version == "2.0"` when the code now writes `"2.5"` passes for the wrong reasons or fails for irrelevant ones
2. **Tests for removed behavior** — if you deleted a code path, delete its test. A test for dead code is noise that obscures real coverage gaps.
3. **Tests that verify old defaults** — if a fix changes a default value, fallback, or error message, find tests that assert the old default and update them

### How to Find Stale Tests

For each source file modified in the current wave:
1. Search `Tests/` for the corresponding test file (e.g., `BackupManager.swift` → `BackupManagerTests.swift`)
2. Grep the test file for string literals, constants, or field names that changed in your fix
3. If a test asserts a value you just changed, update or remove it

### The Geological Test Problem

Tests are subject to the same geological layering as production code (Chapter 14). Early tests verify early assumptions. The app grows, the tests don't, and they either:
- **Pass vacuously** — testing behavior that no longer matters
- **Fail for the wrong reason** — asserting an old value that was intentionally changed
- **Block correct fixes** — a test that enforces yesterday's behavior prevents today's improvement

Treat test files as code that needs auditing, not as fixed ground truth.

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

## Unified Finding Ledger Protocol (v3.0)

All radar-suite skills write findings to a shared ledger at `.radar-suite/ledger.yaml`. The ledger provides cross-skill visibility, deduplication, and finding lifecycle management. Individual handoff YAMLs are still written for backward compatibility.

### Ledger Schema

```yaml
# .radar-suite/ledger.yaml
version: 1
next_id: 1

sessions:
  - id: "<ISO-8601 timestamp>"
    skills_run: [data-model-radar, time-bomb-radar]
    build: "1.0 (30)"

findings:
  - id: RS-001
    status: open              # open | fixed | deferred | accepted
    impact_category: data-loss # crash | data-loss | ux-broken | ux-degraded | polish | hygiene
    source_skill: roundtrip-radar
    summary: "CSV export drops Room and UPC columns on import"
    file: "Sources/Managers/CSVManager.swift"
    line: 142
    confidence: verified       # verified | probable | possible
    severity: HIGH             # CRITICAL | HIGH | MEDIUM | LOW
    discovered: "<ISO-8601>"
    file_hash: "a3f2c1"       # first 6 chars of SHA-256 of file content at discovery
    evidence: "grep confirmed importCSV reads 25 fields, exportCSV writes 27"
    group_hint: "csv_roundtrip"
    also_flagged_by: []        # other skills that found the same issue
    related_to: []             # RS-NNN IDs of findings about the same file/region
    relationships: []          # root_cause, symptom_of, duplicate_of, supersedes (Phase 4)
    history:
      - date: "<ISO-8601>"
        action: discovered
        by: roundtrip-radar
```

### Impact Categories

| Category | Description | Example |
|----------|-------------|---------|
| `crash` | Will crash or force-close | Cascade delete on aged data, force unwrap |
| `data-loss` | Silent data loss or corruption | Export drops fields, backup misses model |
| `ux-broken` | Feature doesn't work | Dead-end screen, button does nothing |
| `ux-degraded` | Feature works but poorly | Buried CTA, missing empty state |
| `polish` | Visual/consistency issues | Spacing, color contrast, dark mode |
| `hygiene` | Code quality, no user impact | Dead fields, naming inconsistency |

### Deferred Finding Schema

When a finding is deferred, add a `deferred` block:

```yaml
  - id: RS-002
    status: deferred
    # ... standard fields ...
    deferred:
      reason: "Needs SwiftData migration strategy"
      release_gate: pre-release  # pre-release | post-release | next-major
      review_by: "2026-05-08"
      deferred_on: "2026-04-08"
```

### Fixed Finding Schema

When a finding is fixed, add a `fixed` block:

```yaml
  - id: RS-001
    status: fixed
    # ... standard fields ...
    fixed:
      commit: "a3f2c1d"
      fixed_on: "2026-04-10"
      file_hash_at_fix: "c5d4e3"
      verification_pattern: "grep 'importCSV.*Room' Sources/Managers/CSVManager.swift"
```

### Accepted Finding Schema

When a finding is accepted (risk acknowledged), add an `accepted` block:

```yaml
  - id: RS-019
    status: accepted
    # ... standard fields ...
    accepted:
      reason: "Room field intentionally excluded from CSV"
      accepted_on: "2026-04-08"
      decay_after_days: 180
      last_reviewed: "2026-04-08"
```

### Ledger Write Rules (MANDATORY for all audit skills)

Every audit skill MUST follow this protocol:

1. **Read ledger at startup.** If `.radar-suite/ledger.yaml` exists, load it. If not, initialize with `version: 1`, `next_id: 1`, empty `sessions` and `findings`.

2. **Record the session.** Append a session entry with the current timestamp, skill name, and build number.

3. **Check for duplicates before creating findings.** For each new finding, check the ledger for existing findings where:
   - Same `file` AND overlapping line range (within 10 lines)
   - OR same `file` AND same `group_hint`
   If a match is found with status `open` or `deferred`, do NOT create a duplicate. Instead, add the current skill to the existing finding's `also_flagged_by[]` and append a history entry.

4. **Assign RS-NNN IDs.** For genuinely new findings, assign the next available ID from `next_id` and increment the counter. IDs are monotonic and never reused.

5. **Assign impact_category.** Classify each finding using the impact categories table above. When in doubt, use the more severe category.

6. **Compute file_hash.** For each finding's file, compute SHA-256 and store the first 6 characters:
   ```bash
   shasum -a 256 "<file path>" | cut -c1-6
   ```

7. **Write history entries.** Every status change (discovered, fixed, deferred, accepted, reopened) gets a timestamped history entry with the acting skill or "user".

8. **Write the ledger.** Save `.radar-suite/ledger.yaml` after completing the audit.

9. **Continue writing handoff YAML.** The existing per-skill handoff YAML is still written for backward compatibility. The ledger is the cross-skill view; handoffs remain per-skill detail.

### Ledger Startup Check

On any `/radar-suite` invocation, the ledger is loaded and checked. Individual audit skills read the ledger to:
- Avoid re-reporting known findings
- Check if previously-fixed findings need re-verification (file hash changed)
- Incorporate existing finding context into their audit

---

## Cross-Skill Deduplication (v3.0)

When a skill is about to create a finding, it MUST check the ledger for duplicates. The dedup check in Ledger Write Rule #3 covers the basic case. This section covers advanced scenarios.

### Same Issue, Different Angle

When two skills find the same root issue from different perspectives (e.g., data-model-radar flags a missing backup field, roundtrip-radar finds the same field lost on round-trip):

1. Do NOT create a duplicate finding
2. Add the current skill to the existing finding's `also_flagged_by[]`
3. Append a history entry: `action: also_flagged, by: [skill], note: "[perspective]"`
4. If the new skill's evidence is stronger (e.g., verified vs probable), upgrade the finding's `confidence`

### Different Issue, Same File

When two skills find different issues in the same file (e.g., data-model-radar flags a dead field, ui-path-radar flags a broken button in the same view):

1. Create a new finding with its own RS-NNN ID
2. Add `related_to: [RS-NNN]` linking to the existing finding in the same file
3. The existing finding also gets the new ID added to its `related_to[]`

### Match Criteria

Two findings are considered the "same issue" when ANY of these are true:
- Same `file` AND line numbers within 10 lines of each other
- Same `file` AND same `group_hint`
- Same `summary` text (fuzzy -- same semantic meaning, not exact string match)

When in doubt, create a new finding and link via `related_to`. False negatives (two entries for the same issue) are less harmful than false positives (merging distinct issues).

---

## Cross-Skill Contradiction Detection (v3.0 -- capstone-radar)

After collecting all findings and companion grades, capstone-radar runs these mechanical checks:

### Grade-vs-Findings Contradictions

| Condition | Action |
|-----------|--------|
| Companion gives A- or higher but ledger has 3+ HIGH findings in that domain | Flag: "[skill] graded A- but [N] HIGH findings exist in ledger. Re-evaluate grade." |
| Companion gives C or lower but all findings in that domain are fixed | Flag: "Grade may be stale. All [N] findings resolved since last audit." |
| Two skills disagree on severity for related findings | Flag: "RS-NNN rated HIGH by [skill1], MEDIUM by [skill2]. Reconcile." |

### Resolution

For each contradiction:
1. Present both sides with evidence
2. Ask the user to resolve: accept higher grade, accept lower grade, or re-audit the domain
3. Record the resolution in the ledger as a history entry

Contradictions are informational -- they don't automatically change grades. But unresolved contradictions prevent a SHIP recommendation.

---

## Regression Detection & Fix Verification (v3.0)

### File Hash Protocol

Each finding stores `file_hash` -- the first 6 characters of SHA-256 of the file content at discovery or fix time. This enables regression detection.

**Computing the hash:**
```bash
shasum -a 256 "<file path>" | cut -c1-6
```

**When to update:**
- On discovery: store as `file_hash`
- On fix: store as `fixed.file_hash_at_fix`

### Regression Check (on audit startup)

Every audit skill checks fixed findings at startup:

1. Read the ledger and filter findings with status `fixed`
2. For each fixed finding, compute current file hash
3. If the current hash differs from `fixed.file_hash_at_fix`: the file has changed since the fix was applied

```
⚠️ 2 fixed findings may need re-verification (files changed since fix):
  RS-001 [fixed] CSVManager.swift — changed 3 days ago
  RS-014 [fixed] PhotoManager.swift — changed today

Re-verify now? [Yes / Skip / Mark as needs-review]
```

**On "Yes":** Re-run the original detection pattern (from `fixed.verification_pattern`). If the pattern still matches, reopen the finding (status back to `open`, append history). If the pattern no longer matches, confirm as still fixed (update `file_hash_at_fix`).

**On "Skip":** Proceed with the audit. The findings remain `fixed` but are flagged for next session.

**On "Mark as needs-review":** Set status to `pending_recheck`, which prevents capstone from counting them as resolved.

### Fix Verification Command

`/radar-suite verify` -- re-verify all fixed findings:

1. For each `fixed` finding in the ledger:
   - Re-run the verification pattern (from `fixed.verification_pattern`)
   - If pattern no longer matches: confirmed fixed (update hash)
   - If pattern still matches: reopen (status → `open`, append history)
2. Report results

`/radar-suite verify RS-001` -- verify a single finding.

`/radar-suite verify --changed` -- only verify findings in files that have changed (hash mismatch).

### Verification Pattern Storage

When a finding is fixed, store a verification pattern that can later confirm the fix is still in place:

```yaml
fixed:
  verification_pattern: "grep 'importCSV.*Room' Sources/Managers/CSVManager.swift"
```

The pattern should be a grep command that would match the original bug. If the grep returns results, the bug is back. If it returns nothing, the fix holds.

Not all findings have simple grep patterns. For complex fixes, store a description instead:

```yaml
fixed:
  verification_pattern: "manual: check that batch delete is used instead of object delete in SafeDeletionManager.swift:89"
```

Manual verification patterns require the skill to read the file and verify the fix is intact.

---

## Finding Relationships (v3.0)

Findings can be linked to express causal and lifecycle relationships. These links enable fix cascading -- when a root cause is fixed, its symptoms are automatically flagged for re-check.

### Relationship Types

```yaml
relationships:
  - type: root_cause    # this finding is the root cause of others
    targets: [RS-003, RS-004, RS-005]
  - type: symptom_of    # this finding is a symptom of another
    target: RS-002
  - type: duplicate_of  # exact same issue found by different skill
    target: RS-007
  - type: supersedes    # this finding replaces an older one
    target: RS-001
```

### Auto-Inference Rules (capstone-radar)

When capstone runs, scan for these relationship patterns:

| Pattern | Relationship |
|---------|-------------|
| Data-model gap + roundtrip data loss in same model | data-model finding is `root_cause`, roundtrip finding is `symptom_of` |
| UI-path dead end + ui-enhancer missing button in same view | Link as `related_to` (neither is clearly root cause) |
| Time-bomb + roundtrip aged-data failure for same deletion code | time-bomb finding is `root_cause` |
| Two skills flag the exact same file:line | Earlier finding gets `duplicate_of` link to newer one (or merge via dedup) |

### Root-Cause Fix Cascade

When a finding with `root_cause` relationship is marked `fixed`:

1. All `symptom_of` findings move to status `pending_recheck`
2. The next audit run re-verifies each symptom
3. If symptom is gone: auto-mark `fixed` with history entry `resolved_by: "root cause RS-NNN fixed"`
4. If symptom persists: reopen as independent finding (remove `symptom_of` link)

### Manual Linking

Users can create relationships via `/radar-suite link`:

```
/radar-suite link RS-002 --root-cause-of RS-003 RS-004
/radar-suite link RS-009 --duplicate-of RS-007
/radar-suite link RS-015 --supersedes RS-001
```

---

## Confidence Decay (v3.0)

Accepted findings are not permanent. Over time, the codebase changes and an accepted risk may no longer be valid -- the field might have been renamed, the workaround removed, or the context that justified the acceptance changed.

### Decay Rules

Findings with status `accepted` have a `decay_after_days` field (default: 180 days). At every `/radar-suite` invocation, check for accepted findings older than their decay threshold:

```
📋 1 accepted finding is due for re-evaluation (180+ days old):
  RS-019 [accepted] Room excluded from CSV — accepted Apr 8, 2026

Still valid? [Yes, extend 180 days / Reopen / Change to deferred]
```

**On "Yes, extend":** Update `accepted.last_reviewed` to today. The next decay check happens in another 180 days.

**On "Reopen":** Set status back to `open`, append history entry `action: reopened_from_decay, by: user`.

**On "Change to deferred":** Set status to `deferred`, add `deferred` block with a new `review_by` date.

### Custom Decay Periods

When accepting a finding, the user can specify a custom decay period:

```
Accept risk with custom review period? [180 days (default) / 90 days / 365 days / Never]
```

"Never" sets `decay_after_days: null` -- the finding will never resurface automatically. Use sparingly.

---

## Partial Re-Audit (v3.0)

`/radar-suite audit --changed` scopes the audit to files that changed since the last session:

### How It Works

1. Read the ledger to find the most recent session timestamp
2. Run `git diff --name-only` against that timestamp to find changed files
3. Filter to files that either:
   - Have existing findings in the ledger, OR
   - Are new files not previously audited
4. Run only the skills relevant to those file types:
   - `.swift` model files (in Models/) → data-model-radar, time-bomb-radar
   - `.swift` view files (in Views/) → ui-path-radar, ui-enhancer-radar
   - Any file with existing roundtrip findings → roundtrip-radar
5. Skip capstone unless new findings are discovered

### Command Variants

```
/radar-suite audit --changed                    # since last audit session
/radar-suite audit --changed --since 2026-04-01 # since specific date
```

### Expected Time

Partial audit: 15-30 minutes (vs 2.5-4 hours for full audit).

### Output

```
═══════════════════════════════════════════════
  PARTIAL AUDIT — [N] files changed since [date]
  Skills to run: [list]
  Estimated time: ~[N] minutes
═══════════════════════════════════════════════

Changed files with existing findings:
  Sources/Managers/CSVManager.swift — RS-001 [fixed], RS-007 [open]
  Sources/Views/SettingsView.swift — RS-019 [accepted]

New files (no prior audit):
  Sources/Views/NewFeatureView.swift

Proceed? [Yes / Full audit instead / Skip]
```

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
