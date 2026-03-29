---
name: data-model-radar
description: 'Audits SwiftData/Core Data model layer for field completeness, serialization gaps, relationship integrity, semantic ambiguity, dead fields, and migration safety. Finds model-layer bugs that manifest as workflow bugs. Triggers: "audit models", "model radar", "/data-model-radar".'
version: 1.4.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, Bash, Edit, Write, AskUserQuestion]
inherits: radar-suite-core.md
metadata:
  tier: execution
  category: analysis
---

# Data Model Radar

> Audits the @Model layer for completeness, consistency, and round-trip integrity. Finds model-layer bugs before they manifest as workflow bugs.

**Anti-shortcut rule:** Do not claim a domain is "clean" without evidence. Every domain grade must cite specific files read and patterns checked. "No dead fields detected from structural analysis" without grepping is a failing grade for the auditor, not a passing grade for the model.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/data-model-radar` | Full 7-domain audit of all models |
| `/data-model-radar [ModelName]` | Audit a single model in depth |
| `/data-model-radar serialization` | Domain 2 only — backup/export coverage |
| `/data-model-radar relationships` | Domain 3 only — cascade rules, orphan risk |
| `/data-model-radar migration` | Domain 6 only — schema version safety |
| `/data-model-radar dead-fields` | Domain 5 only — unused model fields |
| `/data-model-radar status` | Show audit progress |

## Overview

Data Model Radar audits the foundation your app is built on — the data models. Every UI bug, every sync failure, every round-trip data loss traces back to a model-layer decision. This skill finds those issues at the source instead of waiting for them to surface in workflows.

| Domain | What It Finds | Est. Time |
|--------|--------------|-----------|
| **1. Field Completeness** | Missing fields, enum gaps, semantic holes | ~3-5 min |
| **2. Serialization Coverage** | Backup/export fields that don't round-trip | ~10-20 min |
| **3. Relationship Integrity** | Cascade rules, inverse relationships, orphan risk | ~3-5 min |
| **4. Semantic Clarity** | nil vs zero ambiguity, missing type distinctions | ~2-3 min |
| **5. Field Usage Mapping** | Dead fields (no UI reads), phantom fields (UI shows, model doesn't store) | ~10-20 min |
| **6. Migration Safety** | Schema versions, VersionedSchema coverage, migration plan gaps | ~5-10 min |
| **7. Cross-Model Consistency** | Identifier strategy, naming conventions, shared pattern violations | ~3-5 min |

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

**Experience-adapted explanations for Data Model Radar:**

- **Beginner**: "Data Model Radar checks the blueprints your app is built on — the data models that define what an 'item' or 'warranty' or 'photo' looks like in the database. Think of it like inspecting a building's foundation before checking the rooms. If the blueprint says a house has 10 rooms but only 8 have doors, people can't reach 2 rooms. Similarly, if your Item model has 47 fields but your backup only saves 40, those 7 fields are lost forever when someone restores from backup. This skill finds those gaps."

- **Intermediate**: "Data Model Radar audits your @Model classes for field completeness (missing enums, semantic holes), serialization coverage (backup/export round-trip gaps), relationship integrity (cascade rules, orphan risk), nil-vs-zero ambiguity, dead fields (defined but never read), migration safety (schema versions), and cross-model consistency. It finds model-layer bugs that would otherwise surface as workflow bugs across multiple features."

- **Experienced**: "7-domain audit of @Model layer: field completeness, serialization coverage, relationship integrity, semantic clarity, usage mapping, migration safety, cross-model consistency. Outputs issue rating tables with fix plans. Findings feed roundtrip-radar as suspects."

- **Senior/Expert**: "Model audit: fields → serialization → relationships → semantics → usage → migration → consistency. Rating tables + fix plans."

Store the experience level as `USER_EXPERIENCE` and apply to ALL output for the session.

**Subsequent models (if auditing multiple):** Show one-line reminder:
```
Using: [Beginner] mode, [Auto-fix] or [Review first], [Display only]. Type "adjust" to change, or press Enter to continue.
```

---

## Shared Patterns

See `radar-suite-core.md` for: Table Format, Plain Language Communication, Work Receipts, Contradiction Detection, Finding Classification, Audit Methodology, Context Exhaustion, Progress Banner, Issue Rating Tables, Handoff YAML schema.

---

## Audit Depth

Each domain can be run at two depths:

| Depth | When to Use | What It Does |
|-------|-------------|-------------|
| **Quick** | Triage, low-risk models, <10 fields | Structural analysis — read the model, check patterns, report what's visible |
| **Deep** | High-risk models, >20 fields, multiple serialization targets | Grep every field, read every serialization target, verify every claim |

**Default:** Deep for models with Risk = High. Quick for Low risk. Ask for Medium risk.

**The difference matters.** A quick audit of Domain 5 says "no obvious dead fields." A deep audit greps each of the 55 fields and proves it. Quick audits must label their grades with `(quick)` so the handoff distinguishes verified from unverified.

---

## Risk-Ranking (MANDATORY — before any verification)

**Do not start verifying until you have ranked where to go deep.** The default behavior is to verify whatever is easiest to read (usually backup code) and skip what's harder (CSV import, CloudKit mapping). Risk-ranking inverts this: verify riskiest first, not easiest first.

### Six Signals (Check in Order)

**Signal 1: Prior findings exist.**
Before choosing depth, check:
- Memory files for prior audit results mentioning this model
- `.agents/ui-audit/*-handoff.yaml` for companion skill findings
- `.agents/research/*-audit.md` for previous capstone/codebase audit notes

If prior sessions found CSV import loses fields, go deep on CSV — not backup. This is the strongest signal and the cheapest to collect.

**Signal 2: Asymmetry between input and output.**
Count fields on both sides of any serialization target. If export writes 27 columns but import reads 11, the 16-field gap is where data loss hides. Go deep on the smaller side (the reader, not the writer).

**Signal 3: Recently changed code.**
```bash
git log --since="3 months ago" -p -- Sources/Models/{Model}.swift | grep "^+.*var " | head -20
```
New fields are most likely to be missing from serialization structs. Cross-reference these against backup/CSV/CloudKit code.

**Signal 4: Multiple systems touch the same data.**
Count how many systems read/write each field. A field serialized across backup + CSV + CloudKit + UI = 4 consumers = high risk. A field only in one view = low risk.

**Signal 5: Money, identity, and relationships.**
Fields with `InCents`/`Price`/`Value`/`Cost`, identity fields (`cloudSyncID`, `ownerUserRecordID`), and `@Relationship` properties have higher consequences when gaps exist.

**Signal 6: The "looks clean" feeling (meta-signal).**
When you feel confident about a domain without having produced its required artifact — that IS the signal to stop and do the work. Confidence without evidence is the #1 predictor of shallow work.

### Risk-Ranking Output

Before starting Domain 1, produce a risk-ranking table:

```
Risk Ranking for [Model]:
  GO DEEP:
    1. CSV import (Signal 2: 27 export vs 11 import — 16-field asymmetry)
    2. Price fields (Signal 5: 6 currency fields across 3 serialization targets)
    3. Fields added since Build 24 (Signal 3: 4 new fields in last 3 months)
  QUICK OK:
    4. Backup (Signal 1: prior audit found full coverage)
    5. Relationship integrity (low change rate, all cascade)
  NOT APPLICABLE:
    6. CloudKit (no CKRecord mapping code found)
```

This table determines where time is spent. Domains that touch "GO DEEP" items get deep verification. Domains that only touch "QUICK OK" items can use quick verification (labeled accordingly).

---

## Step 0: Model Discovery

Scan the codebase and identify all data models.

### How to Find Them

1. Search for `@Model` classes: `Grep pattern="@Model" glob="**/*.swift" path="Sources/"`
2. Search for Core Data entities if applicable: `Glob pattern="**/*.xcdatamodeld"`
3. Search for Codable structs used in serialization: backup structs, export structs
4. Search for relationship models: `Grep pattern="@Relationship" glob="**/*.swift"`

