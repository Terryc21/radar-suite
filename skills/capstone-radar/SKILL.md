---
name: capstone-radar
description: 'Unified A-F grading and ship/no-ship decisions for the 5-skill radar family. Aggregates companion handoffs, owns 5 grep-reliable domains, tracks velocity, celebrates improvements. Triggers: "capstone radar", "can I ship", "grade codebase", "/capstone-radar".'
version: 3.1.0
author: Terry Nyberg
license: MIT
---

# Capstone Radar

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

**Required output:** Every finding MUST include Urgency, Risk, ROI, and Blast Radius ratings. Do not omit these ratings.

Capstone Radar is the **aggregator + gap filler** for the 5-skill radar family. It consumes findings from 4 companion skills, runs its own scans for 5 domains the companions don't cover, grades everything on one unified scale, and makes the ship/no-ship decision.

It does NOT:
- Re-scan domains already covered by companion skills
- Dispatch Axiom auditor agents
- Produce separate reports for domains companions already cover

## Usage

- `/capstone-radar` — Full analysis — checks everything and reads findings from other audits you've run
- `/capstone-radar quick` — Quick check — only looks at its own areas, ignores other audit results
- `/capstone-radar report` — No scanning, re-grade from existing handoff files only

---

## Skill Introduction (MANDATORY — run before anything else)

On first invocation, ask the user two questions in a single `AskUserQuestion` call:

**Question 1: "What's your experience level with Swift/SwiftUI?"**
- **Beginner** — New to Swift. Plain language, analogies, define terms on first use.
- **Intermediate** — Comfortable with SwiftUI basics. Standard terms, explain non-obvious patterns.
- **Experienced (Recommended)** — Fluent with SwiftUI. Concise findings, no definitions.
- **Senior/Expert** — Deep expertise. Terse, file:line only, skip explanations.

**Question 2: "Which audit mode?"**
- **Full (Recommended)** — Full analysis — checks everything and reads findings from other audits you've run
- **Quick** — Quick check — only looks at its own areas, ignores other audit results
- **Report only** — No scanning, just re-grade from existing handoff files

**Experience-adapted explanations for Capstone Radar:**

- **Beginner**: "Capstone Radar is the final check before your app goes to the App Store. It combines results from 4 other audit tools (if you've run them) with its own security, testing, and code quality checks, then gives your whole app a letter grade and tells you if it's safe to ship. Think of it as the building inspector who reviews all the specialist reports plus checks the things no one else covered."

- **Intermediate**: "Capstone Radar aggregates findings from 4 companion skills (data-model-radar, ui-path-radar, roundtrip-radar, ui-enhancer-radar) and adds its own scans for security, test health, code hygiene, dependencies, and build health. It grades all 10 domains on one scale, tracks trends across runs, and makes a ship/no-ship recommendation."

- **Experienced**: "Aggregator + gap filler for the radar family. Consumes 4 companion handoffs, owns 5 grep-reliable domains, unified A-F grading, velocity tracking, risk heatmap, ship/no-ship decision."

- **Senior/Expert**: "5 owned + 4 consumed domains. Velocity. Heatmap. Ship/no-ship."

Store the experience level as `USER_EXPERIENCE` and apply to ALL output for the session.

---

## Plain Language Communication (MANDATORY)

All user-facing prompts must be understandable by someone who has never used this skill before:

1. **Describe grades by what they mean** ("your backup system has a critical gap — 2 data types aren't saved") not just letter grades
2. **Describe the ship/no-ship decision in plain terms** ("safe to release" / "has issues that should be fixed first" / "has critical problems that could lose user data")
3. **Add an "Explain more" option** to every transition `AskUserQuestion`
4. **Define jargon on first use:**
   - "Companion skill" → one of the other audit tools that checks a specific area (data models, navigation, etc.)
   - "Handoff" → a file another audit tool wrote with its findings, which this tool reads
   - "Ship/no-ship" → whether the app is ready to release to the App Store
   - "Domain" → an area of the codebase being graded (e.g., "Data Safety", "Navigation", "Performance")
