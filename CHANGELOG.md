# Changelog

All notable changes to the Radar Suite skills are documented here.

Format: [skill-name vX.Y.Z] for legacy per-skill entries, [plugin vX.Y.Z] for unified plugin entries as of v2.0.

---

## 2026-04-11 — [plugin v2.1.0] 3-tier depth model

### What shipped

**3-tier invocation model.** Users now choose audit depth at invocation time:

- **Tier 1 (Quick):** Single skill via direct command. Own rating table, no pipeline. The new default (reverses the implicit full-pipeline default from v2.0).
- **Tier 2 (Targeted):** 2-3 skills via `--skills dmr,tbr,rtr` (manual) or `--changed` (auto-select from git diff). Cross-skill handoffs within the subset. No capstone unless all 5 ran.
- **Tier 3 (Full):** All 6 skills + capstone via `--full`. Current v2.0 behavior plus 6 UX enhancements.

**Auto-selection heuristic (`--changed`).** Maps git diff file patterns to skills (e.g., `Sources/Models/*.swift` triggers data-model-radar). If 4+ skills are triggered, suggests upgrading to Tier 3.

**6 pipeline UX enhancements** (Tier 3 only):
1. Pipeline-level progress banner at every skill transition
2. Per-skill mini rating tables marked "PRELIMINARY"
3. Audit-only mode statement at start and transitions
4. Per-phase duration estimates in pipeline banners
5. Pre-capstone summary (consolidated findings table before capstone grades)
6. Finding IDs always include `short_title` in parentheses

**`short_title` field** added to finding schema (max 8 words, required on all findings). Legacy findings without `short_title` fall back to first 8 words of `description`.

**Skill abbreviations:** `dmr` (data-model), `tbr` (time-bomb), `rtr` (roundtrip), `upr` (ui-path), `uer` (ui-enhancer).

**Capstone tier awareness:** Capstone adapts messaging based on active tier. Tier 3 treats missing handoffs as errors. Tier 2 marks excluded skills as "not in scope" and scopes the grade to audited domains.

### Files changed

- `radar-suite-core.md` (+ 7 skill directory copies): Tier System, Auto-Selection Heuristic, Pipeline UX Enhancements, `short_title` field in finding schema
- `skills/radar-suite/SKILL.md`: Tier routing (`--skills`, `--changed`, `--full`, `--scope`), restructured interactive menu, Tier 2 routing logic, auto-selection logic
- `skills/capstone-radar/SKILL.md`: Tier Awareness section, pre-capstone summary emission, tier-aware handoff consumption
- `skills/{data-model,time-bomb,roundtrip,ui-path,ui-enhancer}-radar/SKILL.md`: Pipeline mode behavior, `short_title` requirement, updated shared patterns references
- `README.md`: v2.1 What's New, tier-aware Session Strategy
- All SKILL.md frontmatter bumped to `version: 2.1.0`

---

## 2026-04-10 (later in the day) — [plugin v2.0.0] Axis classification framework SHIPPED + plugin distribution SHIPPED

This is the v2.0 unified-plugin release. Two major changes ship together.

### What shipped

**1. Claude Code plugin distribution.**

- `.claude-plugin/plugin.json` is the new single source of truth for what ships. It declares all 8 skills as an explicit array (not directory enumeration). See the file for the full manifest.
- `.claude-plugin/marketplace.json` declares radar-suite as its own single-plugin marketplace. Users add it with `/plugin marketplace add Terryc21/radar-suite`, then install with `/plugin install radar-suite@radar-suite`.
- `.claude-plugin/verify-manifest.sh` is a drift guardrail. It diffs the plugin.json `skills` array against `ls skills/` and fails non-zero if they disagree. The 17-day silent install bug (same day, earlier entry below) becomes structurally impossible as long as this script runs in CI or pre-commit.
- `install.sh` is kept as a fallback with a deprecation banner. It now runs verify-manifest.sh at install time and warns on drift. Its internal `SKILLS=()` array was updated to include `radar-suite-axis-classification` (the new 8th skill).
- All skill SKILL.md frontmatter `version:` fields now read `2.0.0` (unified plugin version). Previous per-skill versions are preserved as inline comments (`# was 3.3.0 per-skill`) so history is not lost. Future changelog entries will land under the plugin version, not per skill.