### Output

| # | Model | File | Fields | Relationships | Serialized In | Risk |
|---|-------|------|--------|---------------|---------------|------|
| 1 | Item | Item.swift | 47 | 12 | Backup, CSV, CloudKit | High |
| 2 | PhotoAttachment | PhotoAttachment.swift | 6 | 1 | Backup, CloudKit | Medium |

**Risk criteria:**
- **High** — Many fields (>20) + multiple serialization targets + external sync
- **Medium** — Moderate fields (10-20) + some serialization
- **Low** — Simple model (<10 fields), local only, cache/ephemeral

### Recently Changed Fields (Deep mode)

For high-risk models, identify fields most likely to have serialization gaps:
```bash
git log --since="3 months ago" -p -- Sources/Models/Item.swift | grep "^+.*var " | head -20
```

Fields added recently are highest risk — they may not have been added to backup/CSV/CloudKit structs yet. **Audit these first in Domain 2.**

Recommend which models to audit first (highest risk, most relationships).

---

## Step 1: Per-Model Audit

Audit one model at a time across all 7 domains.

### Before Starting (First Model Only)

Ask setup questions:

**"How should fixes be handled?"**
- **Auto-fix safe items (Recommended)** — Apply isolated, low-blast-radius fixes automatically. Present cross-cutting fixes and design decisions for approval first.
- **Review first** — Present all findings with ratings, then ask before making any changes. Fixes still happen — you just approve each wave first.

