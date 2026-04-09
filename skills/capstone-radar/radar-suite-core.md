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

### Experience-Level Output Rules

After storing `USER_EXPERIENCE`, apply these rules to ALL output for the session:

| Output Element | Beginner | Intermediate | Experienced | Senior/Expert |
|---|---|---|---|---|
| Skill intro | Full paragraph with analogy | 2-3 sentences | One line | Skip entirely |
| `--explain` | Auto-enabled | Off (suggest in banner) | Off | Off |
| Progress banner | Full with hint lines | Full with hint lines | Compact (no hint lines) | One-line status only |
| Finding text | Plain language + "why it matters" | Standard terminology | file:line + description | file:line only |
| Sort default | `--sort impact` | `--sort urgency` | `--sort urgency` | `--sort effort` |
| Design citations | Always cite principle | On non-obvious findings only | Never | Never |
| AskUserQuestion | Always include "Explain more" | Include "Explain more" | Standard options | Minimal options |
| Post-fix summary | Full before/after comparison | Brief summary | Skip | Skip |

**Auto-applied on setup:**
- If `USER_EXPERIENCE` = Beginner: set `EXPLAIN_FINDINGS = true` automatically
- If `USER_EXPERIENCE` = Senior/Expert: set default sort to `effort` (they know what matters, they want to knock things out fast)
- If `USER_EXPERIENCE` = Beginner: set default sort to `impact` (most user-visible first helps them understand what matters)

**Progress banner adaptation:**
- Beginner/Intermediate: Full 6-line banner with `--explain` and `--sort` hint lines
- Experienced: 4-line banner (drop hint lines)
- Senior/Expert: Single line: `[SKILL] Phase [N] — [N] findings, [N] fixed, [N] remaining`

**Finding text adaptation:**
- Beginner: "The backup file doesn't include the Room field, so restoring a backup loses where items are stored"
- Intermediate: "Room field missing from backup serialization"
- Experienced: `BackupManager.swift:142` — Room not serialized in backup
- Senior/Expert: `BackupManager.swift:142` — Room missing

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

## Known-Intentional Suppression

Distinct from accepted risks. Accepted risks are "this IS a bug, but I accept it." Known-intentional entries are "this is NOT a bug -- the auditor flagged a pattern that is intentionally correct here."

### Schema

File: `.radar-suite/known-intentional.yaml`

```yaml
entries:
  - id: KI-001
    file: Sources/Features/ClaimPrepKit/ClaimPrepExporter.swift  # glob pattern OK
    pattern: "NSFileCoordinator"  # regex matched against finding description or code
    reason: "Writes to temp directory, not iCloud container. File coordination unnecessary."
    added_by: human  # or skill-name if auto-suggested
    added_date: 2026-04-08
    skill: roundtrip-radar  # which skill flagged the false positive
    review_after: null  # optional YYYY-MM-DD for time-limited suppressions
```

### Matching Rules

1. **File match:** Entry `file` is matched as a glob against the finding's `file` field. Exact path or `**/FileName.swift` both work.
2. **Pattern match:** Entry `pattern` is matched as a regex against the finding's `description` field AND the code evidence in the work receipt. Match on either = suppressed.
3. **Both must match.** A file-only or pattern-only match is not sufficient.

### Behavior

1. **On audit startup:** Read `.radar-suite/known-intentional.yaml` (if exists). Store as `KNOWN_INTENTIONAL`.
2. **Before presenting each finding:** Check against `KNOWN_INTENTIONAL`. If file + pattern match:
   - Skip the finding silently (do not present to user)
   - Increment `intentional_suppressed` counter
3. **Expired entries:** If `review_after` is set and today > `review_after`, the entry is ignored (finding is presented normally) with note: "Previously suppressed -- review_after date passed."
4. **Handoff:** Include `intentional_suppressed: N` in handoff YAML metadata so capstone knows findings were filtered.
5. **Report footer:**
   ```
   Suppressed: N known-intentional entries (--show-suppressed to review)
   ```

### Commands