5. **Exception:** If user selected Senior/Expert experience level, terse references are acceptable

### Final Report Prompt Template

```
## Release Readiness: [SHIP / SHIP WITH CAUTION / DO NOT SHIP]

**Overall Grade: [letter]** — [one plain sentence explaining what this means]

Top issues to address:
1. [plain description] — [urgency]
2. [plain description] — [urgency]

Areas of strength:
- [plain description]

You can:
1. **See the full report** — detailed grades for all [N] areas
2. **Start fixing critical issues** — [one-line description of what gets fixed first]
3. **Explain more** — I'll walk through what each grade means
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

## Terminal Width Check (MANDATORY — run first)

Before ANY output, check terminal width:
```bash
tput cols
```

- **160+ columns** — Use full 8-column Issue Rating Table. Proceed immediately.
- **Under 160 columns** — **Prompt the user first** using `AskUserQuestion`:

  **Question:** "Your terminal is [N] columns wide. The full Issue Rating Table needs 160+ columns. Want to widen it now?"
  - **"I've widened it" (Recommended)** — Re-run `tput cols` to confirm. If tput still reports the old width (terminal resize doesn't always propagate to the shell), trust the user and use full tables anyway.
  - **"Use compact tables"** — Use compact 3-column table with finding text on separate lines below each row:
    ```
    | # | Urgency | Fix Effort |
    |---|---------|------------|
    | 1 | HIGH | Small      |
    |   `activeImporterKind` never assigned — file importer silently drops files |
    |   `EnhancedItemDetailView.swift:93` |
    ```
    Full 8-column table goes to report file only.
  - **"Skip check"** — Use full 8-column table regardless (user accepts wrapping).

  If the user chose compact mode, **after each compact table, print:**

```
Compact table (terminal: [N] cols). Say "show full table" for all 8 columns.
```

If the user later says "show full table", "wide table", or "full ratings", re-render the most recent findings table in full 8-column format regardless of terminal width. Apply to ALL tables in the session.

---

## Step 1: Project Metrics

Collect:

1. **File counts** — `Glob pattern="**/*.swift"` (exclude Tests, Pods, .build, DerivedData)
2. **LOC estimate** — file count x 150, or `wc -l` for accuracy
3. **Architecture** — detect MVVM/MVC/TCA by scanning for ViewModel, Controller, Reducer
4. **Persistence layer** — SwiftData, Core Data, GRDB, UserDefaults, Realm
5. **Test infrastructure** — Swift Testing vs XCTest, unit test count, UI test count
6. **Build number** — read from CLAUDE.md (search for "Current Version" or build number), or from Info.plist
7. **Team detection** — `git shortlog -sn --no-merges | wc -l`. Store as `TEAM_SIZE`.

Ensure output directories exist: `mkdir -p .agents/research .agents/ui-audit`

Print one-line summary:
```
Project: {files} Swift files (~{loc} LOC) | {arch} | {persistence} | Tests: {unit}/{ui} | Build: {number} | Contributors: {count}
```

---

## Step 2: Previous Audit Check

```
Glob pattern=".agents/research/*-capstone-audit.md"
Glob pattern=".agents/research/*-codebase-audit.md"
```

If previous reports exist, parse ALL `GRADES_YAML` HTML comment blocks for velocity tracking. Build an array of dated snapshots sorted by date. Store as `HISTORY`.

---

## Step 3: Companion Handoff Consumption

Read handoff files from all 4 companion skills:

```
Read .agents/ui-audit/data-model-radar-handoff.yaml (if exists)
Read .agents/ui-audit/ui-path-radar-handoff.yaml (if exists)
Read .agents/ui-audit/roundtrip-radar-handoff.yaml (if exists)
Read .agents/ui-audit/ui-enhancer-radar-handoff.yaml (if exists)
```

For each handoff found:
1. Parse `for_capstone_radar.blockers[]` — extract `finding` and `urgency` (CRITICAL or HIGH)
2. **Backward compat:** Also accept `for_release_ready_radar.blockers[]` key
3. Parse companion-specific extras:
   - data-model-radar: `serialization_coverage` (model field coverage stats)
   - roundtrip-radar: `cross_cutting_patterns[]` (patterns affecting multiple workflows)
4. Record which companions were found vs missing

**Score consumed domains:** Start at 95 (generous baseline — companion ran a full audit and only escalated the worst items). Deduct:
- Per CRITICAL blocker: **-15**
- Per HIGH blocker: **-8**
- Floor at 0

**Missing handoffs:** Domain shows "Not audited — run [skill-name] for coverage". Weight redistributed proportionally to audited domains.

Print companion status:
```
Companions: data-model-radar [found/missing] | ui-path-radar [found/missing] | roundtrip-radar [found/missing] | ui-enhancer-radar [found/missing]
```

**Skip this step if mode = Quick.**

### Companion Handoff Quality Assessment

When a companion handoff is found, check its `audit_depth` and `_verified` flags (if present):

- `audit_depth: full` + all targets `_verified: true` → Full credit (start at 95, deduct per blocker)
- `audit_depth: partial` or some targets `_verified: false` → Reduced credit (start at 85, deduct per blocker). Note in report: "Partial audit — [domain] grade is provisional."
- No depth/verified flags (older handoff format) → Treat as partial. Note: "Handoff from older skill version — depth not verified."

**Do not give full credit for unverified companion work.** A handoff that says "backup verified, CSV not checked" should not produce an A for the Model Layer domain. The unverified targets represent unknown risk.

---

## Step 3.5: Risk-Ranking (MANDATORY — before own domain scans)

Before running grep patterns, determine where to go deep vs quick. The default behavior is to run all grep patterns with equal effort — but some domains have more risk than others based on context.

### Check These Signals

**Signal 1: Prior findings.**
Read `HISTORY` from Step 2. If previous audits scored a domain below B, go deep on verification for that domain this time. Also check memory for known issues (e.g., prior session found test health concerns → verify test patterns more carefully).

**Signal 2: Companion handoff gaps.**
If a companion handoff flagged issues that touch an owned domain (e.g., data-model-radar found security-relevant patterns), escalate that owned domain to deep verification.

**Signal 3: Codebase size signals.**
If Step 1 found >500 Swift files, Security Basics grep will produce many candidates. Plan for heavier verification time on that domain. If test-to-source ratio is below 0.2, Test Health needs deep investigation, not just file counting.

### Risk-Ranking Output

Before Step 4, print:

```
Risk Ranking for Own Domains:
  DEEP VERIFY:
    - [domain] (reason: [signal])
    - [domain] (reason: [signal])
  STANDARD:
    - [domain]
    - [domain]
  LOW RISK:
    - [domain]
