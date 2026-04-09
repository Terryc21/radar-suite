# Changelog

All notable changes to the Radar Suite skills are documented here.

Format: [skill-name vX.Y.Z] or [all skills] when changes apply to every skill.

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