- `--show-suppressed` — List all findings that were suppressed by known-intentional entries this session
- `--accept-intentional` — When viewing a specific finding, mark it as known-intentional (prompts for reason, writes entry to YAML)
- Orphaned entry detection is handled by `/radar-suite verify` (see radar-suite router skill)

### Interaction with Regression Detection

- Suppression is pattern-based, not hash-based. If a suppressed file changes, the suppression still applies as long as the pattern matches.
- If the file is deleted, the entry becomes orphaned. `/radar-suite verify` flags orphaned entries for cleanup.

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
  Sort: [current] · --sort effort|impact|implement
  --explain to add user impact explanations
═══════════════════════════════════════════════
```

The last two lines are hints. Omit the `--explain` hint line if `EXPLAIN_FINDINGS` is already true. Omit the sort hint if the user has already changed sort mode this session (they know it exists).

Always follow with `AskUserQuestion`. Never leave blank prompt.

---

## Issue Rating Table Format

**8 columns required (no exceptions):**

| #   | Finding              | Urgency      | Risk:Fix | Risk:NoFix | ROI      | Blast    | Effort |
|-----|----------------------|--------------|----------|------------|----------|----------|--------|

> **Terminal width:** If the table renders as vertical blocks instead of horizontal rows, tell the user: "The rating table needs a wider terminal to display correctly. Try widening your window or using full-screen mode." Do NOT switch to a vertical/list format -- always render as a table.

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

**Default sort:** Urgency descending, then ROI descending.

**Sort modes** (toggle mid-session with `--sort <mode>`):
- `--sort urgency` (default) — most broken first
- `--sort effort` — easiest safe wins first (Fix Effort ↑, Risk:Fix ↑)
- `--sort impact` — most user-visible first (Risk:No Fix ↓, Urgency ↓)
- `--sort implement` — dependency-aware ordering for sprint planning

Sort can be changed without re-running the audit. Note the available modes in the end-of-audit suggestion.

### Implementation Sort Algorithm (`--sort implement`)

When `--sort implement` is active, findings are ordered by dependency topology rather than urgency alone:

1. **Build dependency graph:** Scan all findings for `depends_on` and `enables` fields. Each creates a directed edge in a DAG.
2. **Topological sort:** Order findings so that dependencies come before dependents. Within a topological level, break ties by urgency (descending).
3. **Cycle detection:** If the graph has cycles, warn the user ("Cycle detected: RS-014 → RS-016 → RS-014 — falling back to urgency sort for these items") and fall back to urgency sort for the cycle members only. Non-cycle findings remain topologically sorted.
4. **Output:** Print dependency chains alongside findings:
   ```
   Fix RS-014 first (enables RS-015, RS-016)
   ```

**Within individual skills:** Populate `depends_on`/`enables` for findings where the relationship is obvious:
- "Add Codable conformance" enables "Serialize to JSON backup"
- "Add VersionedSchema" enables "Create migration plan"
- Structural changes (model, protocol) enable behavioral changes (UI, export)

**Cross-skill dependencies** are inferred by capstone-radar using auto-inference rules (see capstone-radar Step 6.5).

### User Impact Explanations

When `EXPLAIN_FINDINGS` is true (toggled via `--explain` / `--no-explain`), append a numbered explanation for each finding after the Issue Rating Table. Each explanation has exactly 3 lines:

```markdown
### #1 -- [Finding title from table]
**What's wrong:** [One sentence describing the bug or gap.]
**Fix:** [One sentence describing the concrete change.]
**User experience:** [One sentence: what the user sees before, and what changes after.]
```

Rules:
- One sentence per line -- not two, not a paragraph.
- "User experience" means the person using the app, not the developer.
- For code-only findings (⚪ LOW), use "Developer experience" instead.
- Order matches the table. Place after the table, before the next-step suggestion.
- Default is off. The table is the primary output; explanations are supplementary.

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
    depends_on: []  # IDs that must be fixed before this one (optional, best-effort)
    enables: []     # IDs that this fix unblocks (optional, best-effort)
    pattern_fingerprint: [normalized anti-pattern name, e.g. "try?_swallow"]
    grep_pattern: [regex to detect this pattern in code]
    exclusion_pattern: [regex — if present near grep_pattern, not a violation]
    fix_applied: [description of fix if status=fixed]
    test_added: [test file path if applicable]

# Session metadata
context_exhaustion_after: [N or null]
tool_calls: [count]
duration_minutes: [number]
accepted_risks_suppressed: [count]
intentional_suppressed: [count]  # known-intentional entries that filtered findings
```

