---
name: roundtrip-radar
description: 'Per-journey code audit tracing data through complete user flows for bugs, data safety, performance, and round-trip completeness. Discovers workflows, audits each end-to-end, rolls up cross-cutting issues, and supports natural-language flow tracing. Triggers: "roundtrip audit", "trace user journey", "/roundtrip-radar".'
version: 1.4.0
author: Terry Nyberg
license: MIT
inherits: radar-suite-core.md
---

# Roundtrip Radar

This skill audits application workflows for bugs, data-safety issues, performance
problems, and data round-trip completeness. It operates in three steps:

- **Step 0** — Discover all workflows (run once, or when workflows change)
- **Step 1** — Deep audit one workflow at a time (one prompt per workflow)
- **Step 2** — Roll-up cross-cutting patterns across all audited workflows

## Usage

| Command | Description |
|---------|-------------|
| `/roundtrip-radar` | Start with Step 0 (discover), then prompt for Step 1 |
| `/roundtrip-radar discover` | Run Step 0 only — find all workflows |
| `/roundtrip-radar [WORKFLOW]` | Run Step 1 for a specific workflow |
| `/roundtrip-radar rollup` | Run Step 2 — cross-cutting analysis |
| `/roundtrip-radar trace "A → B → C"` | Trace a specific user flow path (see below) |
| `/roundtrip-radar diff` | Compare findings against previous audit |

---

## Trace Command

**Targeted flow tracing** — trace a specific user journey described in natural language.

### Usage

```
/roundtrip-radar trace "Dashboard → Add Item → Photo → Save"
/roundtrip-radar trace "Settings, Export, CSV, Email"
```

### How It Works

1. **Parse the path** — Split on `→`, `->`, or `,` into discrete steps
2. **Identify code locations** — For each step, search for:
   - View names matching the step
   - Sheet triggers, navigation actions
   - Button labels, action handlers
3. **Trace step by step** — For each transition:
   - File and line number
   - State changes (sheet presentations, navigation, @State mutations)
   - Data transformations (what model fields are read/written)
4. **Check for issues at each step:**
   - Is data preserved between steps? (Round-trip completeness)
   - Are there error paths that lose context? (Error handling)
   - Is the user's intent preserved? (Data safety)
   - Are there race conditions? (Concurrency)
5. **Output** — Issue Rating Table for findings + step-by-step trace with receipts

### Output Format

```
Trace: Dashboard → Add Item → Photo → Save

| Step | Action | File | Lines | Data In | Data Out | Finding |
|------|--------|------|-------|---------|----------|---------|
| 1 | Dashboard tap "Add" | DashboardView.swift | 142-145 | — | activeSheet = .addItem | ok |
| 2 | Add Item sheet presents | AddItemView.swift | 1-50 | Item.draft | item.title, item.category | ok |
| 3 | Photo picker | PhotoPicker.swift | 23-89 | item.id | PhotoAttachment | ⚠️ orientation lost |
| 4 | Save item | ItemViewModel.swift | 112-134 | item + attachments | modelContext.save() | ok |

Issues Found:
| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
```

### When to Use

- **Debugging a specific user report** — "When I add a photo and save, the orientation is wrong"
- **Verifying a fix** — Trace the exact path to confirm data flows correctly
- **Pre-release spot check** — Trace critical paths without a full audit

---

## Skill Introduction (MANDATORY — run before anything else)

On first invocation, ask the user two questions in a single `AskUserQuestion` call:

**Question 1: "What's your experience level with Swift/SwiftUI?"**
- **Beginner** — New to Swift. Plain language, analogies, define terms on first use.
- **Intermediate** — Comfortable with SwiftUI basics. Standard terms, explain non-obvious patterns.
- **Experienced (Recommended)** — Fluent with SwiftUI. Concise findings, no definitions.
- **Senior/Expert** — Deep expertise. Terse, file:line only, skip explanations.

**Question 2: "Would you like a brief explanation of what this skill does?"**
- **No, let's go (Recommended)** — Skip explanation, proceed to audit.
- **Yes, explain it** — Show a 3-5 sentence explanation adapted to the user's experience level (see below), then proceed.