**IMPORTANT:** Both modes lead to fixes. "Review first" means the user sees the plan before code changes — it does NOT mean "skip fixes and jump to handoff." After presenting findings, ALWAYS offer to fix them regardless of which mode was selected.

- Delivery: Display only / Report / Both
- Presence: Normal / Hands-free / Pre-approved

### Domain 1: Field Completeness `enumerate-required`

**What to check:**
- Are there fields that *should* exist based on how the model is used?
  - Grep for hardcoded strings/enums that could be model fields (e.g., `"inherited"` string where an `acquisitionType` enum should exist)
  - Check if sibling models have fields this model lacks (e.g., all models have `cloudSyncID` except one)
- Are enums complete? Check every `switch` statement — are there `default` cases hiding missing enum values?
- Are optional fields appropriately optional? (Should `warrantyMonths` really be non-optional with default 12?)

**Output per finding:** What field is missing, why it should exist, which code paths would use it.

### Domain 2: Serialization Coverage `enumerate-required`

**MANDATORY CHECKLIST — verify each target explicitly:**

For the model being audited, check ALL applicable serialization targets. Do not skip any.

- [ ] **Backup struct** — Read the `BackupXxx` struct. Diff every model field against backup fields. List gaps.
- [ ] **CSV export** — Find the CSV export code (e.g., `CSVExportManager`, `ExportManager`). Read it. List which model fields map to CSV columns and which don't.
- [ ] **CSV import** — Find the CSV import code (e.g., `CSVImportManager`). Read it. List which CSV columns map back to model fields. The export→import gap is where data loss hides.
- [ ] **CloudKit sync** — Find CKRecord mapping code (e.g., `CloudSyncManager`, `SharedZoneSyncManager`). List synced fields.
- [ ] **JSON API** — If the model receives data from an API, check the response mapping.

**Do not report a target as "covered" without reading the actual code.** "Backup looks complete" without reading BackupItem is not verification.

**Method:**
1. Read the model — list all stored properties (exclude `@Transient` computed properties)
2. Read each serialization struct/function listed above
3. Diff: model fields NOT in serialization = potential data loss on round-trip
4. For each gap, determine: intentional exclusion or oversight?