```

**Deep verify** means: read every grep candidate in context (20+ lines), classify each as CONFIRMED/FALSE_POSITIVE/INTENTIONAL. Don't report counts — report classified findings.

**Standard** means: read a sample of grep candidates (top 5 per pattern), classify those, extrapolate. Label as `(sampled)` in the report.

**Low risk** means: report counts with spot-check of top 3 candidates. Label as `(spot-checked)` in the report.

---

## Step 4: Own Domain Scans

Run grep-based scans for the 5 domains capstone owns. Apply Verification Rule (Step 5) to every hit. **Follow the risk-ranking from Step 3.5** — deep-verify domains go first and get full candidate classification.

### Shared Grep Patterns

**Code Hygiene:**
```
Grep pattern="// TODO|// FIXME|// HACK|// XXX" glob="**/*.swift" output_mode="count"
Grep pattern="as!" glob="**/*.swift"
Grep pattern="try!" glob="**/*.swift"
```
Also check file sizes: `Glob pattern="**/*.swift"` then read line counts for files that appear large. Flag files >1000 lines.

**Test Health:**
```
Grep pattern="import Testing" glob="**/*Test*.swift" output_mode="count"
Grep pattern="import XCTest" glob="**/*Test*.swift" output_mode="count"
Grep pattern="Thread\.sleep|sleep\(" glob="**/*Test*.swift"
Glob pattern="**/*Tests.swift"
Glob pattern="**/*Test.swift"
```
Calculate test-to-source ratio: test files / (total swift files - test files).

**Security Basics:**
```
Grep pattern="(api[_-]?key|secret[_-]?key|password|token)\s*[:=]\s*[\"'][^\"']+[\"']" glob="**/*.swift" -i
Grep pattern="UserDefaults.*\.(password|token|secret|apiKey)" glob="**/*.swift" -i
Grep pattern="http://(?!localhost|127\.0\.0\.1)" glob="**/*.swift"
```

**Dependency Health:**
```bash
stat -f "%Sm" -t "%Y-%m-%d" Package.resolved 2>/dev/null || echo "no Package.resolved"
```
```
Grep pattern="\.exact\(|\.upToNextMajor\(|\.upToNextMinor\(|from:" path="Package.swift" output_mode="content"
```
Count packages in Package.resolved.

**Build Health:**
```bash
find . -name "*.xcscheme" -not -path "*/.build/*" | wc -l
```
```
Grep pattern="targets?:" path="Package.swift" output_mode="content"
```

### Verification Template (MANDATORY for own domain scans)

Before grading each owned domain, produce this table:

```
| Pattern | Grep Run? | Hits | Classified | Confirmed | False Positive | Receipt |
|---------|-----------|------|------------|-----------|----------------|---------|
| TODO/FIXME | ? | | | | | |
| try! | ? | | | | | |
| as! | ? | | | | | |
| hardcoded secrets | ? | | | | | |
| http:// URLs | ? | | | | | |
```

Rules:
- Every pattern in the scan list must appear in this table
- `?` means the grep wasn't run yet — cannot grade until all are filled
- Hits ≠ Findings. Every hit must be classified (Confirmed / False Positive / Intentional)
- The grade comes from Confirmed count, not Hits count
- If Hits > 0 but Classified = 0, the domain was not actually audited

### Per-Domain Scoring

Start at **100 points**. Deduct per CONFIRMED finding:

| Severity | HIGH Conf | MED Conf | LOW Conf |
|----------|-----------|----------|----------|
| CRITICAL | -15 | -10 | -3 |
| HIGH | -8 | -5 | -1 |
| MEDIUM | -3 | -2 | 0 |
| LOW | -1 | -1 | 0 |

---

## Step 5: Verification Rule

Grep patterns produce candidates, NOT confirmed issues. Before reporting:

1. **Read the flagged file** — minimum 20 lines of context
2. **Check structural context** — pattern may be safe in its actual scope
3. **Classify:** CONFIRMED, FALSE_POSITIVE, or INTENTIONAL
4. **Never report grep counts as issue counts** — classify each hit
5. **Only CONFIRMED findings appear in the report**

**Common false positives:**
- `try!` in test setup code — acceptable in tests
- `http://` in XML namespaces or comments — not an endpoint
- `sleep()` in test helpers for async settling — may be intentional
- `TODO` markers that reference completed work — stale comments
- `as!` in exhaustive switch cases — compiler-guaranteed safe
- Hardcoded "password" in UI label strings — not a credential