**Experience-adapted explanations for Roundtrip Radar:**

- **Beginner**: "Roundtrip Radar follows your data through complete user journeys — like tracking a package from warehouse to doorstep and back. For example, it checks: if you create an item, back it up, delete it, and restore — does everything come back exactly? It finds bugs where data gets lost, corrupted, or silently dropped along the way. It audits one workflow at a time (backup, add item, sync, etc.) so nothing gets missed."

- **Intermediate**: "Roundtrip Radar audits individual workflows end-to-end for data safety, error handling, concurrency, and round-trip completeness. It traces data through create → modify → export → import cycles, checks transaction boundaries, verifies error recovery paths, and identifies where data is silently lost. Works one workflow at a time to stay thorough."

- **Experienced**: "Per-workflow code audit: data safety, error handling, concurrency, performance, contract mismatches, and round-trip completeness. Discovers workflows, audits each with issue rating tables and fix plans, then rolls up cross-cutting patterns."

- **Senior/Expert**: "Workflow-scoped audit: data safety + error paths + concurrency + round-trip completeness. Rating tables + fix plans + cross-workflow rollup."

Store the experience level as `USER_EXPERIENCE` and apply to ALL output for the session.

**Subsequent workflows:** Do NOT re-ask the full setup questions. Instead, show a one-line reminder before each workflow:
```
Using: [Beginner] mode, [Auto-fix small issues], [Display only]. Type "adjust" to change, or press Enter to continue.
```
If the user types "adjust", re-ask only the question(s) they want to change. Users may want to adjust experience level after a few workflows (beginner explanations may feel too simple, expert too terse).

---

## Shared Patterns

See `radar-suite-core.md` for: Table Format, Plain Language Communication, Work Receipts, Contradiction Detection, Finding Classification, Audit Methodology, Context Exhaustion, Progress Banner, Issue Rating Tables, Handoff YAML schema.

---

## Step 0: Workflow Discovery

Run first if workflows are unknown or have changed.

Scan the codebase and identify all user-facing workflows.

### What Counts as a Workflow

A workflow is a multi-step user action that:
- Spans 2+ screens or states (not a single tap)
- Involves data creation, modification, deletion, or transfer
- Has a distinct entry point and completion state

### How to Find Them

1. Search for navigation entry points:
   - `.sheet`, `.fullScreenCover`, `.navigationDestination`
   - `NavigationLink`, `TabView` tabs
   - Button actions that trigger multi-step flows
2. Search for data operations:
   - `modelContext.insert`, `modelContext.delete`, `context.save`
   - Import/export, backup/restore, sync operations
   - API calls, file I/O
3. Search for state machines:
   - Enums with cases like `.idle`, `.processing`, `.complete`
   - Multi-step `@State` progressions
   - `isProcessing`, `isImporting`, `isSaving` patterns

### Output

List each workflow with:

| # | Workflow | Entry Point | Key Files | Complexity | Data Risk |
|---|----------|-------------|-----------|------------|-----------|
| 1 | [Name] | [Where user starts it] | [2-4 main files] | Low/Med/High | None/Read/Write/Delete |

### Complexity Criteria

- **Low** — 1-2 files, linear flow, no branching
- **Medium** — 3-4 files, some branching, error handling
- **High** — 5+ files, async operations, multiple outcomes, data transformation

### Data Risk Criteria

- **None** — Display only
- **Read** — Fetches but doesn't modify
- **Write** — Creates or updates data
- **Delete** — Removes data or replaces state

### Priority Recommendation

After listing all workflows, recommend which to audit first based on:
- High complexity + Write/Delete data risk = audit first
- Medium complexity + Write risk = audit second
- Everything else = audit if time permits

Do NOT write a report file. Output the table directly.

---

## Step 1: Per-Workflow Audit

**One workflow per prompt.** Run as a separate agent or conversation per workflow
to prevent context exhaustion.

Audit the **[WORKFLOW NAME]** workflow for bugs, data-safety issues,
performance problems, and data round-trip completeness.

### Before Starting (First Workflow Only)

Ask the user these questions **once per session** in a single prompt. For subsequent workflows, show the one-line reminder from Skill Introduction and skip to the audit.