**Output:** Side-by-side coverage table:

```
| Field | Model | Backup | CSV Export | CSV Import | CloudKit |
|-------|:-----:|:------:|:---------:|:----------:|:--------:|
| title | yes | yes | yes | yes | yes |
| cloudSyncID | yes | yes | no | no | yes |
| documents | yes | no | no | no | yes |
```

Mark fields not checked with `?` instead of yes/no. The table must be honest about what was verified.

### Verification Template (MANDATORY for Domain 2)

Before grading serialization coverage, produce this pre-populated table. Read the model file first to get all stored properties, then fill in each cell by reading the actual serialization code.

```
| Field | Model | Backup | CSV Export | CSV Import | CloudKit | Receipt |
|-------|:-----:|:------:|:---------:|:----------:|:--------:|---------|
| [field1] | yes | ? | ? | ? | ? | (fill after reading each target) |
| [field2] | yes | ? | ? | ? | ? | |
```

Rules:
- `yes` = confirmed by reading the code (include file:line in Receipt column)
- `no` = confirmed absent by reading the code
- `?` = not yet checked
- A domain grade CANNOT be produced while any cell contains `?` for a target you claimed to check
- If you skip a target (e.g., don't read CloudKit), mark the entire column as `not checked` — don't fill in `?` and then grade as if you checked it

### Domain 3: Relationship Integrity `mixed`

**What to check:**
- Every `@Relationship` has a correct `deleteRule` (`.cascade`, `.nullify`, `.deny`, `.noAction`)
- Every `@Relationship` has an `inverse` specified
- Cascade chains don't create unexpected data loss (deleting Item cascades to Photos, which is correct — but does it also cascade to SharedZone records?)
- Orphan risk: can child objects exist without a parent? (e.g., PhotoAttachment with `item: Item? = nil`)
- Circular relationships: A → B → A

**Method:**
1. Grep for all `@Relationship` declarations
2. For each, verify: deleteRule, inverse, optional vs required
3. Build a relationship graph and check for orphan paths

### Domain 4: Semantic Clarity `enumerate-required`

**What to check:**
- **nil vs zero:** For every `Int?` field, is there UI or documentation that distinguishes "not set" from "zero"? (e.g., `priceInCents: Int?` — nil = not entered, 0 = free. But does the UI show this difference?)
- **Missing type distinctions:** Are there fields where a single type carries multiple meanings? (e.g., `priceInCents` used for both new and used purchases — should there be separate fields?)
- **Boolean ambiguity:** `isEstimatedPrice` — does `false` mean "confirmed exact" or "user never set this flag"?
- **String fields that should be enums:** Fields like `disposalMethodRaw: String` — is the enum complete? Are there raw strings in the codebase that don't match any enum case?

### Domain 5: Field Usage Mapping `mixed`

**What to check:**
- **Dead fields:** Model properties that are never read in any view, ViewModel, or manager. Set during creation but never displayed or used in calculations.
- **Phantom fields:** Values shown in the UI that are computed on-the-fly and never stored. If the computation inputs change, the displayed value changes retroactively (e.g., donation FMV recalculated from condition).
- **Write-only fields:** Set by the user but never read back (data goes in but nothing comes out).
- **Read-only fields:** Displayed but never settable by the user (may be intentional for computed fields, but worth flagging if the user might want to override).

**Method (Deep — required for High-risk models):**

For models with >20 fields, use a **stratified sampling strategy** instead of grepping all fields:

1. **All recently added fields** (from git log in Step 0) — highest risk for being unwired
2. **All currency fields** (`*InCents`, `*Price*`, `*Value*`, `*Cost*`) — money = high risk
3. **All optional fields** (`var x: Type? = nil`) — more likely to be dead than required fields
4. **All fields with "raw" suffix** (`*Raw`) — enum storage, check if enum is used anywhere
5. **Random sample of remaining fields** (5-10) to spot-check

For each sampled field:
```
Grep pattern="\.fieldName" glob="**/*.swift" path="Sources/" output_mode="files_with_matches"
```

Flag: 0 read hits in Sources/ (excluding the model file itself and Tests/) = dead field candidate. Verify by reading one suspected consumer.

**Method (Quick — for Low-risk models):**
1. List all stored properties
2. Check for obvious dead patterns: fields with no corresponding UI label, fields added but never referenced in any view
3. Label grade as `(quick)` — not fully verified

### Domain 6: Migration Safety `enumerate-required`

**What to check (Deep — read the actual schema files):**
1. **Read the VersionedSchema file** — `Glob pattern="**/*Schema*.swift"` or `**/*Migration*.swift"`
2. **Verify the latest schema version includes all current model fields.** Diff the schema's model definition against the actual model. Any field in the model but not in the latest schema version = migration gap.
3. Does a `SchemaMigrationPlan` exist with proper stage ordering?
4. Are there fields added without migration? (SwiftData handles simple additions automatically, but relationship changes or type changes need explicit migration)
5. Has the model changed since the last migration version? Compare timestamps: `git log -1 --format="%ai" -- Sources/Models/Item.swift` vs `git log -1 --format="%ai" -- Sources/Models/AppSchema.swift`
6. Are there `@Attribute` modifiers that affect storage (`.externalStorage`, `.unique`) — are these in the migration plan?

**Do not say "migration infrastructure exists" without reading the schema file.** That's the same as saying "backup exists" without reading BackupItem.

### Domain 7: Cross-Model Consistency `enumerate-required`

**Minimum model requirement:** This domain requires reading at least 3 models to be meaningful. When auditing a single model, this domain outputs one of:

- **If 3+ models are being audited this session:** Full cross-model comparison.
- **If single model audit:** Read 2-3 additional model files (pick the highest-relationship models from Step 0) to compare patterns, then grade. Label as `(partial — N models compared)`.

**What to check:**
- **Identifier strategy:** Do all models use the same approach? (Some use `cloudSyncID`, some use `persistentModelID.hashValue`, some use UUID — should be consistent)
- **Timestamp conventions:** `timestamp`, `createdAt`, `date` — same concept, different names across models?
- **Naming patterns:** `priceInCents` vs `deductibleInCents` vs `fairMarketValue` (not in cents?) — consistent currency representation?
- **Shared protocol conformances:** Do models that should be `Sendable` all conform? Do models with `cloudSyncID` all use it the same way?

---

## Issue Rating Criteria

For every finding, use this table format sorted by Urgency (descending), then ROI:

| # | Finding | Confidence | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort | Status |
|---|---------|------------|---------|-----------|--------------|-----|--------------|------------|--------|

### Column Definitions

| Column | Meaning |
|--------|---------|
| Confidence | `verified` (code read + confirmed), `probable` (structural analysis, not independently verified), `needs-runtime` (requires running the app to confirm) |
| Urgency | CRITICAL / HIGH / MEDIUM / LOW |
| Risk: Fix | What could break when making the change |
| Risk: No Fix | Cost of leaving it — data loss, crash, user-visible bug |
| ROI | Excellent / Good / Marginal / Poor |
| Blast Radius | Number of files the fix touches (e.g., `3 files`, `1 file`). Count by grepping for callers/references before rating. |
| Fix Effort | Trivial / Small / Medium / Large |
| Status | Fixed / Documented / Deferred (reason) |

---

## Fix Plan

Group findings into:

**1. Safe fixes (isolated, low blast radius)**

**2. Cross-cutting fixes (touch shared code)**

**3. Schema changes (require migration)**
Changes that add/modify/remove model fields. These need:
- VersionedSchema update
- SchemaMigrationPlan stage
- Backup format update (if field should be serialized)
- Testing on real device with existing data

| # | Finding | Migration Required | Backward Compatible | Fix Effort |
|---|---------|-------------------|--------------------:|------------|

**4. Shared utility extraction**
When multiple models duplicate the same pattern, extract to a shared protocol or utility.

**5. Design decisions (need user input)**

**6. Deferred**

---

## Fix Application Workflow

Apply fixes in **waves** with progress tracking.

### Wave Scaling

Scale the number of waves to finding severity:

- **All findings LOW/MEDIUM, no schema changes:** Collapse to 1 wave (safe fixes) + commit. Skip waves 2-4.
- **Mixed severity, no schema changes:** 2 waves (safe + cross-cutting) + commit.
- **Schema changes present:** Full 5-wave workflow.

### Waves (Full)

| Wave | Section | Est. Time | Description |
|------|---------|-----------|-------------|
| 1 | Safe fixes + tests | ~10-15 min | No schema changes, isolated. Write tests for each fix. |
| 2 | Cross-cutting fixes + tests | ~15-25 min | Touch shared code. Write tests for each fix. |
| 3 | Schema changes + tests | ~20-35 min | Model + migration + backup + tests on real data. |
| 4 | Pattern Sweep | ~5 min | Scan codebase for patterns found. |
| 5 | Build + Test + Commit | ~5 min | Build both platforms, run tests, stage, commit. |

**Every fix must have a test.** Do not move to the next wave until tests for the current wave's fixes are written and compiling. The test verifies the fix works; without it, the fix is unverified code.

### Progress Banner (CRITICAL — BLOCKING requirement)

**After EVERY wave and EVERY commit, your NEXT output MUST be the progress banner followed by the next-wave `AskUserQuestion`. Do not output anything else first. Do not leave a blank prompt.**

After completing each wave, **always** print:

```
Step [N] of [total] complete: [plain description of what was done]
   [X] issues fixed, [Y] remaining, [Z] deferred

Next: [plain description of what comes next] (~[time estimate])
```

Then immediately ask using `AskUserQuestion`:
- **"Continue to next step (Recommended)"** — proceed with the next batch of fixes
- **"Show me what was fixed"** — review the changes before continuing
- **"Stop here"** — defer remaining fixes
- **"Explain more"** — describe what the next step involves and why

### Between Models

After all waves for a model, print scorecard and prompt for next model:

```
Progress: [N] of [total] models checked | [X] issues fixed | [Y] deferred
   Just finished: [model name] — [one-line summary of what was found]
   Next up: [model name] (~[time estimate])
```

Then ask: "Ready to check the next model?" with options including **"Explain more"** — what this model is and why it matters.

---

## Cross-Skill Handoff

Data Model Radar is the **foundation layer** of the radar family. Run it first — its findings feed every other skill.

### On Completion — Write Handoff

After auditing models, write `.agents/ui-audit/data-model-radar-handoff.yaml`:

```yaml
source: data-model-radar
date: <ISO 8601>
project: <project name>
models_audited: <count>
audit_depth: <full | partial | quick>
domains_verified: [1, 2, 3, 4, 5, 6, 7]
domains_at_quick_depth: []
domains_skipped: []

# File timestamps — enables staleness detection by consuming skills
file_timestamps:
  <file path>: "<ISO 8601 mod date>"
  # one entry per unique file referenced in issues

for_roundtrip_radar:
  # Serialization gaps = workflow-specific data loss
  suspects:
    - workflow: "<affected workflow>"
      finding: "<e.g., DocumentAttachment not in BackupItem>"
      model: "<model name>"
      field: "<field name>"
      group_hint: "<optional, e.g. 'backup_gaps', 'csv_gaps', 'cloudkit_gaps'>"

for_ui_path_radar:
  # Dead fields may indicate dead UI paths
  suspects:
    - view: "<view that might reference this field>"
      finding: "<e.g., field exists but no UI reads it>"
      group_hint: "<optional batching suggestion>"

for_ui_enhancer_radar:
  # Semantic ambiguity affects how fields should be displayed
  suspects:
    - view: "<view displaying this field>"
      finding: "<e.g., nil vs 0 not distinguished in UI>"
      group_hint: "<optional batching suggestion>"

for_capstone_radar:
  # Model-layer blockers
  blockers:
    - finding: "<description>"
      urgency: "<CRITICAL|HIGH>"
      domain: "Data Safety"
      group_hint: "<optional batching suggestion>"

serialization_coverage:
  # Summary table for roundtrip-radar to reference
  # Only include targets that were ACTUALLY READ AND VERIFIED
  - model: "Item"
    total_fields: 47
    backup_coverage: 40
    backup_verified: true
    csv_export_coverage: 27
    csv_export_verified: true
    csv_import_coverage: 11
    csv_import_verified: true
    cloudkit_verified: false
    missing_from_backup: ["field1", "field2"]
    missing_from_csv_export: ["field3", "field4"]
```

### File Timestamps

For each unique file path referenced across all issues, record its modification date:

```bash
stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "<file path>"
```

Enables consuming skills to detect **staleness** — if a model file changed after the audit, serialization coverage data may be stale.

### Group Hints

Optional field for batching related issues. Common hints:
- `backup_gaps` — fields missing from backup
- `csv_gaps` — fields missing from CSV export/import
- `cloudkit_gaps` — fields missing from CloudKit sync
- `dead_fields` — model fields with no UI reads
- `semantic_ambiguity` — nil vs zero not distinguished

**Honesty rule:** The handoff must distinguish "verified clean" from "not checked." Use `_verified: true/false` for each serialization target. Capstone-radar uses these flags to determine how much credit to give.

### On Startup — Read Handoffs (MANDATORY)

Before starting Step 1, read ALL companion handoff YAMLs that exist:

```
Read .agents/ui-audit/roundtrip-radar-handoff.yaml (if exists)
Read .agents/ui-audit/ui-path-radar-handoff.yaml (if exists)
Read .agents/ui-audit/ui-enhancer-radar-handoff.yaml (if exists)
Read .agents/ui-audit/capstone-radar-handoff.yaml (if exists)
```

**Parse `for_data_model_radar` sections.** Each companion can direct findings to this skill. Look for:
- `for_data_model_radar.suspects[]` — models or fields another skill flagged as potentially wrong
- `for_data_model_radar.priority_models[]` — models another skill wants audited first

If found, incorporate as **priority targets** in the model audit order. These are not pre-confirmed findings — verify each one independently. If not found, proceed normally.

**What each companion provides:**
- roundtrip-radar — workflow-specific data issues that trace to model gaps
- ui-path-radar — dead UI that may indicate dead model fields
- ui-enhancer-radar — visual issues that may trace to missing/wrong model fields
- capstone-radar — priority models from ship readiness grading

**Automatic:** This file is always written so other audit skills can pick up where this one left off. No user action needed.

---

## Step 2: Cross-Model Rollup

After auditing all high-risk models, identify patterns across models:

1. Shared serialization gaps (e.g., "3 models missing from backup")
2. Inconsistent identifier strategies
3. Naming convention violations
4. Missing shared protocols
5. Top 5 deferred items ranked by impact

---

## Domain Grade Evidence Requirements

Every domain grade MUST cite what was actually done. Use this format after each domain:

```
**Evidence:** Read BackupItem (BackupManager.swift:32-340). Diffed 55 model fields against 55 backup fields.
Verified toItem() restore at line 342-546. CSV export NOT checked (CSVExportManager not read).
**Confidence:** verified (backup), not-checked (CSV, CloudKit)
```

A grade without evidence is not a grade — it's a guess.

---

## End Reminder

After every step: print progress banner → `AskUserQuestion` → never blank prompt.

**Anti-shortcut:** Domain 2 (Serialization) and Domain 5 (Field Usage) require actual grep verification. No "looks complete" without evidence.