**2. Axis classification framework.**

Every finding from every radar is now classified on three axes before it can be emitted:

| Axis | Label | Meaning | Grade impact |
|---|---|---|---|
| **axis_1_bug** | Real bug | User-facing defect that needs a behavior change | Counts toward A-F grade |
| **axis_2_scatter** | Scatter | Correct code, bad structure, reorganize only | Hygiene backlog — no grade impact |
| **axis_3_dead_code** | Dead code | Unreachable branch verified by reachability trace | Hygiene backlog — no grade impact |
| **axis_3_smelly** | Smelly | Reachable but poorly justified (undocumented defensive guard, unused field) | Hygiene backlog — no grade impact |

**New shared skill: `radar-suite-axis-classification`.** Lives at `skills/radar-suite-axis-classification/`. Defines the 3-axis framework, the verification checklist (reachability trace, whole-file scan, branch enumeration, pattern citation lookup, source root introspection), the coaching schema, and the schema gate that rejects findings without proper coaching. Every other radar invokes this skill before emitting findings. Ships with two reference files:

- `coaching-examples-generic.md` — 5 anonymized worked examples covering all 3 axes. Default fallback for any iOS project.
- `coaching-examples-stuffolio.md` — 7 examples with real file:line citations from the Stuffolio codebase. Used when auditing Stuffolio via `.radar-suite/project.yaml` `coaching_examples: [stuffolio, generic]`. Future project overlays: add `coaching-examples-<projectname>.md` and reference it in the target's project.yaml.

**Mandatory coaching fields on every finding.** Every finding now includes:
- `before_after_experience` with explicit `audience` (`end_user` / `code_reader` / `future_maintainer`) and before/after description written from that audience's POV
- `current_approach` — how the code is structured today
- `suggested_fix` — the minimum change
- `better_approach` — **must cite a real file:line pattern in the audited codebase**, not generic advice. A better_approach without a `pattern_citation_lookup` entry in the verification_log is REJECTED by the schema gate.
- `better_approach_tradeoffs` — honest "when to apply / when not to apply" guidance
- `verification_log` — log of which verification checks were run with concrete results

**Extended `radar-suite-core.md` handoff schema.** Every handoff YAML now includes an `axis_summary` top-level block (counts by axis + `rejected_no_citation` count) and a `checks_performed` block (what was scanned, so "no bugs in this category" is distinguishable from "this category was not scanned"). The core file was propagated to all 7 per-skill copies (still byte-identical as of this release; future release will move to a single canonical copy).

**Per-radar integrations (3 of 6 radars wired up in this release).**

- **capstone-radar** — New Step 3.6 reads `axis_summary` from every companion handoff. Report splits into "Fix Before Shipping" (axis_1, graded) and "Hygiene Backlog" (axis_2/3, ungraded). A-F grade reflects ONLY axis_1 findings. "Audit Coverage" section surfaces aggregated `checks_performed` across radars. Backward compatible with pre-v2.0 handoffs (treated as all-axis_1).
- **ui-path-radar** — All 30 issue categories tagged with default axis. Reclassification rules documented: Dead End → axis_3_dead_code if unreachable, Empty State Missing → axis_3_dead_code if empty case unreachable, Sheet Presentation Asymmetry → axis_2_scatter if both platforms work. New Axis Classification Protocol section enforces pre-emission checks.
- **roundtrip-radar** — Roundtrip-specific axis mapping (data loss = axis_1, opaque flow = axis_2, unwired field = axis_3_smelly unless a user feature depends on it). Every finding must cite the full UI → manager → model → persistence → UI path in its verification_log. New `full_path_trace` check type.

**Per-radar integrations deferred to a future release:** data-model-radar, ui-enhancer-radar, time-bomb-radar. Reasons in `gleaming-cuddling-wreath.md` plan file. These radars still work under v2.0 but their findings are treated as legacy (all-axis_1) by capstone.

### Why both changes ship together

The plugin conversion and the axis framework were originally scheduled as separate releases. They ship together in v2.0 because the new axis-classification skill (`radar-suite-axis-classification`) is the 8th skill in the plugin manifest and needs to ship simultaneously. Splitting them would have required either (a) releasing a v1.x plugin with only 7 skills then immediately bumping to v2.x with 8, or (b) releasing the axis framework without the plugin, which would have re-introduced the install.sh drift risk. Neither was acceptable.