**Question 1: "What's your experience level with Swift/SwiftUI?"**
- **Beginner** — New to Swift. Plain language, analogies, define terms on first use.
- **Intermediate** — Comfortable with SwiftUI basics. Standard terms, explain non-obvious patterns.
- **Experienced (Recommended)** — Fluent with SwiftUI. Concise findings, no definitions.
- **Senior/Expert** — Deep expertise. Terse, file:line only, skip explanations.

**Question 2: "How should fixes be handled?"**
- **Auto-fix safe items (Recommended)** — Apply isolated, low-blast-radius fixes automatically. Present cross-cutting fixes and design decisions for approval first.
- **Review first** — Present all findings with ratings, then ask before making any changes. Fixes still happen — you just approve each wave first.

**IMPORTANT:** Both modes lead to fixes. "Review first" means the user sees the plan before code changes — it does NOT mean "skip fixes and jump to handoff." After presenting findings, ALWAYS offer to fix them regardless of which mode was selected.

**Question 3: "How should results be delivered?"**
- **Display only (Recommended)** — Show findings in the conversation. No file written.
- **Report only** — Write findings to `.agents/research/[DATE]-[WORKFLOW]-audit.md`.
  Minimal conversation output.
- **Display and report** — Show findings in the conversation AND write to file.

**Question 4: "Will you be stepping away during the audit?"**
- **I'll be here (Recommended)** — Normal mode. Permission prompts may appear for writes/edits.
- **Run the full analysis without stopping to ask — no code changes** — Restricts to read-only tools (Read, Grep, Glob) for discovery and audit steps. No Bash, no Edit, no Write — nothing that triggers a permission prompt. Fix application is deferred until you return. Results are held in conversation output.
- **Pre-approved** — You have already configured Claude Code permissions for this session (see Permission Setup below). Run at full speed without restriction.

### Permission Modes

#### Normal Mode
- Read any file without asking.
- Edit files listed in "Files to Read" and their corresponding test files freely.
- For files outside that list, edit only if directly required by a P0-P1 fix.
  Note which external files were changed in your output.
- Build and run tests without asking.
- If a fix breaks the build, restore the original code and document the
  finding as "Documented" instead of "Fixed".

#### Hands-Free Mode
**Guarantees no blocking prompts.** The skill will ONLY use these tools:
- `Read` — read file contents
- `Grep` — search file contents
- `Glob` — find files by pattern

It will NOT use:
- `Bash` — no shell commands (grep via Grep tool instead)
- `Edit` / `Write` — no file modifications
- `AskUserQuestion` — no interactive prompts

When the audit completes (or hits a step that needs restricted tools), it prints:
```
⏱ Hands-free audit complete through Step [N].
  Steps requiring action: [list]
  Reply to continue with supervised steps.
```

#### Pre-Approved Mode
Full speed, no restrictions. Assumes you've set up permissions. See below.

### Permission Setup (for unattended runs)

To avoid permission prompts during audits, pre-allow these read-only patterns in your Claude Code settings. These are **safe to auto-approve** — they cannot modify your codebase:

```
# Already safe by default (no setup needed):
Read, Grep, Glob — always auto-approved

# Add these for unattended Bash scans:
Bash(find:*)
Bash(wc:*)
Bash(stat:*)
```

**Do NOT auto-approve** (keep these prompted — they modify state):
```
Edit, Write — file modifications
Bash(rm:*), Bash(git:*) — destructive operations
```

> **Tip:** Hands-free mode can complete workflow discovery (Step 0) and the full per-workflow audit (Step 1) read-only. Only fix application needs write access.

### Freshness

Base all findings on current source code only. Do not read or reference
files in `.agents/`, `scratch/`, or prior audit reports. Ignore cached
findings from auto-memory or previous sessions. Every finding must come
from scanning the actual codebase as it exists now.

### Context Budget

If context is running low, prioritize in this order:
1. Finish verifying Suspects
2. Complete any in-progress fixes
3. Emit the Fix Plan for what you've found so far
4. Skip remaining exploratory checks

Never start a new check you can't finish.

### Experience-Level Adaptation

Adjust ALL output based on the user's experience level:

- **Beginner**: Plain language, real-world analogies, define terms on first use ("a model context — the database connection SwiftUI uses to save data"). Explain why each finding matters. Use compact 4-column tables with prose explanations below.
- **Intermediate**: Standard SwiftUI terminology without defining basics, but explain non-obvious patterns (e.g., why a `Task.sleep` workaround indicates a broken refresh path). Full 8-column tables with brief descriptions.
- **Experienced** (default): Concise findings, no definitions. "Missing `modelContext.save()` after batch delete in `BulkEditViewModel.swift:142`". Full tables, terse text.
- **Senior/Expert**: Minimal prose. File:line + one-line description only. Findings table IS the output. Skip design principle citations and category explanations.

### Fix Threshold

- **Fix:** Data loss, data corruption, crashes, infinite loops, broken user flows (P0-P1)
- **Document only:** Performance, UI polish, code style, missing features (P2+)
- **Defer with explanation:** P0-P1 issues that require multi-file migration,
  schema changes, or affect core models used outside this workflow.
  Mark as "P1 - Deferred (reason)" in the table.

### Suspects (verify these first, then explore beyond)

[One per line. Include file name, approximate line, and the specific question to answer.]

Example:
- `BackupDataSheet.swift ~line 351`: `decryptAndRestore(replaceExisting: false)`
  — is the user's replace choice preserved through the password prompt?

[If no suspects: "No prior suspects — full exploratory audit."]

### Recent Changes (verify these are correct)

[One per line. Include file, what changed, and what to verify.]

Example:
- `CloudSyncManager.swift`: Added `maxRetries=3` retry limit
  — verify counter resets on all terminal paths (success, non-retryable errors)

[If none: "None"]

### Files to Read

- **Must read:** [2-4 files central to this workflow]
- **Read if relevant:** [1-2 supporting files, with the condition that makes them relevant]
- **Skip:** [files that look related but are low-value]
- **Tests:** Find by searching `Tests/` for `[WORKFLOW_KEYWORD]`

### What to Check

1. **Data safety** `enumerate-required` — destructive operations, transaction boundaries, edge cases
2. **Error handling** `mixed` — missing catches, silent failures, user-facing error messages
3. **Concurrency** `mixed` — `@MainActor` compliance, Task isolation, ModelContext thread safety
4. **Performance** `grep-sufficient` — `@Query` without predicates, O(n²) loops, main-thread blocking
5. **Contract mismatches** `grep-sufficient` — constants vs hardcoded strings, keys defined in one file but consumed in another
6. **Round-trip completeness** `enumerate-required` — does data survive a full create → export → import/restore cycle?
7. **Interruption paths** `enumerate-required` — dismiss mid-operation, app backgrounding, rotation, cancel
8. **Tests** `enumerate-required` — update broken tests, add tests for P0-P1 fixes where logic is testable

### Verification Template (MANDATORY per workflow)

Before grading a workflow, produce this table showing what was actually traced:

```
| Step | Action | File Read | Lines | Receipt | Finding |
|------|--------|-----------|-------|---------|---------|
| 1. Create | [what happens] | [file:line] | [range] | [evidence] | [ok / issue] |
| 2. Save | [what happens] | [file:line] | [range] | [evidence] | [ok / issue] |
| 3. Export | [what happens] | [file:line] | [range] | [evidence] | [ok / issue] |
| 4. Import | [what happens] | [file:line] | [range] | [evidence] | [ok / issue] |
```

Rules:
- Every step in the workflow must have a File Read entry
- Steps without a file read cannot produce findings tagged "verified"
- The table IS the audit — the findings are just a summary of what the table reveals

### Issue Rating Criteria

For every finding, use this table format sorted by Urgency (descending), then ROI:

| # | Finding | Confidence | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort | Status |
|---|---------|------------|---------|-----------|--------------|-----|--------------|------------|--------|

#### Column Definitions

