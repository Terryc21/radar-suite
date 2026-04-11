---
name: radar-suite-axis-classification
description: 'Shared axis classification framework for all radar-suite skills. Every finding must be classified as axis_1 (bug), axis_2 (scatter), or axis_3 (dead/smelly) before emission, with mandatory coaching fields and file:line citations to existing patterns in the audited codebase. Triggers: invoked by every radar before emitting findings.'
version: 2.0.0  # unified plugin version as of 2026-04-10 (skill is new in this release)
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob]
inherits: radar-suite-core.md
metadata:
  tier: foundation
  category: framework
---

# Radar Suite — Axis Classification Framework

> Every radar in the suite invokes this skill before emitting findings. This is the verification gate and the coaching engine. Findings that do not pass the gate are rejected.

---

## What This Skill Does

Three things, in order:

1. **Classify** every candidate finding on three axes: does it break user-visible behavior, is it correct code that is hard to read, or is it dead or unjustified code?
2. **Verify** the classification against a checklist of concrete evidence checks before the finding can be emitted.
3. **Coach** with a mandatory `better_approach` section that cites a real file:line pattern from the audited codebase (not generic advice).

Any radar can invoke this skill. The skill itself does not scan code directly — it provides the framework, the checklist, and the schema gate that each radar uses before writing its handoff YAML.

---

## The Three Axes

### axis_1 — Real Bug

Code does the wrong thing from the user's perspective. The behavior needs to change.

**Examples:**
- CSV import freezes the main thread on large files
- Sheet with unsaved changes discards on dismiss with no confirmation
- Platform-branch parity gap: iOS has a dismiss button, macOS does not
- Silent error swallowing with no user feedback

**Default audience:** `end_user`
**Severity:** 4-tier scale (critical, high, medium, low)
**Grade impact:** Yes — counts toward fix-before-shipping grade

### axis_2 — Scatter (Correct but Hard to Read)

Code runs correctly but is structured in a way that makes the next developer's job harder. The fix is reorganization, not behavior change. **No user-visible change after the fix.**

**Examples:**
- Empty-state handlers for the same view scattered 500 lines apart in one file
- Duplicated `#if os(iOS)` / `#else` forks for the same UI concern across multiple files
- State machine implicit in boolean flags rather than an enum
- Managers referenced as singletons without a protocol abstraction when other managers in the codebase already have one

**Default audience:** `code_reader`
**Severity:** Hygiene scale (urgent, rolling, backlog)
**Grade impact:** No — lives in the hygiene backlog, does not affect ship grade

### axis_3 — Dead Code or Smelly

Either unreachable (dead code) or reachable but not clearly justified (smelly). The fix is delete, document, or interrogate.

**Two sub-labels:**

- **axis_3_dead_code** — Unreachable branch. Verified by reachability trace. Cannot be hit from any production call site.
- **axis_3_smelly** — Reachable but poorly justified. Defensive guard with no documented failure mode. Error path that logs but cannot actually fire. Field defined in model but not written or read anywhere.

**Examples:**
- Empty-state branch in a view that is unreachable because an upstream filter removes the empty case
- `guard let` on a value that is constructed two lines above and cannot be nil
- Model field that has neither write sites nor read sites in the wired-up app (as opposed to a wiring bug, which is axis_1)

**Default audience:** `future_maintainer`
**Severity:** Hygiene scale
**Grade impact:** No — lives in the hygiene backlog

---

## Verification Checklist (MANDATORY — before every finding emission)

A radar MUST run these checks before assigning an axis and emitting the finding. Each check that was run is logged in the finding's `verification_log` field. A finding without a `verification_log` is rejected by the schema gate.

### Check 1: Reachability Trace (required for axis_1 dead-end claims)

**Rule:** Before emitting "this branch is a user-facing dead end," trace the branch back to a production call site.

**How:**
1. Identify the file and line of the flagged branch
2. Grep for the enclosing function / view struct name across the codebase
3. Walk up call sites at least 2 levels (who calls this view, who navigates here)
4. If no production call site reaches this branch, **reclassify as axis_3_dead_code** and emit with the reclassification logged

**Log entry:**
```yaml
- check: reachability_trace
  result: "reached from MyProductsView.swift:915 via galleryContent(items) — reachable"
  # or:
  result: "no production call site found; reclassified to axis_3_dead_code"
```