### Migration for existing users

- **If you're on `install.sh`:** do nothing. The script still works. It will print a deprecation banner pointing at the plugin path. Switch when convenient.
- **If you want the plugin:** run `/plugin marketplace add Terryc21/radar-suite` then `/plugin install radar-suite@radar-suite`. You may need to remove the existing symlinks in `~/.claude/skills/` manually first.
- **If you're a skill developer who depended on per-skill version numbers:** the plugin version (2.0.0) is now the only user-visible version. Old per-skill versions are preserved as inline comments in each SKILL.md frontmatter for reference.

### Files added/changed in this release

Added:
- `.claude-plugin/plugin.json` — plugin manifest (source of truth)
- `.claude-plugin/marketplace.json` — single-plugin marketplace declaration
- `.claude-plugin/verify-manifest.sh` — drift guardrail
- `skills/radar-suite-axis-classification/SKILL.md` — shared framework
- `skills/radar-suite-axis-classification/coaching-examples-generic.md`
- `skills/radar-suite-axis-classification/coaching-examples-stuffolio.md`

Changed:
- `radar-suite-core.md` (+ all 7 per-skill copies) — extended handoff schema, axis_summary, checks_performed, schema gate rules
- `skills/capstone-radar/SKILL.md` — Step 3.6 axis consumption, two-section report format
- `skills/ui-path-radar/SKILL.md` — axis mapping on 30 categories, Axis Classification Protocol section
- `skills/roundtrip-radar/SKILL.md` — Axis Classification Protocol section, full-path verification rule
- `install.sh` — deprecation banner, updated SKILLS array with radar-suite-axis-classification, drift check integration, updated completion message to "8 skills"
- `README.md` — plugin install path first, install.sh documented as fallback, "Coming soon" section replaced with "Shipped in v2.0" section
- All 8 `skills/*/SKILL.md` — `version:` field set to `2.0.0` with inline legacy-version comment

Not changed (deferred):
- `skills/data-model-radar/SKILL.md` — axis integration deferred
- `skills/ui-enhancer-radar/SKILL.md` — axis integration deferred
- `skills/time-bomb-radar/SKILL.md` — axis integration deferred

---

## 2026-04-10 — [installer] install.sh was silently incomplete for 17 days -- FIXED

**If you installed Radar Suite between 2026-03-24 and 2026-04-10, your install is missing `time-bomb-radar` and the `radar-suite` orchestrator.** Pull the latest and re-run `./install.sh` to backfill.

```bash
cd radar-suite
git pull
./install.sh
```

The installer is idempotent and safe to re-run.

**What happened.** `install.sh` was last updated on 2026-03-24 in commit `ca926a9`. Since then, two skills were added to the repo but the installer's hardcoded `SKILLS=()` array was never updated to match. Users who cloned the repo and ran `./install.sh` during the 17-day window received a working but incomplete install. `/time-bomb-radar` and `/radar-suite` commands would have returned "skill not found" errors even though the skill directories existed in `skills/`.

**How long it was broken.** 17 days (2026-03-24 to 2026-04-10). GitHub traffic shows 161 clones from 114 unique cloners in the 14-day window ending 2026-04-09. Some unknown fraction of those users got the incomplete install.

**What was fixed.** `install.sh` now installs all 7 skills (`data-model-radar`, `ui-path-radar`, `roundtrip-radar`, `time-bomb-radar`, `ui-enhancer-radar`, `capstone-radar`, and the `radar-suite` orchestrator). The completion message and recommended run order in the installer output were updated to match. See commit `d7e3191`.

**Why this happened.** A hand-maintained shell script is too fragile to be the source of truth for what a skill suite ships with. The README correctly said "7 skills" but the installer shipped 5, and the drift was not caught because nothing verified the two lists matched. This is exactly the kind of two-sources-of-truth bug that the plugin conversion shipped in v2.0 (entry above) was designed to prevent.

---

## 2026-04-09 (late)

### [ui-path-radar] Cross-Skill Handoff with workflow-audit