| Column | Meaning |
|--------|---------|
| Confidence | `verified` (code read + confirmed), `probable` (agent reported, not independently verified), `needs-runtime` (requires running the app to confirm) |
| Urgency | How time-sensitive — must it be fixed before release? |
| Risk: Fix | What could break when making the change |
| Risk: No Fix | Cost of leaving it — crash, data loss, user-visible bug |
| ROI | Return on effort (inverted — 🟠 = excellent, 🔴 = poor) |
| Blast Radius | Number of files the fix touches (e.g., `🟢 3 files`, `⚪ 1 file`). Do not use `<br>` tags. Count by grepping for callers/references before rating. |
| Fix Effort | Trivial / Small / Medium / Large |
| Status | Fixed / Documented / Deferred (reason) |

#### Indicator Scale

| Indicator | General meaning | ROI meaning |
|-----------|----------------|-------------|
| 🔴 | Critical / high concern | Poor return — reconsider |
| 🟡 | High / notable | Marginal return |
| 🟢 | Medium / moderate | Good return |
| ⚪ | Low / negligible | — |
| 🟠 | Pass / positive | Excellent return |

#### Urgency Scale

- 🔴 CRITICAL — pre-launch blocker OR data loss / crash risk
- 🟡 HIGH — user-visible or stability risk; fix before release
- 🟢 MEDIUM — real issue; acceptable to schedule
- ⚪ LOW — nice-to-have; minimal impact

Do not use prose for ratings. Every finding gets a row in this table.

### Output

#### Fix Plan

After all findings, generate a Fix Plan grouped into these sections:

**1. Safe fixes (contained, only touching one or two files)**
Changes contained within the audited files. No behavioral changes outside the workflow.

| # | Finding | Files Changed | Urgency | ROI | Fix Effort |
|---|---------|---------------|---------|-----|------------|

**2. Cross-cutting fixes (touch shared code)**
Changes that affect models, protocols, or utilities used by other features.
Review for unintended side effects before approving.

| # | Finding | Files Changed | Urgency | ROI | Fix Effort | Side Effects |
|---|---------|---------------|---------|-----|------------|--------------|

**3. Requires design decision**
Multiple valid approaches. Needs user input before proceeding.

| # | Finding | Options | Urgency |
|---|---------|---------|---------|

**4. Deferred (no action needed now)**
Documented for future reference. No plan step generated.

| # | Finding | Urgency | Why Deferred |
|---|---------|---------|--------------|

**5. Shared utility extraction**
When multiple code paths duplicate the same logic, extract to a shared utility.

| # | Finding | Proposed Utility | Files Affected |
|---|---------|------------------|----------------|

**6. Out of scope**
Issues discovered here that belong to a different workflow.
List them with the affected workflow name so they can be fed into that workflow's audit.

| # | Finding | Affected Workflow | Urgency |
|---|---------|-------------------|---------|

#### Verification (auto-fix mode only)

After applying Safe fixes:
1. Build the project — if it fails, revert and move the fix to Cross-Cutting
2. Run tests touching modified files — if any fail, fix the test or revert the code fix
3. Report pass/fail counts in the Fix Plan output

#### Then

- If user chose **Auto-fix safe items**: apply Section 1 fixes, run Verification,
  then present Sections 2-3 for approval.
- If user chose **Review first**: present all sections for approval,
  then ask if the user wants to proceed with fixes.

#### Delivery