### Check 2: Whole-File Scan (required for "missing handler" claims)

**Rule:** Before claiming a state / case / branch is unhandled, scan the ENTIRE file (not just the flagged region) for a handler.

**How:**
1. Read the full file where the finding was detected (or at minimum, grep the whole file for the case name, enum value, or state flag)
2. If a handler exists elsewhere in the same file, **reclassify as axis_2_scatter** (the handler exists but is scattered)
3. The original finding is still valid, but its fix is reorganization, not adding missing logic

**Log entry:**
```yaml
- check: whole_file_scan
  result: "scanned 1169 lines; no other handlers for .empty case found — finding stands as axis_1"
  # or:
  result: "scanned 1169 lines; handler at LegacyWishesView.swift:847; reclassified to axis_2_scatter"
```

### Check 3: Branch Enumeration (required for any `#if` claim)

**Rule:** Before classifying a `#if os(iOS)` (or any conditional compilation block) as iOS-only or platform-broken, READ both the `#if` and the `#else` branches. Do not drop the `#else`.

**How:**
1. When a flagged pattern is inside a `#if` block, read the full block including all `#elseif` and `#else` clauses
2. Verify the claim against every branch, not just the one you noticed first
3. If the `#else` branch handles the case and the radar missed it, the finding is a false positive

**Log entry:**
```yaml
- check: branch_enumeration
  result: "#if os(iOS) block at lines 102-118 has #else at 112-116 that handles the macOS case; finding retracted"
  # or:
  result: "#if os(iOS) block at lines 102-118 has no #else; iOS-only code confirmed"
```

### Check 4: Pattern Citation Lookup (required for every better_approach)

**Rule:** The `better_approach` coaching field MUST cite an existing pattern in the SAME codebase being audited. Grep for the pattern shape before writing the recommendation. Generic advice ("consider using a protocol abstraction") without a citation is rejected.

**How:**
1. When writing a `better_approach`, identify the pattern shape (protocol abstraction, async bridge, typed navigation enum, etc.)
2. Grep the audited codebase for that shape
3. If a match exists, cite it by file:line in the `better_approach` body
4. If no match exists, fall back to an anonymized shape reference from `coaching-examples-generic.md` AND note explicitly "no existing pattern found in this codebase"

**Log entry:**
```yaml
- check: pattern_citation_lookup
  result: "found similar pattern at Sources/Protocols/CloudSyncManaging.swift:14 (protocol + @MainActor class)"
  # or:
  result: "no existing protocol abstraction pattern found in codebase; using generic template"
```

### Check 5: Source Root Introspection (lightweight on single-root projects)

**Rule:** Before claiming a field / type / symbol is unused, enumerate the project's actual source roots. Do not hardcode `Sources/` as the only root.

**How:**
1. Read `project.pbxproj` (Xcode project) or `Package.swift` (SPM) to get the actual source root list
2. If only one source root exists, this check collapses to "grep the whole root" and is cheap
3. If multiple source roots exist (e.g., `Sources/Views/` AND `Sources/Features/` AND `Sources/Shared/`), grep all of them before emitting an "unused" finding

**Log entry:**
```yaml
- check: source_root_introspection
  source_roots: ["Sources/"]
  result: "single source root confirmed; full-root grep ran"
```

---

## Coaching Schema (MANDATORY on every finding)

Every finding MUST populate these fields. A finding missing any mandatory field is rejected by the schema gate.