- Reads `.workflow-audit/persona-handoff.yaml` (if exists) to enrich Layer 4 semantic evaluation with user personas and D/E/F/R ratings
- Reads `.workflow-audit/handoff.yaml` (if exists) to import companion findings
- Adds `checks_performed` section to handoff YAML (automated_checks count, categories_scanned list, confidence_scoring flag)
- All reads are "if exists" -- zero behavior change when workflow-audit is not installed
- Compact table headers (Risk:Fix, Risk:NoFix, Blast, Effort) and terminal width cue added

---

## 2026-04-09

### [all skills] 5 Infrastructure Improvements

**1. False Positive Suppression (`known-intentional.yaml`)**
- New file: `.radar-suite/known-intentional.yaml` for suppressing findings that are intentionally correct
- Distinct from accepted risks ("not a bug" vs "known bug I accept")
- Match on file glob + pattern regex; skip silently during audit
- Commands: `--show-suppressed`, `--accept-intentional`
- Orphaned entry detection added to `/radar-suite verify`

**2. Dependency Graph for `--sort implement`**
- New finding fields: `depends_on`, `enables` (optional, best-effort)
- Capstone-radar Step 6.5: builds DAG from all findings, topological sort for `--sort implement`
- 3 auto-inference rules for cross-skill dependencies
- Cycle detection with fallback to urgency sort

**3. Pattern Fingerprints for Reintroduction Detection**
- New finding fields: `pattern_fingerprint`, `grep_pattern`, `exclusion_pattern`
- On audit startup, checks ledger for fixed patterns and greps codebase for reintroductions
- Reintroduced patterns reported at 🟡 HIGH urgency by default
- 5 built-in pattern categories always checked: `try?_swallow`, `force_unwrap_production`, `todo_in_production`, `shared_mutable_static`, `missing_file_protection`

**4. Companion Handoff Staleness Decay (capstone-radar only)**
- Formula: `staleness_score = (days * 0.3) + (commits * 0.1)`
- 4 tiers: Fresh (0-2), Aging (2-5), Stale (5-10), Expired (10+)
- Stale companions downgraded by one letter; Expired companions ignored
- Spot-check protocol for Aging/Stale findings
- New flag: `--trust-all` to override staleness

**5. Experience-Level Enforcement**
- New "Experience-Level Output Rules" table in core: 8 output dimensions x 4 levels
- Beginner: auto-enables `--explain`, defaults to `--sort impact`
- Senior/Expert: defaults to `--sort effort`, one-line progress banners
- All companion skills updated with auto-apply logic
- Workflow-audit now has Session Setup with experience-level question (previously missing)

---

### [all skills] User Impact Explanations, Sort Modes, Source Column

**`--explain` / `--no-explain` (all skills)**
- New toggle: appends a 3-line explanation after each finding in the Issue Rating Table
- Format: What's wrong (one sentence), Fix (one sentence), User experience before/after (one sentence)
- Code-only findings use "Developer experience" instead of "User experience"
- Default: off. Can be enabled at setup (capstone-radar Question 3) or toggled mid-session
- Defined in `radar-suite-core.md` "User Impact Explanations" section

**`--sort` modes (all skills)**
- `--sort urgency` (default) -- most broken first (Urgency ↓, ROI ↓)
- `--sort effort` -- easiest safe wins first (Fix Effort ↑, Risk:Fix ↑)
- `--sort impact` -- most user-visible first (Risk:No Fix ↓, Urgency ↓)
- `--sort implement` -- dependency-aware ordering for sprint planning
- Can be changed mid-session without re-running the audit
- Defined in `radar-suite-core.md` and `workflow-audit/skills/shared/rating-system.md`

**Source column (capstone-radar only)**
- 9-column table with new Source column (position 3, after Finding)
- Values: `capstone`, `data-model`, `ui-path`, `roundtrip`, `ui-enhancer`, `time-bomb`
- Eliminates need for separate tables per companion skill
- Impact-based organization now uses single table with category separator rows
- Other skills remain 8-column (Source would always be themselves)

**Progress banner updates (all skills)**
- Banner now includes sort mode hint and `--explain` hint
- Hints auto-suppress once the user has used them in the session

---

## 2026-04-07

### [all skills v3.0.0] Unified Finding Ledger & Impact-Based Organization

This is a major release that adds cross-skill finding management to every radar skill.