---

## Step 6: Cross-Domain Correlation

### 6.1 Risk Heatmap by File

Collect ALL file paths from ALL findings (own 5 domains + companion handoffs). Count domain appearances per file. Report files appearing in **3+ domains**:

```
Risk Heatmap — Files with findings in 3+ domains:
  {file1}  — {domain1}, {domain2}, {domain3} ({N} domains)
  {file2}  — {domain1}, {domain2}, {domain3} ({N} domains)

These {N} files account for {X}% of all findings.
```

### 6.2 Team Enrichment

If `TEAM_SIZE` > 1:
- For each heatmap file, run `git log --format="%an" --since="30 days ago" -- {file} | sort -u` to find recent contributors
- Add ownership info: `{file} — {N} domains, {M} contributors this month, {owner or "no clear owner"}`

### 6.3 Cross-Cutting Patterns

If roundtrip-radar handoff includes `cross_cutting_patterns[]`, incorporate them. Flag patterns that affect 3+ workflows.

---

## Step 7: Grading

### Domain Weights

| Domain | Source | Weight |
|--------|--------|--------|
| Code Hygiene | Own scan | 10% |
| Test Health | Own scan | 15% |
| Security Basics | Own scan | 15% |
| Dependency Health | Own scan | 5% |
| Build Health | Own scan | 5% |
| Model Layer | data-model-radar handoff | 10% |
| Navigation/UX | ui-path-radar handoff | 10% |
| Data Safety | roundtrip-radar handoff | 15% |
| Visual Quality | ui-enhancer-radar handoff | 10% |
| Cross-Domain Risk | Correlation analysis | 5% |