```yaml
findings:
  - id: [unique-hash]
    # Axis classification (REQUIRED)
    axis: axis_1_bug | axis_2_scatter | axis_3_dead_code | axis_3_smelly

    # Audience (REQUIRED — defaults by axis but may be overridden per finding)
    # axis_1 default: end_user
    # axis_2 default: code_reader
    # axis_3 default: future_maintainer
    before_after_experience:
      audience: end_user | code_reader | future_maintainer
      before: "Concrete description of the experience today from the named audience's POV"
      after: "Concrete description after the fix, same audience"

    # Coaching fields (ALL REQUIRED, including for axis_2 and axis_3)
    current_approach: |
      How the code is structured today. Specific file:line references.
      Describe the shape, not just the location.
    suggested_fix: |
      The minimum change that addresses the immediate finding.
      For axis_1: the bug fix. For axis_2: the reorganization. For axis_3: delete or document.
    better_approach: |
      How a senior reviewer would write this area of the codebase beyond the minimum fix.
      MUST cite an existing pattern in the user's codebase by file:line.
      Format: "Follow the pattern at [File.swift:NN] which [describes what the pattern does]."
      A better_approach without a pattern_citation_lookup entry in verification_log is REJECTED.
    better_approach_tradeoffs: |
      Honest tradeoffs. When the better approach is overkill. When it is the right call.
      At least one sentence of each: when to apply, when not to apply.

    # Verification log (REQUIRED — at minimum, pattern_citation_lookup)
    verification_log:
      - check: reachability_trace | whole_file_scan | branch_enumeration | pattern_citation_lookup | source_root_introspection
        result: "concrete outcome of the check"

    # Existing fields (unchanged from radar-suite-core.md schema)
    description: [plain language]
    confidence: verified|probable|possible
    urgency: critical|high|medium|low
    status: open|fixed|deferred|accepted
    file: [path]
    line: [number]
    file_last_modified: [ISO-8601]
    group_hint: [category for batch operations]
    pattern_fingerprint: [normalized anti-pattern name]
    grep_pattern: [regex]
    exclusion_pattern: [regex]
```

### Schema Gate Rules

A finding is **REJECTED** (not emitted, returned to the radar for correction) if any of these apply:

1. `axis` field is missing or not one of the four valid values
2. `before_after_experience` is missing or any sub-field is empty
3. `current_approach`, `suggested_fix`, or `better_approach` is missing or empty
4. `better_approach` does not contain a file:line citation (format: `[A-Za-z0-9_/+.-]+\.swift:\d+`)
5. `verification_log` is missing or does not contain a `pattern_citation_lookup` entry
6. `better_approach_tradeoffs` is missing or does not contain both a "when to apply" and a "when not to apply" sentence

**When a finding is rejected:** the radar must either (a) fix the finding by running the missing checks and populating the missing fields, or (b) downgrade the finding's confidence to `possible` and explicitly mark it as "coaching incomplete" in the handoff so it is visible as a low-confidence entry rather than dropped silently.

---

## Severity and Grade Mapping

### axis_1 uses the existing 4-tier severity scale

- 🔴 **CRITICAL** — pre-launch blocker OR data loss / crash risk
- 🟡 **HIGH** — user-visible or stability risk; fix before release
- 🟢 **MEDIUM** — real issue; acceptable to schedule
- ⚪ **LOW** — nice-to-have; minimal impact

**Grade impact:** CRITICAL findings cap grade at C. HIGH findings cap at B+. (Same rules as `radar-suite-core.md`.)

### axis_2 and axis_3 use the hygiene scale

- **urgent_hygiene** — will bite within 1-2 development sessions (scattered state in a file about to be refactored)
- **rolling_hygiene** — fix opportunistically when touching the file (most axis_2 scatter)
- **backlog_hygiene** — safe to defer indefinitely (stable dead code with documented reason)

**Grade impact:** NONE. Hygiene findings do not count toward the A-F grade. They live in a separate capstone section.

### Two scales coexist in the same handoff

A radar may emit both axis_1 findings (severity: `critical`) and axis_2 findings (severity: `rolling_hygiene`) in the same handoff YAML. The capstone reader splits them by axis, not by severity value.

---

## Audience Tagging

Every finding declares its audience. The audience is who experiences the before/after change.

| Axis | Default Audience | Override When |
|---|---|---|
| axis_1 | `end_user` | The "bug" is a developer ergonomic issue (e.g., crash on a debug-only code path) — override to `code_reader` |
| axis_2 | `code_reader` | The scatter is so bad it causes observable lag from bundle size or view recomputation — override to `end_user` |
| axis_3 | `future_maintainer` | The smelly code is a hygiene issue a code reviewer would catch in the next PR — override to `code_reader` |

**Why explicit audience matters:** axis_2 and axis_3 findings have no natural `end_user` experience. Forcing every finding to phrase before/after for the end user makes axis_2/3 findings hand-wavy. Naming the correct audience keeps the coaching grounded.

**Writing the before/after per audience:**

- **`end_user`** — describe what the app does today vs after (from a user's perspective, not developer's)
- **`code_reader`** — describe what the code looks like today vs after (from a developer reading the file for the first time)
- **`future_maintainer`** — describe what a developer inheriting this code in 6 months would think / trip over