**Phase 1: Unified Finding Ledger**
- New `.radar-suite/ledger.yaml` -- single file where every skill writes findings with RS-NNN IDs
- Session tracking, monotonic IDs, impact categories, file content hashes
- All 6 skills (5 audit + capstone) now write to and read from the ledger
- Existing per-skill handoff YAMLs preserved for backward compatibility
- New command: `/radar-suite ledger` with filters (--open, --deferred, --impact, --skill, --severity)

**Phase 2: Impact-Based Organization & Deferred Management**
- Capstone report now organizes findings by impact category (crash > data-loss > ux-broken > ux-degraded > polish > hygiene) instead of by skill
- Legacy by-skill view available via `/capstone-radar report --by-skill`
- Fix batching options: by crash risk, blast radius, user journey, or skill
- Stale-deferred check on every `/radar-suite` invocation -- overdue findings surfaced with snooze/dismiss options
- New command: `/radar-suite deferred` generates DEFERRED.md from ledger

**Phase 3: Cross-Skill Deduplication & Contradiction Detection**
- Findings about the same file+region are merged or linked across skills
- `also_flagged_by[]` tracks which skills found the same issue
- `related_to[]` links different findings in the same file
- Capstone detects grade-vs-findings contradictions (e.g., A- grade with 3 HIGH findings)
- Severity disagreements between skills flagged for reconciliation

**Phase 4: Finding Relationships**
- Root-cause/symptom/duplicate/supersedes relationship types
- Auto-inference rules: data-model gap + roundtrip loss = root cause + symptom
- Fix cascade: fixing root cause auto-marks symptoms for re-check
- New command: `/radar-suite link RS-NNN --root-cause-of RS-NNN [RS-NNN...]`

**Phase 5: Regression Detection & Fix Verification**
- File content hashes (SHA-256 first 6 chars) stored at discovery and fix time
- All skills check fixed findings on startup -- flag files that changed since fix
- Verification patterns stored with each fix for automated re-checking
- New command: `/radar-suite verify` (all fixed findings, single finding, or --changed only)

**Phase 6: Confidence Decay & Partial Re-Audit**
- Accepted findings resurface after 180 days (configurable decay period)
- Decay check runs on every `/radar-suite` invocation alongside stale-deferred check
- New command: `/radar-suite audit --changed` scopes audit to modified files only (15-30 min vs 2.5-4 hrs)
- Partial audit auto-selects relevant skills based on changed file types

---

## 2026-04-03

### [roundtrip-radar 1.5.0 → 1.6.0] Bridge Parity Detection