**Weight redistribution:** When domains are unaudited (missing companion handoff), divide their total weight proportionally among audited domains. Example: if Data Safety (15%) and Visual Quality (10%) are missing, remaining 75% becomes 100%. Code Hygiene's 10% becomes 10/75 = 13.3%.

### Grade Honesty Rules

**1. Label the scope.** The overall grade line must state how many domains were audited:
```
Overall: B+ [87] (6/10 domains audited — 4 companion domains missing)
```
Not just `Overall: B+ [87]`.

**2. Label the depth.** Each owned domain grade must state its verification depth:
```
Code Hygiene: A [96] (deep-verified — all candidates classified)
Test Health: A [94] (sampled — top 5 per pattern classified)
Build Health: A+ [100] (spot-checked — 3 candidates verified)
```

**3. Distinguish hygiene from quality.** The 5 owned domains are surface hygiene checks. They catch "did you leave a hardcoded password" but NOT "does the backup restore lose 7 fields." When companion domains are missing, add this disclaimer:
```
Note: This grade covers hygiene domains only. Logic bugs, data safety,
navigation issues, and visual quality are not assessed without companion
skill handoffs. Prior audits found [N] bugs in unaudited domains.
```
Check `HISTORY` for the count of prior findings in unaudited domains. If no history, say "unknown number of bugs may exist."

**4. Partial companion credit.** When a companion handoff has `audit_depth: partial` or `_verified: false` on some targets, the consumed domain grade is provisional. Mark it:
```
Model Layer: B+ [88] (provisional — companion audit was partial)
```

### Cross-Domain Risk Scoring

Start at 100. Deduct:
- **-5** per file appearing in 3+ domains (from risk heatmap)
- **-3** per cross-cutting pattern affecting 3+ workflows
- **-5** per correlated domain pair (e.g., security finding + test gap in same file)

### Grade Scale

| Grade | Score | Grade | Score | Grade | Score |
|-------|-------|-------|-------|-------|-------|
| A+ | 97-100 | B+ | 87-89 | C+ | 77-79 |
| A | 93-96 | B | 83-86 | C | 73-76 |
| A- | 90-92 | B- | 80-82 | C- | 70-72 |
| | | D+ | 67-69 | D | 63-66 |
| | | D- | 60-62 | F | 0-59 |
| **I** | **n/a** | | | | |

### Incomplete (I) Grade

Overrides the numeric score for ship-blocking, irreversible risks:

| Trigger | Source |
|---------|--------|
| Hardcoded production credentials | Security Basics (own) |
| Unencrypted secrets in UserDefaults/plist | Security Basics (own) |
| CRITICAL blocker from any companion | Companion handoff |
| Confirmed data loss/corruption path | Companion or own |

If ANY domain is Incomplete, overall grade is `I (Incomplete)`.

### Overall Grade

Weighted average using domain weights (after redistribution), mapped to grade scale.

---

## Step 8: Velocity + Regressions

### Velocity Tracking

If `HISTORY` has previous snapshots, compare current grades to each:

```
Velocity — Grade Over Time:
  Code Hygiene:     C  -> B- -> B+  (3 audits, improving)
  Security Basics:  A  -> A  -> A   (stable)
  Test Health:      C  -> C  -> C+  (3 audits, slowly improving)

  Overall: B -> B+ (trending up)
```

If 3+ data points, add projection: "At this rate, you'll hit overall A- by [estimate]."

### Build-Over-Build Comparison

If current and previous audits have build numbers:

```
Build {prev} -> Build {current}:
  New issues: {N}
  Resolved: {N}
  Grade: {prev_grade} -> {current_grade}
```

### Celebrate Improvements

Diff current vs previous audit. Highlight domains that improved by >=1 letter grade OR >=10 points:

```
Improvements since last audit:
  Code Hygiene: B- -> A- (resolved 8 TODO markers)
  Test Health: C -> B- (added 12 test files)
  Data Safety: D+ -> B (roundtrip-radar found and fixed 6 data loss bugs)
```

Always show improvements BEFORE findings. Positive reinforcement matters.

### Regressions Tied to Git History

For each finding NOT present in the previous audit:

```
REGRESSION: {finding description}
  File: {file:line}
  Introduced: commit {hash} "{message}" ({date})
```

If `TEAM_SIZE` > 1, also show author and reviewer (if from a PR):
```
  Author: {name}
  PR: #{number} (if detectable from commit message)
```

Run `git log -1 --format="%H %s %an %ai" -- {file}` for each regression file.

---

## Step 9: Ship Recommendation

| Recommendation | Criteria |
|----------------|----------|
| **SHIP** | No CRITICALs, <=2 HIGHs, overall B- or above, no Incompletes |
| **CONDITIONAL SHIP** | No CRITICALs, 3-5 HIGHs, overall C+ or above, no Incompletes |
| **DO NOT SHIP** | Any Incomplete, OR any CRITICAL, OR >5 HIGHs, OR overall C or below |

Any Incomplete = automatic **DO NOT SHIP** — no exceptions.

Format:

```
## Ship Recommendation: [SHIP / CONDITIONAL SHIP / DO NOT SHIP]

### Blockers (must fix before release)
1. [Issue] — LOE: Xh | File: path:line

### Advisories (fix soon after release)
1. [Issue] — LOE: Xh | File: path:line

**Estimated total blocker LOE:** X hours
```

### Companion Coverage Notice

If any companion skills were not run:

```
Coverage gaps — these domains were NOT audited:
  Model Layer: Run data-model-radar for coverage
  Data Safety: Run roundtrip-radar for coverage

Ship recommendation is based on {N}/10 domains. Run missing companions for full confidence.
```

---

## Step 10: Output + Follow-up

### Write Report

Write to `.agents/research/YYYY-MM-DD-capstone-audit.md`. Write sections as generated.

**Report sections:**

1. **Header** — date, build number, mode, companions found/missing
2. **Project metrics** — files, LOC, architecture, persistence, tests, contributors
3. **Grade summary line** — `**Overall: B+** (CodeHygiene A- [91] | Security A [95] | ...)`
4. **GRADES_YAML** — machine-readable in HTML comment:

```html
<!-- GRADES_YAML
build: 25
date: 2026-03-23
overall: 87
code_hygiene: 92
test_health: 78
security_basics: 95
dependency_health: 88
build_health: 90
model_layer: 85
navigation_ux: null
data_safety: 72
visual_quality: null
cross_domain_risk: 80
-->
```

