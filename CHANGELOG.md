# Changelog

All notable changes to the Radar Suite skills are documented here.

Format: [skill-name vX.Y.Z] or [all skills] when changes apply to every skill.

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