Added:
- **Bridge Parity Detection** (check #10, `enumerate-required`) -- when multiple functions consume the same model type, compare which fields each reads. Flag asymmetries where one consumer reads strictly fewer fields than others. Uses relative comparison (no need to know the "correct" set -- the outlier is the finding).
- **Field-access matrix** -- structured method for recording which fields each consumer reads, making the comparison systematic.
- **Cross-cutting accumulator integration** -- after finding a bridge parity issue, the model type is added to the accumulator so subsequent workflows auto-check new consumers.
- **Handoff YAML** -- added `bridge_parity` group hint for cross-skill handoffs.

Origin: Stuffolio bug where `ScoutSession` had 3 consumers building notes text. Two included all 6 narrative fields; one included only 3. No type error, no crash -- users silently lost Historical Context, Collector Notes, and Research Tips on one code path. Single-path tracing cannot catch this; only cross-consumer comparison reveals the asymmetry.

---

## 2026-03-30

### [all skills] Dippy integration for paths with spaces

Added:
- **Environment pre-flight check** — Detects project paths with spaces and recommends [Dippy](https://github.com/ldayton/Dippy) if not installed. Non-blocking — audits continue either way.
- **Bundled `.dippy` config** — Reference config tuned for audit workflows (auto-approve read-only commands, block destructive operations).
- Addresses the Claude Code "Command contains backslash-escaped whitespace that could alter command parsing" warning that disrupts audit flow on paths with spaces.

---

## 2026-03-27 — Current (uncommitted)

### [all skills] Version bump + new features

**data-model-radar 1.2.0 → 1.3.0**
**ui-path-radar 3.4.0 → 3.5.0**
**ui-enhancer-radar 3.1.0 → 3.2.0**
**roundtrip-radar 1.2.0 → 1.3.0**
**capstone-radar 3.1.0 → 3.2.0**

Added (all 5 skills):
- **Genuine problems preamble** — "Report real issues backed by evidence. Do not nitpick, invent issues, or inflate severity."
- **Inline cross-skill referrals** — findings that belong to another skill's domain get a `→ Deeper analysis: /[skill]` hint
- **Findings by File view** — re-groups findings by file path after the domain-organized table
- **Xcode MCP integration** — optional startup check for Xcode MCP tools (BuildProject, RenderPreview, DocumentationSearch)
- **Hard gate on progress banners** — response MUST end with AskUserQuestion after every wave/commit/build
- **Finding Resolution Gate** — all findings must reach terminal state (Fixed/Accepted/Deferred) before wrap-up
- **Startup version check** — checks GitHub for newer version, prints one-line notice if outdated
- **VERSION files** — each skill has a VERSION file for remote version checking

Added (ui-enhancer-radar, data-model-radar):
- **Reference-based architecture** — domain knowledge extracted into `references/` subdirectories. Single-domain commands load only the relevant reference file, saving context window.
  - ui-enhancer-radar: 5 reference files (domains-1-4, domains-5-8, domains-9-11, compaction-rules, pattern-sweep). SKILL.md reduced from 2,579 to ~1,850 lines.
  - data-model-radar: 1 reference file (domains). SKILL.md reduced from 765 to ~690 lines.

---

## 2026-03-27 — `a4ae91f`

### [docs] README improvements
- Added GitHub stars/forks badges
- Added "How is Radar Suite different" section explaining pattern matching vs behavior tracing

---

## 2026-03-25 — `6ffe108`

### [all skills] Fidelity infrastructure

Added:
- **6 infrastructure gaps closed** — consistent enforcement across all 5 skills
- **Test Gate** — every fix must have a test before moving to next wave
- **Compliance Self-Check** — mechanical verification that output matches skill rules
- **Table Format Gate** — pre-output check that rating tables have all required columns

### [ui-enhancer-radar 3.1.0]
- **Visual Inspection Gate** — blocks all code changes until user confirms they can see the view
- **Guided Visual Review** — walks through changes with user looking at the screen
- **Similar View Queue** — after fixing one view, finds similar patterns across codebase with pre-generated tailored recommendations
- **Pattern Sweep decision prompts** — mandatory "Explain pros/cons" option

### [docs]
- Finding Resolution section added to README
- FIDELITY.md — "The Deeper Problem" section on why AI auditors skip steps

---

## 2026-03-24 — `cf55c66`

### [all skills] Fidelity improvements

Added:
- **Work receipts** — every verified finding must cite the file, line range, and grep pattern used
- **Contradiction detection** — mechanical check that grades don't contradict findings
- **Finding classification** — every finding categorized as Bug, Stale Code, or Design Choice
- **Verification templates** — per-domain checklists that must be filled before grading
- **Developer growth awareness** — findings framed as growth, not criticism

### [all skills] Finding Resolution system
- Every finding must reach terminal state: Fixed, Planned, or Accepted
- FIDELITY.md created documenting audit honesty philosophy

---

## 2026-03-24 — `ca926a9`

### Radar Suite monorepo created

Consolidated 5 individual skill repos into one monorepo with shared install script.

Initial versions at monorepo creation:
- data-model-radar 1.2.0
- ui-path-radar 3.4.0
- ui-enhancer-radar 3.1.0
- roundtrip-radar 1.2.0
- capstone-radar 3.1.0

---

## Pre-monorepo history

Skills were developed individually across separate repos (now archived/redirected):

- **data-model-radar** — v1.0 → v1.1 → v1.2: Added risk-ranking, evidence gates, anti-shortcut rules, audit depth modes, stratified sampling
- **ui-path-radar** — v3.0 → v3.2 → v3.3 → v3.4: Added 3-tier scan, hierarchy grouping, 6 new issue patterns, progress milestones, permission modes, experience-level adaptation
- **ui-enhancer-radar** — v2.5 → v3.0 → v3.1: Added Domain 11 (Color Audit), Adaptive View Profile, Cross-View Consistency, platform heuristics, batch mode
- **roundtrip-radar** — v1.0 → v1.1 → v1.2: Added fix application workflow (waves), progress banners, two-pass risk scoring, cross-cutting pattern accumulator
- **capstone-radar** — v3.0 → v3.1: Added risk-ranking, grade honesty rules, companion handoff quality assessment, tests-required-per-fix