`null` = domain not audited. Previous reports with old 13-category format are still parseable for velocity — map old domain names where possible, ignore the rest.

5. **Improvements** (if previous audit exists) — celebrate what got better
6. **Velocity chart** (if 2+ previous audits) — grade trends per domain
7. **Ship recommendation** — SHIP / CONDITIONAL / DO NOT SHIP with blockers
8. **Companion coverage notice** (if any missing)
9. **Risk heatmap** — files in 3+ domains
10. **Per-domain sections** — grade, score trail, strengths, CONFIRMED issues with Issue Rating Tables
11. **Regressions** — new issues traced to commits
12. **Test coverage gaps** — untested source files, especially those appearing in findings
13. **Top 10 prioritized issues** — composite: `(Urgency x 3) + (Risk x 2) + (ROI x 2) + (1/LOE)`
14. **Next steps** — which companion radars to run for unaudited domains

### Test Coverage Gap Analysis

Map test files against source files:

1. Glob `**/*Tests.swift` and `**/*Test.swift`
2. Extract tested type names from test file names (e.g., `ItemViewModelTests.swift` → `ItemViewModel`)
3. Compare against source files
4. Flag untested files that ALSO appear in findings (high risk + no tests = worst combination)

```
Test Coverage Gaps:
  {type} ({N} files, 0 tests) — appears in {domain} findings
  {type} ({N} files, 0 tests) — HIGH risk (companion flagged data issues)
```

### Issue Rating Format

For every finding in per-domain sections:

| # | Finding | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|---------|-----------|--------------|-----|--------------|------------|

**Blast Radius:** Always include the number of files the fix touches (e.g., `3 files`, `1 file`). Count by grepping for callers/references before rating.

### Indicator Scale

| Indicator | General meaning | ROI meaning |
|-----------|----------------|-------------|
| CRITICAL | Critical / high concern | Poor return |
| HIGH | High / notable | Marginal return |
| MEDIUM | Medium / moderate | Good return |
| LOW | Low / negligible | — |
| PASS | Pass / positive | Excellent return |

### Time-Boxed Fix List

After the ship decision, ask: "How much time do you have for fixes?"

Sort findings by (grade impact / fix effort). Output a prioritized list that fits the time budget:

```
You have {N} hours. Here are the {M} fixes that move your grade the most:
1. {fix} ({domain} {old_grade} -> {new_grade}) — {effort}, {files} file(s)
2. {fix} ({domain} {old_grade} -> {new_grade}) — {effort}, {files} file(s)
...
```

**Every fix includes tests.** When listing fix effort, include test writing time. A "Small" fix that needs tests is "Small + tests." When the user applies fixes (directly or via companion skills), verify tests were added. Untested fixes are unverified fixes.

### Write Handoff

Write `.agents/ui-audit/capstone-radar-handoff.yaml`:

```yaml
source: capstone-radar
date: <ISO 8601>
project: <project name>
build: <build number>
recommendation: "ship" | "conditional" | "no-ship"
overall_grade: "<letter grade>"
overall_score: <numeric>

for_roundtrip_radar:
  priority_workflows:
    - domain: "<e.g., Data Safety>"
      grade: "<letter>"
      reason: "<why this domain scored low>"

for_ui_path_radar:
  priority_areas:
    - domain: "<e.g., Navigation/UX>"
      grade: "<letter>"
      reason: "<specific issues found>"

for_ui_enhancer_radar:
  priority_views:
    - domain: "<e.g., Visual Quality>"
      grade: "<letter>"
      reason: "<specific gaps>"

for_data_model_radar:
  priority_models:
    - domain: "<e.g., Model Layer>"
      grade: "<letter>"
      reason: "<specific model issues>"
```

**Automatic:** This file is always written so other audit skills can pick up where this one left off. No user action needed.

### Follow-up Options