**Cross-skill handoff rules:**
1. data-model-radar → roundtrip-radar: Pass `suspects` for serialization gaps
2. roundtrip-radar → capstone-radar: Pass workflow-level findings
3. ui-path-radar → ui-enhancer-radar: Pass dead-end views for visual audit
4. All → capstone-radar: Pass `overall_grade` for aggregation

---

## Pattern Reintroduction Detection

A fixed bug can reappear in a *different* file. Regression detection (file hash changes) catches re-breaks in the same file. Pattern fingerprints catch the same anti-pattern introduced elsewhere.

### How It Works

1. **On fix:** When a finding is marked `status: fixed` in the ledger, store its `pattern_fingerprint` and `grep_pattern` alongside the fix record.
2. **On audit startup:** Read the ledger for all `status: fixed` findings that have a `pattern_fingerprint`. For each:
   - Run `grep_pattern` against the entire codebase (excluding test files, build artifacts)
   - For each match, check if `exclusion_pattern` appears within 5 lines of context
   - If `grep_pattern` matches AND `exclusion_pattern` is absent → **reintroduced pattern**
3. **Reporting:** Reintroduced patterns are reported as new findings with:
   - Default urgency: 🟡 HIGH (a fixed bug coming back is worse than a new bug)
   - Description prefix: "Reintroduced pattern:"
   - Reference to the original fixed finding ID
4. **Deduplication:** If the match is in the same file as the original finding and the file hash matches the fix hash, skip it (this is a regression, not a reintroduction -- handled by regression detection).

### Built-In Pattern Categories

All skills check these 5 patterns on startup, regardless of whether they were previously found:

| Fingerprint | Grep Pattern | Exclusion Pattern | What It Catches |
|---|---|---|---|
| `try?_swallow` | `try\?` | `do \{.*\} catch` within 5 lines | Silent error swallowing |
| `force_unwrap_production` | `[^/]!\\.` or `as!` | File path contains `Tests/` or `Preview` | Force unwraps outside tests |
| `todo_in_production` | `// TODO\|// FIXME\|// HACK\|// XXX` | none | Unresolved markers |
| `shared_mutable_static` | `static var ` | `let \|nonisolated\|Mutex\|Lock\|actor ` in same type | Unprotected shared mutable state |
| `missing_file_protection` | `\.write\(to:` | `\.completeFileProtection\|\.protectedUntilFirstUserAuthentication` within 10 lines | File writes without protection |

**Rules:**
- Built-in patterns are checked in addition to project-specific fingerprints from the ledger
- They use the same reporting format as reintroduced patterns
- They do NOT require a previous finding to exist -- they are always-on baseline checks
- If a built-in pattern match is in `known-intentional.yaml`, it is suppressed normally

### Populating Fingerprints

When creating a finding, assign a `pattern_fingerprint` if the anti-pattern is generalizable:
- Use a short, descriptive name (e.g., `try?_context_save_no_catch`, `missing_backup_field`)
- Populate `grep_pattern` with a regex that would find this pattern in any file
- Populate `exclusion_pattern` with a regex for the correct version of the pattern (what makes it NOT a violation)
- If the finding is too specific to generalize (e.g., a one-off logic error), leave fingerprint fields empty

---

## Completion Prompt Pattern

```
I found [X] issues:
- [N] critical (brief description)
- [N] high / [N] medium / [N] low
[If intentional_suppressed > 0:] (N known-intentional entries suppressed — --show-suppressed to review)

You can:
1. **Fix critical issues now** (~[time]) — [description]
2. **Fix quick wins only** (~[time]) — [description]
3. **Keep auditing other areas** — [description of next area]
4. **Explain more** — walk through what each issue means
```
