# Domain Definitions Reference — Data Model Radar
> Loaded by SKILL.md during Step 1: Per-Model Audit. For single-domain commands, load only the relevant section.

### Domain 1: Field Completeness

**What to check:**
- Are there fields that *should* exist based on how the model is used?
  - Grep for hardcoded strings/enums that could be model fields (e.g., `"inherited"` string where an `acquisitionType` enum should exist)
  - Check if sibling models have fields this model lacks (e.g., all models have `cloudSyncID` except one)
- Are enums complete? Check every `switch` statement — are there `default` cases hiding missing enum values?
- Are optional fields appropriately optional? (Should `warrantyMonths` really be non-optional with default 12?)

**Output per finding:** What field is missing, why it should exist, which code paths would use it.

### Domain 2: Serialization Coverage

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

### Domain 3: Relationship Integrity

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

### Domain 4: Semantic Clarity

**What to check:**
- **nil vs zero:** For every `Int?` field, is there UI or documentation that distinguishes "not set" from "zero"? (e.g., `priceInCents: Int?` — nil = not entered, 0 = free. But does the UI show this difference?)
- **Missing type distinctions:** Are there fields where a single type carries multiple meanings? (e.g., `priceInCents` used for both new and used purchases — should there be separate fields?)
- **Boolean ambiguity:** `isEstimatedPrice` — does `false` mean "confirmed exact" or "user never set this flag"?
- **String fields that should be enums:** Fields like `disposalMethodRaw: String` — is the enum complete? Are there raw strings in the codebase that don't match any enum case?

### Domain 5: Field Usage Mapping

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

### Domain 6: Migration Safety

**What to check (Deep — read the actual schema files):**
1. **Read the VersionedSchema file** — `Glob pattern="**/*Schema*.swift"` or `**/*Migration*.swift"`
2. **Verify the latest schema version includes all current model fields.** Diff the schema's model definition against the actual model. Any field in the model but not in the latest schema version = migration gap.
3. Does a `SchemaMigrationPlan` exist with proper stage ordering?
4. Are there fields added without migration? (SwiftData handles simple additions automatically, but relationship changes or type changes need explicit migration)
5. Has the model changed since the last migration version? Compare timestamps: `git log -1 --format="%ai" -- Sources/Models/Item.swift` vs `git log -1 --format="%ai" -- Sources/Models/AppSchema.swift`
6. Are there `@Attribute` modifiers that affect storage (`.externalStorage`, `.unique`) — are these in the migration plan?

**Do not say "migration infrastructure exists" without reading the schema file.** That's the same as saying "backup exists" without reading BackupItem.

### Domain 7: Cross-Model Consistency

**Minimum model requirement:** This domain requires reading at least 3 models to be meaningful. When auditing a single model, this domain outputs one of:

- **If 3+ models are being audited this session:** Full cross-model comparison.
- **If single model audit:** Read 2-3 additional model files (pick the highest-relationship models from Step 0) to compare patterns, then grade. Label as `(partial — N models compared)`.

**What to check:**
- **Identifier strategy:** Do all models use the same approach? (Some use `cloudSyncID`, some use `persistentModelID.hashValue`, some use UUID — should be consistent)
- **Timestamp conventions:** `timestamp`, `createdAt`, `date` — same concept, different names across models?
- **Naming patterns:** `priceInCents` vs `deductibleInCents` vs `fairMarketValue` (not in cents?) — consistent currency representation?
- **Shared protocol conformances:** Do models that should be `Sendable` all conform? Do models with `cloudSyncID` all use it the same way?