After presenting the report, offer:

- **Run missing companions** — list which companion radars would improve coverage
- **Plan blockers only** — create implementation plan for CRITICAL + HIGH items
- **Plan all items** — comprehensive roadmap
- **No plan needed**

---

## Permission Modes

### Normal Mode
- Read any file without asking.
- Write report to `.agents/research/` without asking.
- Run bash commands (git log, stat, find) without asking.

### Hands-Free Mode
**Guarantees no blocking prompts.** Only uses Read, Grep, Glob. No Bash, no Edit, no Write. When complete:
```
Hands-free audit complete. Analysis ready.
  Deferred: Report file writing, git history analysis.
  Reply to continue with supervised steps.
```

---

## Experience-Level Adaptation

Adjust ALL output (grades, findings, recommendations, domain summaries) based on `USER_EXPERIENCE`:

- **Beginner**: Explain what each grade means and why it matters. Define terms. Use analogies for severity.
- **Intermediate**: Standard terminology, explain non-obvious findings.
- **Experienced** (default): Concise grades + key findings. No definitions. Focus on what needs action.
- **Senior/Expert**: Grades + file:line references only. Skip domain descriptions. Just the data.

---

## Step Progress Banner (CRITICAL — BLOCKING requirement)

**After EVERY step and EVERY commit, your NEXT output MUST be the progress banner followed by the next-step `AskUserQuestion`. Do not output anything else first. Do not leave a blank prompt.**

After completing each step, **always** print this banner:

```
Step [N] of 10 complete: [step name]

Next: Step [N+1] — [step name] (~[time estimate])
```

Step time estimates:
| Step | Name | Est. Time |
|------|------|-----------|
| 1 | Project Metrics | ~1 min |
| 2 | Previous Audit Check | ~1 min |
| 3 | Companion Handoff Consumption | ~1 min |
| 3.5 | Risk-Ranking | ~1 min |
| 4 | Own Domain Scans | ~3-5 min |
| 5 | Verification | ~2-5 min |
| 6 | Cross-Domain Correlation | ~2 min |
| 7 | Grading | ~1 min |
| 8 | Velocity + Regressions | ~2 min |
| 9 | Ship Recommendation | ~1 min |
| 10 | Output + Follow-up | ~3 min |

---

## Companion Skills (5-Skill Family)

| Skill | Unique Role |
|-------|-------------|
| data-model-radar | Are your @Model definitions correct? |
| ui-path-radar | Can users reach every feature? |
| roundtrip-radar | Does data survive the full journey? |
| ui-enhancer-radar | Does it look and feel right? |
| **capstone-radar** (this skill) | Can you ship? Unified grade + decision. |

**Recommended audit order:**
1. data-model-radar (foundation — model layer)
2. ui-path-radar (navigation paths)
3. roundtrip-radar (data flows)
4. ui-enhancer-radar (visual quality)
5. capstone-radar (unified grade + ship decision)

Capstone is both the **entry point** ("what should I audit?") and the **exit point** ("can I ship?"). The other radars are the deep work in between.

---

## REMINDER (End-of-File — Survives Context Compaction)

**CRITICAL:** After EVERY step, EVERY commit, and EVERY domain transition:
1. Print the progress banner (step-level)
2. Immediately `AskUserQuestion` for the next step
3. NEVER leave a blank prompt

This reminder is placed at the end of the file because context compaction tends to preserve the beginning and end. If you are unsure whether to print the banner, **print it**.

**GRADE HONESTY:** Every overall grade must state N/10 domains audited. Every owned domain grade must state verification depth (deep/sampled/spot-checked). When companions are missing, add the hygiene-only disclaimer. Do not produce a clean A+ from surface grep patterns — that grade disguises the unknown risk in unaudited companion domains.

**RISK-RANKING:** Do not start Step 4 without producing the risk-ranking table from Step 3.5. Verify riskiest domains first, not easiest first.