---

## Coaching Examples Loader

Before writing `better_approach` for any finding, the radar loads coaching examples in this order:

1. **Check the target project for `.radar-suite/project.yaml`**
2. **Read the `coaching_examples:` array** — e.g., `[stuffolio, generic]` or `[generic]`
3. **Load each named file** in order from `skills/radar-suite-axis-classification/coaching-examples-<name>.md`
4. **First citation match wins.** When deciding which pattern shape to cite, prefer the first loaded file that has a matching example. The Stuffolio overlay loaded first means Stuffolio-specific citations take priority when auditing Stuffolio; generic falls back when a pattern has no Stuffolio example.

**Example `.radar-suite/project.yaml` for Stuffolio:**
```yaml
coaching_examples:
  - stuffolio
  - generic
```

**Example for a new project with no overlay:**
```yaml
coaching_examples:
  - generic
```

**No project.yaml means:** load generic only.

**Pattern match precedence:** if the Stuffolio overlay has an example for "protocol abstraction" and the generic file also has one, the Stuffolio example is used. If Stuffolio does NOT have an example for "typed navigation destination enum" but generic does, the generic example is used.

---

## Checks Performed Reporting (replaces silent absence of failure)

Every radar must include a `checks_performed` block in its handoff YAML. This makes "no findings in this category" distinguishable from "this category was not scanned."

```yaml
checks_performed:
  source_roots_scanned: ["Sources/"]
  files_scanned: 588
  patterns_checked:
    - reachability_trace
    - whole_file_scan
    - branch_enumeration
    - pattern_citation_lookup
    - source_root_introspection
  patterns_not_run: []  # empty if all checks ran
  reason_for_skipped_checks: null
```

**If a check is deliberately skipped:** document why.
```yaml
patterns_not_run: ["branch_enumeration"]
reason_for_skipped_checks: "no #if conditional compilation blocks found in scope"
```

---

## Invocation Protocol (how a radar calls this skill)

This skill does not run as a standalone orchestrator. Each radar invokes it via the following protocol:

### Before emitting any finding:

1. **Classify.** Assign an axis label based on the three axes defined above.
2. **Run required checks.** For the axis chosen, run the applicable checks from the verification checklist. Minimum always-required check: `pattern_citation_lookup`.
3. **Load coaching examples.** Read `.radar-suite/project.yaml` from the target repo and load the example files.
4. **Write coaching.** Populate `current_approach`, `suggested_fix`, `better_approach` (with citation), `better_approach_tradeoffs`.
5. **Validate against schema gate.** Self-check the finding against the schema gate rules above. If any gate rule fails, loop back to step 2 and fill the missing data.
6. **Emit.** Write the finding to the radar's handoff YAML with full axis + coaching fields populated.

### Before finalizing the handoff:

1. Add the `checks_performed` block summarizing what the radar actually scanned.
2. Write a top-level `axis_summary` counting findings by axis:
   ```yaml
   axis_summary:
     axis_1_bug: 12
     axis_2_scatter: 7
     axis_3_dead_code: 2
     axis_3_smelly: 4
     rejected_no_citation: 3  # findings dropped at the gate for missing coaching
   ```
3. The `rejected_no_citation` count is visible so capstone knows the radar had candidate findings it could not coach.

---

## What This Skill Does NOT Do

- **It does not scan code directly.** Each radar scans; this skill provides the framework.
- **It does not replace existing finding categories.** ui-path-radar's 30 issue categories still apply; each category gets an axis label on top.
- **It does not block findings from being emitted indefinitely.** If the gate rejects a finding, the radar can downgrade confidence and emit it as "coaching incomplete" rather than drop it.
- **It does not change the 8-column rating table.** axis_1 findings still render with the existing rating table format. Hygiene findings use a simpler format (see capstone-radar integration).

---

## Reference Files

- **`coaching-examples-generic.md`** — Anonymized worked examples for all 3 axes. Ships with the skill. Default fallback.
- **`coaching-examples-stuffolio.md`** — Stuffolio-specific overlay with real file:line citations from the Stuffolio codebase. Loaded first when auditing Stuffolio.

Future projects with their own overlays: create `coaching-examples-<projectname>.md` in this skill's directory and reference it in the target project's `.radar-suite/project.yaml`.
