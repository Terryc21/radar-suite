---
name: roundtrip-radar
description: 'Per-journey code audit tracing data through complete user flows for bugs, data safety, performance, and round-trip completeness. Discovers workflows, audits each end-to-end, and rolls up cross-cutting issues. Triggers: "roundtrip audit", "trace user journey", "/roundtrip-radar".'
version: 1.3.0
author: Terry Nyberg
license: MIT
---

# Workflow Code Audit

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

**Genuine problems only:** Report real issues backed by evidence. Do not nitpick, invent issues, or inflate severity. If unsure whether something is a problem, say so — don't report it as a finding.

This skill audits application workflows for bugs, data-safety issues, performance
problems, and data round-trip completeness. It operates in three steps:

- **Step 0** — Discover all workflows (run once, or when workflows change)
- **Step 1** — Deep audit one workflow at a time (one prompt per workflow)
- **Step 2** — Roll-up cross-cutting patterns across all audited workflows

## Usage

- `/workflow-code-audit discover` — Run Step 0 only
- `/workflow-code-audit [WORKFLOW_NAME]` — Run Step 1 for a specific workflow
- `/workflow-code-audit rollup` — Run Step 2 after all individual audits
- `/workflow-code-audit` (no args) — Start with Step 0, then prompt for Step 1

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
Using: [Beginner] mode, [Auto-fix] or [Review first], [Display only]. Type "adjust" to change, or press Enter to continue.
```
If the user types "adjust", re-ask only the question(s) they want to change. Users may want to adjust experience level after a few workflows (beginner explanations may feel too simple, expert too terse).

---

## Terminal Width Check (MANDATORY — run first)

Before ANY output, check terminal width:
```bash
tput cols
```

- **160+ columns** → Use full 8-column Issue Rating Table. Proceed immediately.
- **Under 160 columns** → **Prompt the user first** using `AskUserQuestion`:

  **Question:** "Your terminal is [N] columns wide. The full Issue Rating Table needs 160+ columns. Want to widen it now?"
  - **"I've widened it" (Recommended)** — Re-run `tput cols` to confirm. If tput still reports the old width (terminal resize doesn't always propagate to the shell), trust the user and use full tables anyway.
  - **"Use compact tables"** — Use compact 3-column table with finding text on separate lines below each row:
    ```
    | # | Urgency | Fix Effort |
    |---|---------|------------|
    | 1 | 🟡 HIGH | Small      |
    |   `activeImporterKind` never assigned — file importer silently drops files |
    |   `EnhancedItemDetailView.swift:93` |
    | 2 | ⚪ LOW  | Trivial    |
    |   `showingAddImageMenu` declared but never used — dead code |
    |   `EnhancedItemDetailView.swift:94` |
    ```
    Full 8-column table goes to report file only (if report delivery was selected).
  - **"Skip check"** — Use full 8-column table regardless (user accepts wrapping).

  If the user chose compact mode, **after each compact table, print:**

```
📐 Compact table (terminal: [N] cols). Say "show full table" for all 8 columns.
```

If the user later says "show full table", "wide table", or "full ratings", re-render the most recent findings table in full 8-column format regardless of terminal width. Apply to ALL tables in the session.

---

## Version Check (on first invocation — silent on failure)

On startup, check if a newer version exists. Run in background, do not block the audit:

```bash
curl -sf https://raw.githubusercontent.com/Terryc21/radar-suite/main/skills/roundtrip-radar/VERSION 2>/dev/null
```

- If the remote version is newer than `1.3.0`, print one line before proceeding:
  > Update available: roundtrip-radar v[remote] (you have v1.3.0). Run `git -C ~/.claude/skills/roundtrip-radar pull` or visit https://github.com/Terryc21/radar-suite
- If curl fails, remote is same/older, or command times out — skip silently. Never block the audit for a version check.

---

## Xcode MCP Integration (Optional)

On startup, silently check if Xcode MCP tools are available (e.g., attempt to list tools or check for `xcrun mcpbridge`).

- **Available:** Set `XCODE_MCP = true`, note in audit header: `Xcode MCP: available`
- **Not available:** Set `XCODE_MCP = false`, skip silently. Do not prompt user to install.

**When XCODE_MCP = true, use these tools:**
- `BuildProject` — verify fix compilation after each wave

---

## Plain Language Communication (MANDATORY)

All user-facing prompts must be understandable by someone who has never used this skill before. Apply these rules to every `AskUserQuestion`, progress banner, and completion message:

1. **Describe what was found** in plain terms ("data lost when exporting and re-importing", "backup doesn't save your insurance settings") — not jargon ("serialization gap in round-trip")
2. **Describe next steps by what they DO**, not by skill name ("check your data models for missing fields" not "proceed to data-model-radar")
3. **Describe options by outcome and time cost** ("Fix the data loss bugs now (~20 min)" not "Wave 2: Cross-cutting fixes")
4. **Add an "Explain more" option** to every transition `AskUserQuestion` so users can get context without slowing down experienced users
5. **Define jargon on first use:**
   - "Round-trip" → when data goes through a complete cycle (e.g., create → export → import) and comes back intact
   - "Workflow" → a complete user task from start to finish (e.g., "add an item", "create a backup")
   - "Wave" → "fix batch" (a group of related fixes applied together)
   - "Handoff" → a file this skill writes so other audit skills can pick up where it left off
   - "Cross-cutting" → an issue that appears in multiple workflows (not just one)
   - "Blast radius" → how many files a fix touches
6. **Exception:** If user selected Senior/Expert experience level, terse references are acceptable

### Completion Prompt Template

When all workflows are audited, use this pattern:

```
I traced [X] user workflows end-to-end and found [Y] issues:
- [N] data loss risks (data doesn't survive the complete cycle)
- [N] silent failures (operations appear to succeed but data is wrong/missing)
- [N] other issues

You can:
1. **Fix the data loss issues now** (~[time]) — prevents users from losing data
2. **Fix just the quick wins** (~[time]) — [one-line description]
3. **Keep auditing other areas first** — I'll check [plain description] next
4. **Explain more** — I'll walk through what each issue means before you decide
```

---

## Work Receipts (MANDATORY — every verified finding)

Every finding tagged as `verified` must include a **work receipt** — proof of what was actually checked. No receipt = automatic downgrade to `probable`.

A work receipt includes:
- **File read:** the specific file path and line range that was read
- **Pattern searched:** the grep pattern or search term used
- **Evidence found:** the specific code that confirms the finding (quote 1-3 lines)

**Example — with receipt (verified):**
```
Finding: Room column not imported in CSV
Receipt: Read CSVImportManager.swift:420-447. Searched for `item.room =` — 0 matches.
  Canonical mapping exists at line 45 (`"room": "Room"`) but createItemFromRow never sets item.room.
Confidence: verified
```

**Example — without receipt (downgraded):**
```
Finding: Room column not imported in CSV
Receipt: none (structural analysis only)
Confidence: probable (no file evidence — upgrade to verified by reading CSVImportManager.swift)
```

**Rule:** If you catch yourself writing "verified" without having produced a receipt, stop and either produce the receipt or downgrade to "probable." The receipt is not documentation for the user — it is a structural constraint that prevents claiming depth you didn't achieve.

---

## Contradiction Detection (MANDATORY — before final grades)

Before presenting any domain grade, run this mechanical check:

1. **Findings vs grade:** If a domain has any CRITICAL findings, the grade cannot be above C. If it has any HIGH findings, the grade cannot be above B+. If the calculated score produces a higher grade than these caps allow, lower the grade to the cap and note: "Grade capped from [calculated] to [capped] due to [N] [severity] findings."

2. **Cross-reference handoff vs grade:** If the handoff file for a domain lists blockers, the grade for that domain cannot be A. The handoff represents what was actually found — the grade must be consistent.

3. **Self-consistency:** If two findings in the same report contradict each other (e.g., "backup is comprehensive" in Domain 2 but "InsuranceProfile missing from backup" in the findings table), flag the contradiction explicitly and resolve it before grading.

These checks are mechanical — no judgment needed, just arithmetic and string matching. Run them automatically as the last step before presenting grades.

---

## Finding Classification (MANDATORY)

Classify every finding into one of three categories. Do not report all findings as the same type.

### 1. Bug
Code does something wrong. The behavior contradicts the developer's intent.
- Example: Edit form drops secondary categories on save

### 2. Stale Code
Code was correct when written but the codebase grew around it. Detectable via git history.
- Check: `git log -1 -- <file>` for last modification date
- Check: model/dependency field count at that date vs now
- If the model grew significantly and the code didn't keep up → stale code
- Example: CKRecordMapper mapped 36 of 40 fields when extracted. Model grew to 85+ fields. Mapper only grew to 39.
- Present as: "This code was last updated [date] when [model] had [N] fields. [Model] now has [M] fields. [M-N] fields were added after this code was written. Was this intentional?"

### 3. Design Choice
Intentionally limited scope with documented evidence.
- Requires: CLAUDE.md section, code comment explaining the limitation, or consistent pattern across the codebase
- If no documentation exists, classify as Stale Code, not Design Choice
- Present as: "Documented decision: [quote from docs]. If this no longer reflects your intent, reclassify as stale code."

### Why This Matters
"Design choice" is often a euphemism for "built under time pressure, never revisited." The distinction between categories 2 and 3 is the presence of evidence. Without evidence, assume stale — the developer can always correct you.

### Developer Growth Awareness (how to frame findings)

A solo developer's codebase reflects multiple versions of themselves — early code reflects early understanding. Frame findings accordingly:

**For bugs:** Direct and specific. "This code does X when it should do Y."

**For stale code:** Frame as growth, not failure. Show the developer their own progress:
- "You've since adopted [better pattern] in [newer file] — this older file uses the earlier approach."
- "This was written [date] when the model had [N] fields. You've added [M-N] fields since then. The [feature] didn't keep up."
- "Your current code in [newer file] handles this correctly. This older code predates that pattern."

**For design choices:** Respect the decision but invite reconsideration:
- "This was documented as intentional [quote]. Given what you've built since then, does this still match your intent?"

**Never frame findings as criticism.** Every finding is an opportunity for current-self to revisit past-self's decisions — not a judgment on past-self's competence. Early code worked. It shipped. It just reflects an earlier stage of understanding.

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

1. **Data safety** — destructive operations, transaction boundaries, edge cases
2. **Error handling** — missing catches, silent failures, user-facing error messages
3. **Concurrency** — `@MainActor` compliance, Task isolation, ModelContext thread safety
4. **Performance** — `@Query` without predicates, O(n²) loops, main-thread blocking
5. **Contract mismatches** — constants vs hardcoded strings, keys defined in one file but consumed in another
6. **Round-trip completeness** — does data survive a full create → export → import/restore cycle?
7. **Interruption paths** — dismiss mid-operation, app backgrounding, rotation, cancel
8. **Tests** — update broken tests, add tests for P0-P1 fixes where logic is testable

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

## Findings by File (auto-generated after findings table)

After the main findings table, re-group all findings by file path:

```
### Findings by File

**Sources/Managers/BackupManager.swift** (3 findings)
- #1 (🔴 CRITICAL) — one-line summary
- #5 (🟡 HIGH) — one-line summary
- #9 (🟢 MEDIUM) — one-line summary

**Sources/ViewModels/AddItemViewModel.swift** (1 finding)
- #3 (🟡 HIGH) — one-line summary
```

- Sort files by highest-severity finding first (files with CRITICAL first)
- Finding numbers match the main table for cross-reference
- Skip this section entirely if fewer than 3 total findings
- For Senior/Expert users, omit the "no findings" file list

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

**HARD GATE: After EVERY wave, EVERY commit, and EVERY build verification, your response MUST end with the progress banner + `AskUserQuestion`. If your response does not end with `AskUserQuestion`, you have violated this rule. Check before sending.**

**This includes:**
- After `git commit` → banner + AskUserQuestion (not just "committed" or "ready to push")
- After `xcodebuild build` succeeds → banner + AskUserQuestion (not just "build passed")
- After all fixes in a wave are applied → banner + AskUserQuestion
- After wrapping up a workflow → banner + AskUserQuestion for next workflow
- After all workflows done → banner + AskUserQuestion for wrap-up/next-skill

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

## Inline Cross-Skill Referrals

When a finding primarily belongs to another skill's domain, append this line to the finding:

`→ Deeper analysis: /[skill-name] [relevant-command]`

| If the finding involves... | Refer to |
|---------------------------|----------|
| Missing/incomplete model fields | `/data-model-radar [ModelName]` |
| Navigation dead ends or broken links | `/ui-path-radar` |
| Visual layout, spacing, color issues | `/ui-enhancer-radar [ViewName]` |
| Overall release readiness | `/capstone-radar` |

Do NOT refer to roundtrip-radar (that's this skill). Do NOT refer to a skill already running in this session.

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

for_ui_path_radar:
  # Data issues that may have navigation/entry-point implications
  suspects:
    - entry_point: "<button/link that triggers this workflow>"
      finding: "<data safety issue found>"
      file: "<file:line>"
      question: "<does the UI reflect this data issue?>"

for_ui_enhancer_radar:
  # Dead code, orphaned UI, or views with broken data backing
  suspects:
    - view: "<view file>"
      finding: "<data issue that affects this view>"
      action: "verify data binding or remove dead UI"

for_capstone_radar:
  # Critical/high findings that affect ship readiness
  blockers:
    - finding: "<description>"
      urgency: "<CRITICAL|HIGH>"
      workflow: "<workflow name>"

cross_cutting_patterns:
  # Patterns found across multiple workflows — useful for all skills
  - pattern: "<e.g., Double() price parsing>"
    workflows_affected: ["Backup", "Edit Item", "CSV Import"]
    status: "fixed" | "deferred"
```

**Automatic:** This file is always written so other audit skills can pick up where this one left off. No user action needed.

### On Startup — Read Handoffs (MANDATORY)

Before Step 0 (or Step 1 if skipping discovery), read ALL companion handoff YAMLs that exist:

```
Read .agents/ui-audit/data-model-radar-handoff.yaml (if exists)
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

## Finding Resolution Gate (MANDATORY before wrap-up)

**The audit cannot end until every finding has a terminal state.** The auditor does not get to decide which findings are "not worth asking about" — the user decides.

Before writing the handoff file or presenting the wrap-up summary:

1. List all findings from the session
2. Check each has a terminal state: **Fixed** / **Accepted** / **Deferred** (with reason)
3. If any finding lacks a terminal state, present it to the user via `AskUserQuestion`
4. Only after all findings are resolved can you write the handoff and wrap up

**Not terminal:** "Noted" / "Observed" / "Documented" — these are descriptions, not decisions. Findings presented in a table but never asked about individually are not resolved.

### User Experience Gate (applies to all findings)

Before accepting a "Deferred (Post-release)" classification, check: **When this feature fails, does the user discover it silently, eventually, or immediately and visibly?**

- **Silent** — Post-release deferral OK.
- **Eventually** — Post-release acceptable if documented.
- **Immediately and visibly** — **Cannot be Post-release. Must be Pre-release regardless of fix effort.**

### Deferred Finding Re-evaluation (on startup)

When reading existing DEFERRED.md or handoff files at startup, re-evaluate every deferred finding against the User Experience Gate. If a Post-release finding would be immediately visible to users, challenge the deferral.

---

## REMINDER (End-of-File — Survives Context Compaction)

**CRITICAL:** After EVERY fix batch (wave), EVERY commit, and EVERY workflow transition:
1. Print the progress banner (wave-level or workflow-level)
2. Immediately `AskUserQuestion` for the next step
3. NEVER leave a blank prompt

This reminder is placed at the end of the file because context compaction tends to preserve the beginning and end. If you are unsure whether to print the banner, **print it**.