- If user chose **Display only**: output all tables in the conversation.
- If user chose **Report only**: write all tables to
  `.agents/research/[DATE]-[WORKFLOW]-audit.md`. Show only a one-line summary
  in the conversation (e.g., "Audit complete: 3 critical, 5 high, 2 medium.
  Report written to .agents/research/2026-03-06-backup-audit.md").
- If user chose **Display and report**: output all tables in the conversation
  AND write to file.

#### Deferred Items Registry

After each workflow audit, append deferred findings to `.agents/research/roundtrip-radar-deferred.md`. This accumulates across workflows so Step 2 rollup can consume them without re-reading all audit output.

Format:
```markdown
## [Workflow Name] — [Date]
| # | Finding | Urgency | Why Deferred |
|---|---------|---------|--------------|
| 1 | ... | 🟡 HIGH | Needs design decision |
```

---

## Fix Application Workflow

After presenting the Fix Plan, apply fixes in **waves**. Each wave is a phase from the Fix Plan. After each wave (including commits), **always** print the progress banner and auto-prompt for the next wave.

### Waves

| Wave | Fix Plan Section | Est. Time | Description |
|------|-----------------|-----------|-------------|
| 1 — Quick fixes | Safe fixes + tests | ~10-15 min | Small, contained fixes (one or two files each). Applied automatically. Tests written for each fix. |
| 2 — Shared code fixes | Cross-cutting fixes + tests | ~15-25 min | Fixes that touch code used by other features. Presented for your review first. Tests written for each fix. |
| 3 — Your call | Design decisions | ~5-15 min | Multiple valid approaches. You pick the direction for each item. |
| 4 — Same bug elsewhere | Pattern Sweep | ~5 min | Search the whole codebase for the same bugs found in this workflow. |
| 5 — Wrap up | Build + Test + Commit | ~5 min | Build both platforms, run tests, stage, commit. |

**Every fix must have a test.** Do not move to the next wave until tests for the current wave's fixes are written and compiling. The test verifies the fix works; without it, the fix is unverified code.

Skip empty waves (e.g., if no design decisions, go straight from Wave 2 to Wave 4).

If a "cross-cutting fix" turns out to need a design decision during implementation, reclassify it — ask the user via `AskUserQuestion` with the options, don't proceed without input.

### Wave 4: Pattern Sweep (after fixes, before commit)

After fixing findings in a workflow, scan the entire codebase for the same anti-pattern. This catches all instances at once instead of rediscovering them workflow-by-workflow.

For each pattern found and fixed in this workflow:
1. Build a grep query (e.g., `Double(` for raw price parsing, `hashValue` for unstable IDs)
2. Search all Sources/ files
3. Report: "Pattern X found in N additional files: [list]"
4. If fixes are trivial and isolated, apply them now. Otherwise, note for the next workflow.

### Progress Banner (CRITICAL — BLOCKING requirement)

**This is a BLOCKING requirement.** After EVERY wave and EVERY commit, your NEXT output MUST be the progress banner followed by the next-wave `AskUserQuestion`. Do not output anything else first. Do not wait for user input. Do not leave a blank prompt.

After completing each wave, **always** print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Fix batch [N] of [total] complete: [plain description]
   [X] findings fixed, [Y] remaining, [Z] deferred

⏱  Next: Batch [N+1] — [plain description] (~[time estimate])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then immediately ask: "Ready for the next batch?" with options:
- **Proceed (Recommended)** — Start the next batch of fixes
- **Commit first** — Commit current changes before continuing
- **Stop here** — End for now, resume later
- **Explain more** — Describe what the next batch will do before starting

### Between Workflows (MANDATORY transition)

After committing all fixes for a workflow, follow this exact sequence:

1. Print the **Workflow-Level Scorecard**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Roundtrip Radar Progress
   Workflows: [N]/[total] | Fixed: [X] | Deferred: [Y] | Patterns: [Z]
   Last: [workflow name] ([N] fixed)
   Next: [workflow name] (~[time estimate])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

2. Immediately ask: "Ready for the next workflow?" with options:
   - **Proceed (Recommended)** — Audit the next highest-priority workflow
   - **Stop here** — End session, save progress to memory
   - **Final rollup (Step 2)** — Cross-cutting analysis across all audited workflows

3. If user proceeds, show the one-line settings reminder (see Skill Introduction) then start the audit. Do NOT re-ask the 4 setup questions.

**Never leave the user with a blank prompt between workflows.**

---

## Step 2: Roll-Up

Run after all per-workflow audits are complete.

Review the findings from the individual workflow audits below and identify
cross-cutting patterns.

[Paste the finding tables from each workflow audit here, or reference the
report files if they were written.]

### Output

1. List any pattern that appears in 2+ workflows (e.g., `@Query` without predicates, hash-based IDs)
2. For each pattern, state which workflows are affected and whether a shared fix exists
3. Rank the top 5 remaining deferred items by impact using the Issue Rating table format

Deliver results according to the user's output preference from Step 1.

---

## Cross-Skill Handoff

Roundtrip Radar complements **data-model-radar** (model layer), **ui-path-radar** (navigation paths), **ui-enhancer-radar** (visual quality), and **capstone-radar** (ship readiness). Findings from one skill inform the others.

### On Completion — Write Handoff

After completing a workflow audit (or Step 2 rollup), write/update `.agents/ui-audit/roundtrip-radar-handoff.yaml`:

```yaml
source: roundtrip-radar
date: <ISO 8601>
project: <project name>
workflows_audited: <count>

# File timestamps — enables staleness detection by consuming skills
# If a file changed after the audit, affected issues may need re-verification
file_timestamps:
  <file path>: "<ISO 8601 mod date>"
  # one entry per unique file referenced in issues

for_ui_path_radar:
  # Data issues that may have navigation/entry-point implications
  suspects:
    - entry_point: "<button/link that triggers this workflow>"
      finding: "<data safety issue found>"
      file: "<file:line>"
      question: "<does the UI reflect this data issue?>"
      group_hint: "<optional, e.g. 'data_loss', 'silent_failure'>"

for_ui_enhancer_radar:
  # Dead code, orphaned UI, or views with broken data backing
  suspects:
    - view: "<view file>"
      finding: "<data issue that affects this view>"
      action: "verify data binding or remove dead UI"
      group_hint: "<optional batching suggestion>"

for_capstone_radar:
  # Critical/high findings that affect ship readiness
  blockers:
    - finding: "<description>"
      urgency: "<CRITICAL|HIGH>"
      workflow: "<workflow name>"
      group_hint: "<optional batching suggestion>"

cross_cutting_patterns:
  # Patterns found across multiple workflows — useful for all skills
  - pattern: "<e.g., Double() price parsing>"
    workflows_affected: ["Backup", "Edit Item", "CSV Import"]
    status: "fixed" | "deferred"
    group_hint: "<optional, e.g. 'price_parsing', 'id_handling'>"
```

### File Timestamps

For each unique file path referenced across all issues, record its modification date at audit time:

```bash
# Get file mod date (macOS)
stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "<file path>"
```

This enables consuming skills to detect **staleness** — if a file changed after the audit, affected issues may need re-verification before acting on them.

### Group Hints

Optional field suggesting how consuming skills might batch related issues:
- Issues with the same `group_hint` are candidates for a single fix task
- Consuming skills are free to ignore hints and group differently
- Common hints: `data_loss`, `silent_failure`, `round_trip_gap`, `error_handling`, `concurrency`

**Automatic:** This file is always written so other audit skills can pick up where this one left off. No user action needed.

### On Startup — Read Handoffs (MANDATORY)

Before Step 0 (or Step 1 if skipping discovery), read ALL companion handoff YAMLs that exist:

```
Read .agents/ui-audit/data-model-radar-handoff.yaml (if exists)
Read .radar-suite/time-bomb-radar-handoff.yaml (if exists)
Read .agents/ui-audit/ui-path-radar-handoff.yaml (if exists)
Read .agents/ui-audit/ui-enhancer-radar-handoff.yaml (if exists)
Read .agents/ui-audit/capstone-radar-handoff.yaml (if exists)
```

**Parse `for_roundtrip_radar` sections.** Each companion can direct findings to this skill. Look for:
- `for_roundtrip_radar.suspects[]` — workflows or data paths another skill flagged as potentially broken
- `for_roundtrip_radar.priority_workflows[]` — workflows another skill wants audited first

If found, incorporate as **priority targets** in workflow selection. These are not pre-confirmed findings — verify each one independently.

**What each companion provides:**
- data-model-radar — model gaps that may cause data loss in specific workflows
- ui-path-radar — dead ends and broken promises suggest workflows to prioritize
- ui-enhancer-radar — visual issues in views that may have data backing problems
- capstone-radar — priority workflows from ship readiness grading

**Specific incorporation rules:**
- Dead-end buttons from ui-path-radar → check the workflow behind that button
- Orphaned views from ui-path-radar → verify the data path exists
- Views flagged by ui-enhancer → check if the data binding is correct before suggesting visual changes
- Model gaps from data-model-radar → trace through the workflow that creates/edits that model

If not found, proceed normally.

---

## End Reminder

After every wave/commit/workflow: print progress banner → `AskUserQuestion` → never blank prompt.
