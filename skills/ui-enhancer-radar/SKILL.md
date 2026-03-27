---
name: ui-enhancer-radar
description: 'Systematic iOS/SwiftUI UI audit with design intent interview, 11-domain analysis (including Color Audit with adaptive Color Profile), element compaction, cross-view consistency checks, layout reorganization, design-aware push-back, App Store guardrails, and incremental apply with revert safety. 17 subcommands. Run /ui-enhancer-radar help for all commands. Triggers: "enhance this UI", "ui enhancer radar", "improve this view", "screen review", "ux audit".'
version: 3.2.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, Bash, Write, Edit, AskUserQuestion]
metadata:
  tier: execution
  category: ux
---

# UI Enhancer Radar

> **Quick Ref:** Screenshot + code analysis of any iOS/SwiftUI view. Design intent interview (sacred elements, aggressiveness), 11-domain analysis with layout reorganization and Color Audit (adaptive Color Profile), element compaction (compact vs remove vs keep), cross-view consistency checks, design-aware refinement with push-back and App Store guardrails, incremental apply with revert safety (git or file backup), visual verification guidance, and files-changed summary.

<ui-enhancer-radar>

You are performing a systematic UI enhancement on a specific iOS/SwiftUI view, analyzing both the visual screenshot and the underlying code, then implementing improvements with tests.

**Required output:** Every finding MUST include a severity rating (Critical / High / Medium / Low) and estimated implementation effort (Trivial / Small / Medium / Large).

**Genuine problems only:** Report real issues backed by evidence. Do not nitpick, invent issues, or inflate severity. If unsure whether something is a problem, say so — don't report it as a finding.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/ui-enhancer-radar` | Full audit with interview |
| `/ui-enhancer-radar space` | Space efficiency analysis only |
| `/ui-enhancer-radar hierarchy` | Visual hierarchy analysis only |
| `/ui-enhancer-radar density` | Information density analysis only |
| `/ui-enhancer-radar interaction` | Interaction patterns analysis only |
| `/ui-enhancer-radar accessibility` | Accessibility audit only |
| `/ui-enhancer-radar hig` | HIG compliance check only |
| `/ui-enhancer-radar dark-mode` | Dark mode audit only |
| `/ui-enhancer-radar performance` | Performance impact analysis only |
| `/ui-enhancer-radar design-system` | Design system compliance only |
| `/ui-enhancer-radar color` | Color audit only (inventory, flatness, consistency) |
| `/ui-enhancer-radar compare` | Compare before/after screenshots for progress |
| `/ui-enhancer-radar revert` | Undo all changes back to last checkpoint |
| `/ui-enhancer-radar batch [path]` | Audit all views in a directory, rank by severity |
| `/ui-enhancer-radar --capture` | Capture screenshot from running simulator (optional) |
| `/ui-enhancer-radar --devices` | Analyze layout across device sizes (optional) |
| `/ui-enhancer-radar fix-deferred` | Resolve items deferred from a previous run |
| `/ui-enhancer-radar verify` | Re-check previous findings without full re-audit (~5 min) |

---

## Help Command

**If the user runs `/ui-enhancer-radar help`**, display this command reference and stop (do not start an audit):

```
UI Enhancer — Available Commands

FULL AUDIT
  /ui-enhancer-radar              Full 11-domain audit with interview

SINGLE DOMAIN (skip interview, run one domain)
  /ui-enhancer-radar space        Space efficiency analysis
  /ui-enhancer-radar hierarchy    Visual hierarchy analysis
  /ui-enhancer-radar density      Information density analysis
  /ui-enhancer-radar interaction  Interaction patterns analysis
  /ui-enhancer-radar accessibility  Accessibility audit
  /ui-enhancer-radar hig          HIG compliance check
  /ui-enhancer-radar dark-mode    Dark mode audit
  /ui-enhancer-radar performance  Performance impact analysis
  /ui-enhancer-radar design-system  Design system compliance
  /ui-enhancer-radar color        Color audit (inventory, flatness, consistency)

UTILITIES
  /ui-enhancer-radar compare      Compare before/after screenshots
  /ui-enhancer-radar revert       Undo all changes back to checkpoint
  /ui-enhancer-radar batch [path] Audit all views in a directory
  /ui-enhancer-radar help         Show this command list

OPTIONS (combine with any command)
  --capture                 Capture screenshot from running simulator
  --devices                 Analyze layout across device sizes
```

---

## First-Run Hint

When `/ui-enhancer-radar` is invoked with no subcommand, display this hint **once** before the Phase 1 interview (not on subsequent runs in the same session):

> Tip: Run `/ui-enhancer-radar help` to see all available commands, or continue for a full audit.

Then proceed directly to Phase 1.

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

**Experience-adapted explanations for UI Enhancer:**

- **Beginner**: "UI Enhancer is like having a professional designer review every screen in your app. It checks 11 different things — spacing, colors, accessibility, layout efficiency, and more — then suggests specific improvements. It won't just say 'this looks wrong'; it'll show you exactly what to change and why. It works one view at a time, applying changes incrementally so you can undo anything."

- **Intermediate**: "UI Enhancer performs an 11-domain analysis of SwiftUI views: layout, spacing, color accessibility, typography, element compaction, cross-view consistency, and more. It interviews you about design intent first, then audits against Apple HIG and your app's design system. Changes are applied incrementally with revert safety."

- **Experienced**: "11-domain SwiftUI UI audit with design intent interview, adaptive color profiles, element compaction, cross-view consistency checks, layout reorganization, App Store guardrails, and incremental apply with revert safety. 17 subcommands."

- **Senior/Expert**: "11-domain view audit: layout, color, typography, spacing, compaction, consistency, accessibility. Interview → analyze → apply incrementally."

Store the experience level as `USER_EXPERIENCE` and apply to ALL output for the session.

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
curl -sf https://raw.githubusercontent.com/Terryc21/radar-suite/main/skills/ui-enhancer-radar/VERSION 2>/dev/null
```

- If the remote version is newer than `3.2.0`, print one line before proceeding:
  > Update available: ui-enhancer-radar v[remote] (you have v3.2.0). Run `git -C ~/.claude/skills/ui-enhancer-radar pull` or visit https://github.com/Terryc21/radar-suite
- If curl fails, remote is same/older, or command times out — skip silently. Never block the audit for a version check.

---

## Xcode MCP Integration (Optional)

On startup, silently check if Xcode MCP tools are available (e.g., attempt to list tools or check for `xcrun mcpbridge`).

- **Available:** Set `XCODE_MCP = true`, note in audit header: `Xcode MCP: available`
- **Not available:** Set `XCODE_MCP = false`, skip silently. Do not prompt user to install.

**When XCODE_MCP = true, use these tools:**
- `RenderPreview` — verify layout recommendations before presenting them
- `BuildProject` — verify code changes compile after applying fixes

---

## Plain Language Communication (MANDATORY)

All user-facing prompts must be understandable by someone who has never used this skill before:

1. **Describe what was found** in plain terms ("3 layout issues, 2 color contrast problems") — not "3 Domain 1 findings, 2 Domain 11 findings"
2. **Describe next steps by what they DO**, not by skill name
3. **Add an "Explain more" option** to every transition `AskUserQuestion`
4. **Define jargon on first use:**
   - "Domain" → "check area" (a focused area of UI analysis, e.g., spacing, colors, typography)
   - "Phase" → "fix batch" (a group of related improvements applied together)
   - "Handoff" → a file this skill writes so other audit skills can pick up where it left off
   - "Compaction" → reducing wasted space so more content is visible without scrolling
5. **Exception:** If user selected Senior/Expert experience level, terse references are acceptable

### Completion Prompt Template

```
I reviewed [view name] across [N] areas and found [X] improvements:
- [N] layout/spacing issues
- [N] visual hierarchy improvements
- [N] accessibility fixes

You can:
1. **Apply all improvements** (~[time])
2. **Apply critical fixes only** (~[time]) — [one-line description]
3. **Keep auditing other areas first** — I'll check [plain description] next
4. **Explain more** — I'll walk through what each improvement does
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

## Phase 1: Interview

Before analyzing, run a brief intake to focus the audit on what matters most.

**Display this instruction before the first set of questions:**

> To answer, type the option labels (e.g., "General polish, All domains, Moderate, Experienced") or use numbers (e.g., "1, 1, 1, 1, 3"). You can answer all questions at once or one at a time.

```
questions:
[
  {
    "question": "What's your experience level with Swift/SwiftUI?",
    "header": "Experience",
    "options": [
      {"label": "Beginner", "description": "New to Swift — plain language, analogies, define terms on first use"},
      {"label": "Intermediate", "description": "Comfortable with SwiftUI basics — standard terms, explain non-obvious patterns"},
      {"label": "Experienced (Recommended)", "description": "Fluent with SwiftUI — concise findings, no definitions"},
      {"label": "Senior/Expert", "description": "Deep expertise — terse output, file:line only, skip explanations"}
    ],
    "multiSelect": false
  },
  {
    "question": "What's the main reason for this review?",
    "header": "Focus",
    "options": [
      {"label": "General polish (Recommended)", "description": "No specific complaint \u2014 just want it to be better"},
      {"label": "Specific problem", "description": "Users or I have noticed something wrong"},
      {"label": "Pre-release review", "description": "Final check before shipping"},
      {"label": "Competitive parity", "description": "Want to match or exceed a competitor's UX"}
    ],
    "multiSelect": false
  },
  {
    "question": "Which aspects matter most right now?",
    "header": "Priority",
    "options": [
      {"label": "All domains (Recommended)", "description": "Full 9-domain analysis"},
      {"label": "Visual \u2014 layout and hierarchy", "description": "Space, visual weight, information density"},
      {"label": "Interaction \u2014 usability", "description": "Touch targets, discoverability, feedback"},
      {"label": "Technical \u2014 performance and compliance", "description": "Dark mode, perf, HIG, design system"}
    ],
    "multiSelect": false
  }
]
```

**If "Specific problem"**, follow up:

```
questions:
[
  {
    "question": "What's the specific issue?",
    "header": "Issue",
    "options": [
      {"label": "Too much wasted space (most common)", "description": "Content doesn't start until halfway down the screen"},
      {"label": "Hard to find things", "description": "Users can't discover features or actions"},
      {"label": "Looks cluttered or confusing", "description": "Too much competing for attention"},
      {"label": "I'll describe it", "description": "Let me explain the problem"}
    ],
    "multiSelect": false
  }
]
```

**If "Competitive parity"**, ask for a competitor screenshot to enable Domain 10 (Competitive Comparison).

### Design Intent (always ask)

After the focus/priority questions, always ask about design intent and change aggressiveness:

```
questions:
[
  {
    "question": "Are there elements on this screen you consider essential to its identity — things that should be preserved even if they use extra space?",
    "header": "Identity",
    "options": [
      {"label": "No sacred elements (Recommended)", "description": "Everything is fair game for optimization"},
      {"label": "Yes, I'll point them out", "description": "I'll identify specific elements to preserve"},
      {"label": "Keep all branding/headers", "description": "Preserve illustrated headers, icons, and branded sections"},
      {"label": "Not sure — show me options", "description": "Offer compact vs remove for each visual element"}
    ],
    "multiSelect": false
  },
  {
    "question": "How aggressive should changes be?",
    "header": "Aggressiveness",
    "options": [
      {"label": "Moderate (Recommended)", "description": "Compact where possible, remove only clear redundancies"},
      {"label": "Conservative", "description": "Tighten spacing and compact only — never remove elements"},
      {"label": "Aggressive", "description": "Maximize space — remove anything non-essential"}
    ],
    "multiSelect": false
  }
]
```

### Attendance (always ask)

```
questions:
[
  {
    "question": "Will you be stepping away during the audit?",
    "header": "Attendance",
    "options": [
      {"label": "I'll be here (Recommended)", "description": "Normal mode — permission prompts may appear for writes/edits"},
      {"label": "Hands-free (walk away safe)", "description": "Read-only analysis only — no edits, no Bash, no prompts. Code changes deferred until you return."},
      {"label": "Pre-approved", "description": "You've configured Claude Code permissions for this session. Full speed, no restrictions."}
    ],
    "multiSelect": false
  }
]
```

**If "Hands-free"** — restrict to Read, Grep, Glob tools only. Complete Phases 1-5 (interview through analysis) without blocking. Defer Phase 6+ (code changes) until the user returns. Print when paused:
```
⏱ Hands-free audit complete through Phase 5 (analysis).
  Phases requiring action: Phase 6 (compaction), Phase 7 (apply changes)
  Reply to continue with supervised phases.
```

**If "Pre-approved"** — full speed, no restrictions. Assumes permissions are configured per the Permission Setup guide below.

### Permission Setup (for unattended runs)

To avoid permission prompts during audits, pre-allow these read-only patterns in Claude Code settings. Safe to auto-approve — they cannot modify your codebase:

```
# Already safe by default (no setup needed):
Read, Grep, Glob — always auto-approved

# Add these for unattended Bash scans:
Bash(find:*)
Bash(wc:*)
Bash(stat:*)
```

**Do NOT auto-approve** (keep prompted — they modify state):
```
Edit, Write — file modifications
Bash(rm:*), Bash(git:*) — destructive operations
```

**After all questions, always offer:**

> Anything else I should know? (design preferences, constraints, specific elements to preserve — or press Enter to skip)

Record any free-text input as additional constraints that apply throughout the audit. For example: "Preserve saturation and hue of card backgrounds" becomes a constraint checked during every finding.

**If "Yes, I'll point them out"** — ask the user to describe or screenshot the sacred elements. Tag them as `[PRESERVE]` in the findings table and default to compaction (Phase 6c) rather than removal.

**If "Keep all branding/headers"** — mark all illustrated headers, SheetHeaders, ContentIllustratedHeaders, and branded sections as `[PRESERVE]`. Only recommend compaction for these, never removal.

**If "Not sure — show me options"** — for every visual element, present the full Phase 6c compaction menu (compact / remove / keep).

### Aggressiveness calibration

The aggressiveness setting affects all findings throughout the audit:

| Setting | Spacing | Headers | Decorative elements | Redundant info |
|---|---|---|---|---|
| **Conservative** | Tighten 10-20% | Compact only | Keep, reduce size | Merge, don't remove |
| **Moderate** | Tighten 20-40% | Compact (default), remove if redundant | Compact or remove | Remove if truly duplicate |
| **Aggressive** | Minimize to HIG minimum | Remove unless `[PRESERVE]` | Remove | Remove |

The interview determines:
- Which domains to run (all 9, or a focused subset)
- Severity weighting (user-reported problems get Critical minimum)
- Whether to include competitive comparison
- Which elements are sacred (`[PRESERVE]` tag)
- How aggressive to be with changes (Conservative / Moderate / Aggressive)
- How to pitch explanations (experience level)

### Experience-Level Adaptation

Adjust ALL output (findings, questions, recommendations, compaction options) based on the user's experience level:

- **Beginner**: Plain language, real-world analogies. "This header takes up 120 points of space — that's about a third of the visible screen on an iPhone. Compacting it would let users see their content sooner." Define SwiftUI terms on first use. When presenting compaction options, explain what each choice means visually.
- **Intermediate**: Standard SwiftUI terminology, explain non-obvious tradeoffs. "The `SheetHeader` uses 120pt — compacting to inline icon+title saves 80pt and keeps the visual identity. The `.stuffolioCard()` modifier handles the styling." Explain architectural choices but not basic concepts.
- **Experienced** (default): Concise findings. "SheetHeader: 120pt → 40pt inline. Saves 80pt above fold." No definitions, focus on measurements and tradeoffs.
- **Senior/Expert**: Minimal. "SheetHeader 120→40pt. `.stuffolioCard()` handles styling. 3 files touched." Skip design rationale — just the change, the impact, and the blast radius.

---

## Phase 2: Gather Input

```
questions:
[
  {
    "question": "How would you like to provide the view to analyze?",
    "header": "Input",
    "options": [
      {"label": "Screenshot + file path (Recommended)", "description": "Deepest analysis \u2014 visual + structural"},
      {"label": "Screenshot only", "description": "Visual analysis, recommendations without code changes"},
      {"label": "File path only", "description": "Code analysis, structural improvements"},
      {"label": "Capture from simulator", "description": "I'll capture the screenshot automatically (optional)"}
    ],
    "multiSelect": false
  }
]
```

**If "Capture from simulator"** (optional feature):
```bash
xcrun simctl io booted screenshot /tmp/ui-enhancer-radar-capture.png
```
Then read the captured screenshot.

---

## Phase 2b: View Type Classification

**Before analyzing, classify the view type.** This determines severity weighting, compensation strategies, and domain-specific heuristics throughout the audit.

Classify by reading the code and/or screenshot. Do NOT ask the user — infer from evidence:

| View Type | How to Identify | Implications |
|-----------|----------------|--------------|
| **Dashboard / overview** | Aggregates data from multiple sources, cards/widgets, summary stats | Space efficiency is Critical; visual variety matters most |
| **Detail / inspector** | Shows one item's full data, sections of attributes | Information density is Critical; hierarchy matters most |
| **Form / input** | Text fields, pickers, toggles for data entry | Interaction patterns are Critical; keep chrome minimal |
| **List / table** | Repeating rows of similar items, search/filter | Density and performance are Critical; row height matters |
| **Help / reference** | Static instructional text, tips, guides | Space is Medium priority; visual richness prevents boredom |
| **Sheet / modal** | Presented modally for a focused task | Check for duplicate headers (SheetContainer + SheetHeader) |
| **Settings / config** | Toggles, preferences, grouped sections | HIG compliance is Critical; follow system patterns |

**Record the classification** at the top of the report (e.g., "View type: Help / reference (sheet)"). Reference it when:
- Choosing severity levels (Domain 1-11)
- Offering compaction alternatives (Phase 6c)
- Recommending compensation techniques (Phase 6d)
- Deciding whether a finding is worth fixing
- Applying platform-specific design heuristics (see below)

#### Platform-Specific Design Heuristics

When the view runs on multiple platforms, apply platform-appropriate design expectations:

| View Type | macOS (with sidebar) | iPhone (no sidebar) |
|---|---|---|
| **Dashboard** | Should be a *summary* — show stats, alerts, and insights. Navigation lives in sidebar. Feature cards that duplicate sidebar items are redundant. | Should be a *hub* — provide entry points to all features. No sidebar means the dashboard IS the navigation. |
| **Settings / config** | Settings items accessible via sidebar don't need dashboard cards. Theme toggle in header is optional if Settings is 1 click away. | Settings behind a tab or gear icon — header controls add convenience. |
| **Form / input** | Wider layout allows side-by-side fields. Keyboard toolbar not needed (Tab key navigation). | Keyboard Done toolbar is essential. Single-column layout. |
| **List / table** | Can show more columns, denser rows. Hover effects for interactivity. | Swipe actions, pull-to-refresh. Touch-optimized row height (44pt min). |

**How to apply:** After classifying the view type, check which platform the screenshot/code targets. If macOS with sidebar, apply the "summary" heuristic for dashboards. If iPhone, apply the "hub" heuristic. Flag findings that are platform-specific (e.g., "This redundancy only applies on macOS where the sidebar provides the same navigation").

---

## Phase 3: Screenshot Analysis

When a screenshot is provided, analyze it visually:

### 3a. First Impression (3-Second Test)
- What does the user see first? Is it what matters most?
- Can the user tell what this screen does within 3 seconds?
- Is the primary action obvious?

### 3b. Visual Scan Pattern
- Does the layout follow natural eye flow (F-pattern or Z-pattern)?
- Are related elements grouped visually?
- Is there a clear visual hierarchy (primary > secondary > tertiary)?

### 3c. Content-to-Chrome Ratio
- Measure: What percentage of the viewport is actual content vs. navigation chrome?
- **Target:** >60% content on iPhone, >70% on iPad
- Flag any view where content ratio falls below 50%

---

## Phase 4: Code Analysis

When a SwiftUI file is provided, read it and analyze:

### 4a. View Structure
- Total nesting depth (VStack chains)
- Number of distinct visual sections
- Spacing and padding accumulation
- Bottom padding for floating elements

### 4b. Component Audit
- Redundant UI elements (same info shown twice)
- Elements that could be merged (separate rows that should be one)
- Hidden/conditional elements wasting space when collapsed
- Action button sizing and placement

### 4c. Text and Typography
- Font hierarchy clarity (is there a clear primary > secondary > tertiary?)
- Line limit truncation (important text cut off while less important text has room)
- Dynamic Type support (`.system(size:)` vs semantic fonts)

### 4d. Color Usage
- Meaningful vs. decorative color
- Competing colors
- Contrast sufficiency
- Information redundancy (color + icon + text)

---

## Phase 5: Domain Analysis

Run the applicable domains based on the interview:

### Verification Template (MANDATORY per view audit)

Before grading a view, produce this checklist showing what was actually inspected:

```
| Domain | Checked? | Receipt | Findings |
|--------|----------|---------|----------|
| 1. Space Efficiency | ? | (file:line) | |
| 2. Visual Hierarchy | ? | (file:line) | |
| ... | | | |
| 11. Color Audit | ? | (file:line) | |
```

Rules:
- Every domain must be marked checked (yes) or skipped (no — with reason)
- Skipped domains cannot contribute to the grade (positive or negative)
- A grade cannot be produced while any domain has `?`

### Domain Reference Loading

Load domain references based on the command. References are in `references/` relative to this skill's directory.

**Full audit or no subcommand:** Read all domain references:
- `Read ~/.claude/skills/ui-enhancer-radar/references/domains-1-4.md`
- `Read ~/.claude/skills/ui-enhancer-radar/references/domains-5-8.md`
- `Read ~/.claude/skills/ui-enhancer-radar/references/domains-9-11.md`

**Single domain commands — load only the relevant file:**

| Command | Load |
|---------|------|
| `space`, `hierarchy`, `density`, `interaction` | `references/domains-1-4.md` |
| `accessibility`, `hig`, `dark-mode`, `performance` | `references/domains-5-8.md` |
| `design-system`, `color` | `references/domains-9-11.md` |

**batch mode:** Read all domain references (needed for cross-view scoring).

---

**Domains 5-8** (Accessibility, HIG, Dark Mode, Performance): See `references/domains-5-8.md`

---

**Domains 9-11** (Design System, Competitive, Color Audit, Adaptive View Profile): See `references/domains-9-11.md`

---

---

## Phase 6: Generate Report

### Report Structure

```
## UI Enhancer Report: [ViewName]
*UI Enhancer v[version] | [date]*

### Focus: [from interview — e.g., "General polish" or "Specific: too much wasted space"]

### Screenshot Analysis
- Content-to-chrome ratio: X%
- First content element at: Ypt from top
- Primary action visibility: [Obvious / Hidden / Ambiguous]
- 3-second test: [Pass / Fail — what draws the eye]

### Findings

| # | Domain | Finding | Severity | Effort | Recommendation |
|---|--------|---------|----------|--------|---------------|
| 1 | Space | 45% of screen is header chrome | Critical | Medium | Merge photo into title row |
| 2 | Hierarchy | Date text dominates over item title | High | Small | Replace with status circle |
| 3 | Dark Mode | 3 hardcoded Color.white references | Medium | Trivial | Replace with semantic colors |
| ... | ... | ... | ... | ... | ... |

### UX Score

| Domain | Score | Notes |
|--------|-------|-------|
| Space Efficiency | 4/10 | Content starts at 410pt |
| Visual Hierarchy | 6/10 | Date text too dominant |
| Information Density | 7/10 | Good density, some redundancy |
| Interaction | 5/10 | Combined buttons, gesture-only deletes |
| Accessibility | 8/10 | Good labels, some fixed fonts |
| HIG Compliance | 7/10 | Minor deviations |
| Dark Mode | 6/10 | Some hardcoded colors |
| Performance | 8/10 | Clean structure |
| Design System | 7/10 | Mostly compliant |
| Color | 5/10 | Monochromatic sections, inconsistent opacities |
| **Overall** | **6.2/10** | |

### Before/After ASCII Mockup

BEFORE:
┌─────────────────────────┐
│ [Nav Bar]               │
│ [Photo Row - 56pt]      │
│ [Title Row - 64pt]      │
│ [Tab Chips - 40pt]      │
│ [Action Buttons - 32pt] │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│ [Content starts here]   │
│ ...                     │
└─────────────────────────┘
Content ratio: 39%

AFTER:
┌─────────────────────────┐
│ [Nav Bar]               │
│ [Photo+Title - 64pt]    │
│ [Chips + Buttons - 40pt]│
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │
│ [Content starts here]   │
│ ...                     │
│ ...                     │
│ ...                     │
└─────────────────────────┘
Content ratio: 63%

### Space Budget (Before/After)

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Header chrome | [N]pt | [N]pt | -[N]pt |
| Search/filters | [N]pt | [N]pt | -[N]pt |
| Section headers (×[count]) | [N]pt | [N]pt | -[N]pt |
| Content starts at | [Y]pt | [Y]pt | -[N]pt |
| Content-to-chrome ratio | [X]% | [X]% | +[N]% |
| Sections | [N] | [N] | -[N] |
| Feature cards/buttons | [N] | [N] | -[N] |

**Net space recovered:** ~[N]pt

### Implementation Priority

**Quick Wins (do first):**
1. [Finding] — [exact code change]

**Medium Effort:**
2. [Finding] — [approach]

**Nice-to-Have:**
3. [Finding] — [approach]
```

---

## Phases 6b/6c/6d: Compaction Rules

**When any finding recommends removing UI elements, load the compaction reference:**

`Read ~/.claude/skills/ui-enhancer-radar/references/compaction-rules.md`

This covers:
- **Phase 6b:** Content & Identity Preservation Check (before removing UI)
- **Phase 6c:** Element Compaction (when recommending removal of visual elements)
- **Phase 6d:** Visual Compensation Check (when removing visual elements)

Load this reference ONLY when findings recommend removing or replacing UI elements. Skip for audits that only identify issues without removal recommendations.

## Phase 7: Implementation Playbook

**MANDATORY: Before ANY code edits, complete Phase 7a (User Commit Offer), Phase 7b (Visual Inspection Gate), and Phase 7c (Guided Visual Review). These are NOT optional. Skipping them means making blind changes to visual UI.**

For each finding, generate the exact code change — not just a description.

### Playbook Entry Format

```
### Fix #1: [Finding title]

**File:** `Sources/Views/Detail/EnhancedItemDetailView.swift`
**Lines:** 180-265

**Before:**
[exact code block to replace]

**After:**
[exact replacement code]

**Why:** [one sentence explaining the UX improvement]

**Test:** [what to verify after applying]
```

Offer to apply changes:

```
questions:
[
  {
    "question": "How would you like to apply these changes?",
    "header": "Implement",
    "options": [
      {"label": "Apply all (Recommended)", "description": "Implement all fixes with keep/revert after each"},
      {"label": "Quick wins only", "description": "Only Trivial/Small effort changes"},
      {"label": "One at a time", "description": "Apply and verify each fix individually"},
      {"label": "Save playbook", "description": "Save to file, implement later"}
    ],
    "multiSelect": false
  }
]
```

---

## Phase 7a: User Commit Offer (MANDATORY — execute before ANY edits)

**This phase is NOT optional. Do NOT skip it. Do NOT silently create checkpoints. ASK the user.**

**First, check if git is available** by running `git rev-parse --is-inside-work-tree`. If git is available, offer the git-based options. If not, offer file-based alternatives.

### If git IS available:

```
questions:
[
  {
    "question": "Before making changes, would you like to commit your current work? This creates a clean revert point.",
    "header": "Safety",
    "options": [
      {"label": "Commit first (Recommended)", "description": "Commit uncommitted changes so you can revert cleanly"},
      {"label": "Skip — working tree is clean", "description": "No uncommitted work to protect"},
      {"label": "Skip — I'll manage git myself", "description": "Proceed without committing"}
    ],
    "multiSelect": false
  }
]
```

**If "Commit first":**
1. Run `git status` to show what will be committed
2. Stage and commit with message: `chore: checkpoint before ui-enhancer-radar changes`
3. Confirm the commit hash to the user

**If "Skip — working tree is clean":**
Verify with `git status --porcelain`. If there ARE uncommitted changes, warn and re-ask.

**If "Skip — I'll manage git myself":**
Proceed without committing.

### If git is NOT available:

```
questions:
[
  {
    "question": "No git repository detected. Before making changes, would you like to back up the files that will be modified?",
    "header": "Safety",
    "options": [
      {"label": "Back up files (Recommended)", "description": "Copy each file to a .backup before editing"},
      {"label": "Skip — I have my own backups", "description": "Proceed without backup"},
      {"label": "Save playbook only", "description": "Show the changes but don't apply — I'll do it manually"}
    ],
    "multiSelect": false
  }
]
```

**If "Back up files":**
For each file that will be modified, create a copy: `cp file.swift file.swift.backup`
List the backup files created so the user can find them.

**If "Save playbook only":**
Generate the full playbook with before/after code blocks, but do not apply any edits. The user applies changes manually in Xcode.

**Revert behavior without git:**
- "Revert this fix" → restore from `.backup` file
- "Revert all" → restore all `.backup` files
- After the audit completes successfully, offer to clean up `.backup` files

---

## Phase 7b: Visual Inspection Gate (MANDATORY — blocks ALL code changes)

> **⚠️ CRITICAL WARNING: NEVER modify UI code based solely on code analysis.**
>
> Code analysis can count colors, measure spacing values, and detect structural patterns — but it CANNOT tell you whether a view actually *looks* wrong. A view with 3/5 blue icons might look perfectly fine because the form layout separates them visually. A view with "excessive" padding might feel exactly right on a real device.
>
> **Every UI change must be validated by a human looking at the actual view.** This is non-negotiable. The user must visually inspect the view before ANY finding is approved or rejected.

### Why This Gate Exists

Without visual inspection, the skill will:
- Fix "problems" that aren't actually visible to users
- Make changes that look worse than the original
- Waste time on micro-optimizations that don't matter on a real screen
- Create a "revert everything" scenario because changes were made blind

### How It Works

**Before applying ANY code changes from the playbook, block on user visual inspection.**

Present this prompt (do NOT skip, do NOT auto-proceed):

```
questions:
[
  {
    "question": "Before making changes, you need to see the actual view. How are you viewing it?",
    "header": "Inspect",
    "options": [
      {"label": "Xcode Canvas (Recommended)", "description": "Open the file in Xcode — Canvas shows the view live. Fastest feedback loop."},
      {"label": "Running in Simulator", "description": "App is running in Simulator — I can navigate to the view"},
      {"label": "Running on device", "description": "App is running on a physical device"},
      {"label": "I'll view it later", "description": "Save the findings as a playbook — I'll apply changes when I can see the view"},
      {"label": "Explain pros/cons", "description": "Why does visual inspection matter for this?"}
    ],
    "multiSelect": false
  }
]
```

**If "Xcode Canvas":**
Confirm: "Open `[FileName].swift` in Xcode. The Canvas panel (right side) should show the view. If Canvas isn't visible, press Opt+Cmd+Return. Reply when you can see it."

**If "Running in Simulator" or "Running on device":**
Confirm: "Navigate to [ViewName] in the app. Reply when you can see it."

**If "I'll view it later":**
Save the full playbook to `.agents/ui-enhancer-radar/[date]-[view]-playbook.md`. Do NOT apply any code changes. Print:
```
📋 Playbook saved. Run `/ui-enhancer-radar` on this view again when you can see it.
   No code changes were made.
```
**Then skip Phases 7c-7e entirely and go to Phase 9 (Summary).**

**If "Explain pros/cons":**
Explain briefly, then re-prompt with the same options (minus Explain).

### Gate Rule

**Do NOT proceed to Phase 7c until the user confirms they can see the view.** There is no bypass. There is no "trust the code analysis" option. If the user cannot view the screen right now, the correct action is to save the playbook for later.

---

## Phase 7c: Guided Visual Review (MANDATORY — with user looking at the view)

**This is the core of the visual audit. The user is looking at the actual view. Walk through each finding collaboratively, then collect any additional issues the user spots.**

### Part 1: Walk Through Recommended Changes

For each finding in the playbook, present it as a question while the user is looking at the view:

```
Finding #[N]: [description]

Look at [specific element] on your screen.
[Describe what to look for — e.g., "Notice the three blue icons in a row: Appearance, Privacy, and iCloud. Do they blend together?"]

What do you think?
1. **Fix this** — [brief description of the change]
2. **Compact instead** — [if applicable: preserve visual identity at smaller size]
3. **Skip** — it looks fine on screen, leave it
4. **Explain pros/cons** — walk through the tradeoff before deciding
```

**Key behavioral rules:**
- **Describe what to LOOK FOR, not what's "wrong."** Let the user's eyes decide if it's actually a problem.
- **Accept "Skip" gracefully.** Code analysis flagged it, but the user's eyes override. Mark as Accepted with reason "Looks fine on screen per user inspection."
- **Never argue** if the user says it looks fine. They are literally looking at it. You are not.
- **Be specific** about which element to examine — don't say "check the colors"; say "look at the three icons next to Appearance, Privacy, and iCloud."

### Part 2: User-Spotted Issues (MANDATORY — always ask)

After walking through all recommended findings, **always** ask:

```
questions:
[
  {
    "question": "Now that you're looking at [ViewName], do you see anything else you'd like to change? Things code analysis might miss — alignment, spacing feel, visual weight, element sizing, color choices.",
    "header": "Your eyes",
    "options": [
      {"label": "Yes, I see some things", "description": "I'll describe what I'd like to change"},
      {"label": "No, looks good", "description": "The recommended changes cover everything"},
      {"label": "Actually, let me look at dark mode too", "description": "Toggle to dark mode before deciding"}
    ],
    "multiSelect": false
  }
]
```

**If "Yes, I see some things":**
Let the user describe in free text. For each item they mention:
1. Evaluate against design rules (push-back if needed — see Push-back guidance below)
2. Add to the approved changes list
3. Generate the playbook entry

**If "Actually, let me look at dark mode too":**
Wait for user to toggle. Then re-ask about both light and dark mode issues.

### What This Phase Produces

A **final approved list** of changes — combining:
- Recommended findings the user confirmed (from Part 1)
- User-spotted issues (from Part 2)
- With all "Skip" items removed

This list is the input to Phase 7d.

---

## Phase 7d: Apply Approved Changes (execute after visual review)

**Apply ONLY the changes approved in Phase 7c. One at a time, with keep/revert after each.**

### Per-Change Flow

For each approved change:

1. **Apply the fix** (Edit tool)
2. **If testable** (accessibility fix, dead code removal, component wiring change) — write a test. If purely visual (spacing, color, layout reorder) — skip the test.
3. **Show what changed** (brief description + files modified)
4. **Direct user to check the view:**

> "Check [ViewName] in [Canvas/Simulator/device]. The [element] should now [description of visible change]."

5. **Ask:**

```
questions:
[
  {
    "question": "Fix #N applied: [description]. How does it look?",
    "header": "Review",
    "options": [
      {"label": "Keep", "description": "Looks good, move to next fix"},
      {"label": "Compact instead", "description": "Revert removal, apply compacted version preserving visual identity"},
      {"label": "Revert this fix", "description": "Doesn't look right — undo this change, continue with others"},
      {"label": "Revert all", "description": "Undo everything back to checkpoint"},
      {"label": "Stop here", "description": "Keep changes so far, skip remaining fixes"}
    ],
    "multiSelect": false
  }
]
```

**If "Keep":**
After each kept fix that removes a reference to a component/property/array, check for dead code:
1. Grep the codebase for the removed reference
2. If the definition is now unreferenced, flag it: "The definition of `[name]` at [file:line] is now unused. Clean up?"
3. If the user confirms, remove the dead definition

**If "Compact instead":**
1. Revert: `git checkout -- [files modified by this fix]`
2. Apply compaction (Phase 6c techniques)
3. Direct user to check the view again
4. Re-ask with Keep / Revert

**If "Revert this fix":**
```bash
git checkout -- [files modified by this fix]
```
Continue to next fix.

**If "Revert all":**
```bash
git checkout -- [all files modified by ui-enhancer-radar in this session]
```
Report: "All UI Enhancer changes reverted."

**If "Stop here":**
Skip remaining fixes. Offer to save remaining playbook entries.

### Batch Revert Command

Available anytime: `/ui-enhancer-radar revert`

1. Shows files changed during the session
2. Asks for confirmation (Revert all / Show diff first / Cancel)

### Safety Rules

1. **Never force-push** — revert only affects local changes
2. **Never revert past user commits** — only revert ui-enhancer-radar edits
3. **No revert if already pushed** — warn and suggest `git revert` instead

---

## Phase 7e: Pattern Sweep — Similar View Queue

**Load the pattern sweep reference:**

`Read ~/.claude/skills/ui-enhancer-radar/references/pattern-sweep.md`

Load after Phase 7d completes and at least one change was kept.

---

## Phase 7f: Refinement Loop (after all changes applied)

**After all findings are applied (or stopped early), offer the user a chance to refine the result. This is where users request tweaks like "add a background tint," "make the icon bigger," or "change the color."**

### When to trigger

After the last change in Phase 7d is resolved (Keep / Stop here), ask:

```
questions:
[
  {
    "question": "All changes applied. Would you like to refine anything?",
    "header": "Refine",
    "options": [
      {"label": "Done (Recommended)", "description": "Changes look good, move to tests"},
      {"label": "Refine an element", "description": "Tweak a specific element (color, size, spacing, background)"},
      {"label": "Compare before/after", "description": "See what changed before deciding"},
      {"label": "Question or new direction", "description": "Ask about the changes, suggest a different approach, or redirect"}
    ],
    "multiSelect": false
  }
]
```

### Refinement flow

**If "Refine an element":**
1. Ask the user what they want to change (free-form or screenshot)
2. **Evaluate the request** against the project's design system and CLAUDE.md before implementing
3. Apply the refinement
4. Show the result and re-ask with Keep / Revert / Refine again

### Push-back guidance (MANDATORY)

**Before implementing any refinement, check it against design rules. Push back when a refinement would:**

| Violation | Example | Push-back response |
|---|---|---|
| **Break colorblind safety** | "Make it green" | "Green isn't in the colorblind-safe palette — it's confused with red by ~8% of users. How about cyan or blue instead?" |
| **Break color palette** | "Use hot pink" | "That color isn't in the project's design system. The closest approved colors are pink (.pink) or purple (.purple). Which works?" |
| **Violate Dynamic Type** | "Use .system(size: 11)" | "Fixed font sizes don't scale with Dynamic Type. Use .caption or .footnote instead for the same visual size with accessibility support." |
| **Break visual consistency** | "Remove the icon circle" | "[ComponentName] uses icon circles in [N] other views. Removing it here would break consistency. Resize instead?" |
| **Undo the audit's improvement** | "Put the header back to full size" | "That would restore ~[N]pt of the space we just recovered. If you want the branding back, compact is the middle ground — it preserves identity at half the height." |
| **Break HIG compliance** | "Make the touch target 30pt" | "Apple HIG requires 44pt minimum touch targets. I can make it visually 30pt with a 44pt tap area using .contentShape()." |
| **Exceed space budget** | "Add a subtitle and description" | "Adding that text would push content below the fold. Consider putting it behind a disclosure or (?) button instead." |
| **App Store rejection risk** | See table below | Flag with "App Store risk" and cite the specific guideline |

### App Store Review guardrails

**UI changes that are known to trigger App Store rejections. Flag these BEFORE implementing:**

| Risk | Guideline | What triggers it | Push-back response |
|---|---|---|---|
| **Missing accessibility** | 2.1 (Performance) | Removing `.accessibilityLabel()`, VoiceOver support, or Dynamic Type | "Removing this accessibility label could trigger rejection under guideline 2.1. VoiceOver users won't be able to interact with this element." |
| **Non-functional UI** | 2.1 (Performance) | Adding buttons/links that do nothing, placeholder UI, "coming soon" labels | "Empty buttons or 'coming soon' UI can trigger rejection. Either wire it up or remove it." |
| **iPad layout broken** | 2.4.1 (Multitasking) | Hardcoding widths that break iPad split view, removing landscape support | "This layout would break on iPad multitasking. Use adaptive layout (ViewThatFits, size classes) instead of fixed widths." |
| **Missing back/dismiss** | 4.0 (Design) | Removing dismiss buttons from sheets, creating navigation dead ends | "Removing this dismiss button would create a dead end — users can't escape. App Review flags this under guideline 4.0." |
| **Misleading UI** | 2.3.1 (Accurate) | Icons/labels that suggest functionality the app doesn't have | "This icon implies [feature] but the app doesn't support it. App Review flags misleading UI under guideline 2.3.1." |
| **Minimum font size** | 2.1 (Performance) | Text below 11pt that doesn't scale | "Text this small may be flagged as unreadable. Use `.caption2` (11pt) as the minimum, and ensure it scales with Dynamic Type." |
| **Privacy UI** | 5.1.1 (Data Collection) | Removing permission explanations, hiding privacy controls | "Removing this explanation could violate guideline 5.1.1. Users must understand why data is collected before granting permission." |

### How to push back

1. **Explain why** — cite the specific rule (CLAUDE.md, HIG, colorblind palette, cross-view pattern)
2. **Offer an alternative** — never just say "no," always suggest what WOULD work
3. **Defer to the user** — if they insist after hearing the tradeoff, implement it with a note: "Applied as requested. Note: this deviates from [rule]."

### Diminishing returns guardrail

Track refinement count per element. After **3 refinements on the same element**:

> "This element has been refined 3 times. Further tweaks may not be visible to users. Suggest moving on — you can always revisit later. Continue refining or move on?"

This prevents infinite micro-adjustment loops while respecting the user's autonomy.

### When to skip refinement

- User chose "Done" — proceed to Phase 8 (Tests)
- Single-domain audit (e.g., `/ui-enhancer-radar space`) — refinement is less relevant for focused checks
- No visual changes were made (e.g., only performance or accessibility fixes)

---

## Phase 8: Tests

**Before asking, analyze the changes and make a recommendation.** State whether tests are needed and why, then ask.

**How to decide:**
- **No tests needed:** Pure styling (color, font, padding), layout reordering, section merging, spacing changes, renaming labels, enabling existing component parameters — recommend skipping
- **Tests recommended:** New reusable component extracted, new interaction behavior added, conditional logic changed, accessibility labels modified — recommend adding

```
questions:
[
  {
    "question": "[Recommendation: Skip/Add] — [brief reason]. Would you like to add tests?",
    "header": "Tests",
    "options": [
      {"label": "Skip tests", "description": "Verify visually by running the app"},
      {"label": "Add tests for new components", "description": "Generate tests for any extracted or new components"},
      {"label": "Add preview coverage", "description": "Ensure #Preview blocks cover all states"},
      {"label": "Full test suite", "description": "Unit tests + previews + accessibility checks"}
    ],
    "multiSelect": false
  }
]
```

**If "Skip tests"** — proceed to Phase 9. Most UI enhancer changes (spacing, color, layout reordering, compaction) are verified visually, not via tests.

### How to verify changes visually

**After applying changes, suggest a verification method:**

| Method | Best for | How |
|--------|----------|-----|
| **Xcode Canvas preview (Recommended)** | Quick visual check after each change | Open the modified file in Xcode, Canvas auto-refreshes as code changes. No build required. |
| **Run on simulator** | Full interaction testing, navigation flows | Cmd+R in Xcode. Verify the view looks right in context with real data. |
| **Run on device** | Final validation, touch targets, real-world sizing | Build to physical device for accurate colors, text sizes, and haptics. |
| **Screenshot comparison** | Before/after side-by-side | Capture simulator screenshots before and after; compare in Preview.app or Finder. |
| **Dark mode toggle** | Dark mode verification | Toggle Appearance in Xcode Canvas or Settings > Developer > Dark Appearance on device. |
| **Dynamic Type** | Accessibility text scaling | Change text size in Canvas controls or Settings > Accessibility > Display & Text Size. |

**Always mention Canvas as the recommended method** — it gives immediate feedback without building, and the user can see changes as they're applied.

### What Gets Tests

| Change Type | Test Type | Example |
|-------------|-----------|---------|
| New component extracted | Unit test (Swift Testing) | `WarrantyStatusCircle` properties and states |
| Layout change | Preview verification | `#Preview` with all states |
| Accessibility change | Accessibility audit test | VoiceOver label coverage |
| Interaction change | UI test (if warranted) | Button tap triggers expected action |
| Performance change | No test needed | Verified by profiling |

### Test Template

```swift
import Testing
@testable import [AppModule]

@Suite("[ComponentName] Tests")
struct [ComponentName]Tests {
    @Test("Renders correct state for [condition]")
    func [testName]() {
        // Arrange
        // Act
        // Assert with #expect
    }
}
```

### When to Skip Tests
- Pure styling changes (color, font, padding) — verify visually
- Layout reordering — verify via preview/screenshot
- Removing unused code — no behavior to test

---

## Phase 9: Summary & Progress Tracking

### Files Changed Summary (MANDATORY)

**Before asking about progress, always list every file modified during this audit:**

```
## Files Modified

| File | Changes |
|------|---------|
| `Sources/Views/Tools/ToolsView.swift` | Removed action bar, enabled showThemeToggle, full-width single-tool grid |
| `Sources/Views/Tools/ToolCategory.swift` | Merged input+output → importExport, renamed CSV Import → Spreadsheet Import |
| `Documentation/Development/FUTURE_FEATURES.md` | Added XLSX import item |

Total files: 3 | Lines added: X | Lines removed: Y
```

**This helps users who return to the project later know exactly what was touched.**

### Progress Question

```
questions:
[
  {
    "question": "Changes applied. Want to measure the improvement?",
    "header": "Progress",
    "options": [
      {"label": "Done for now (Recommended)", "description": "Save the report and move on"},
      {"label": "Re-audit now", "description": "Run the audit again and compare scores"},
      {"label": "Capture new screenshot", "description": "Take a fresh screenshot and compare side-by-side"}
    ],
    "multiSelect": false
  }
]
```

### Progress Report Format

```
## Progress: [ViewName]

UI Enhancer v[version]

| Domain | Before | After | Change |
|--------|--------|-------|--------|
| Space Efficiency | 4/10 | 7/10 | +3 |
| Visual Hierarchy | 6/10 | 8/10 | +2 |
| Overall | 6.4/10 | 8.1/10 | +1.7 |

Content-to-chrome ratio: 39% → 63% (+24%)
Findings resolved: 8/12
Tests added: 5
```

### Phase Progress Banner (CRITICAL — BLOCKING requirement)

**HARD GATE: After EVERY phase, EVERY commit, and EVERY build verification, your response MUST end with the progress banner + `AskUserQuestion`. If your response does not end with `AskUserQuestion`, you have violated this rule. Check before sending.**

**This includes:**
- After `git commit` → banner + AskUserQuestion (not just "committed" or "ready to push")
- After `xcodebuild build` succeeds → banner + AskUserQuestion (not just "build passed")
- After completing a phase → banner + AskUserQuestion
- After all phases done → banner + AskUserQuestion for wrap-up/next-view

After completing each phase, **always** print this banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Phase [N] of 9 complete: [phase name]

⏱  Next: Phase [N+1] — [phase name] (~[time estimate])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Phase time estimates:
| Phase | Name | Est. Time |
|-------|------|-----------|
| 1 | Interview | ~2 min |
| 2-2b | Gather Input + Classification | ~3 min |
| 3 | Screenshot Analysis | ~2 min |
| 4 | Code Analysis | ~3-5 min |
| 5 | Domain Analysis | ~5-10 min |
| 6 | Report + Compaction | ~3-5 min |
| 7-7a | Playbook + Commit Offer | ~3 min |
| 7b | Visual Inspection Gate | ~2 min (user opens view) |
| 7c | Guided Visual Review | ~5-10 min (collaborative walk-through) |
| 7d | Apply Approved Changes | ~10-15 min |
| 7e | Pattern Sweep | ~5 min |
| 7f | Refinement Loop | ~5-10 min |
| 8 | Tests | ~5-10 min |
| 9 | Summary | ~2 min |

Then immediately prompt for the next phase. **After a commit**, reprint the banner and auto-prompt. Never leave a blank prompt.

---

## Optional Features

These features are available but not run by default. User must explicitly request them.

### Device Size Simulation (Optional)

Analyze how the view behaves across device sizes by examining spacing, padding, and layout constraints in code.

```
/ui-enhancer-radar --devices
```

| Device | Width | Check |
|--------|-------|-------|
| iPhone SE | 375pt | Does content fit? Truncation? |
| iPhone 16 | 393pt | Standard layout |
| iPhone 16 Pro Max | 430pt | Extra space utilized? |
| iPad 11" | 820pt | Split view behavior? |

### Simulator Screenshot Capture (Optional)

Automatically capture a screenshot from a running simulator.

```
/ui-enhancer-radar --capture
```

```bash
# List available simulators
xcrun simctl list devices booted

# Capture screenshot
xcrun simctl io booted screenshot /tmp/ui-enhancer-radar-capture.png
```

### Before/After Screenshot Comparison

When `/ui-enhancer-radar compare` is used, or when the user wants to see visual progress:

**Automated workflow (if simulator is running):**
```bash
# Capture "after" screenshot
xcrun simctl io booted screenshot /tmp/ui-enhancer-radar-after.png
```
Then read both the original screenshot (provided at start) and the new capture, comparing side by side.

**Manual workflow (guide the user):**
1. "Take a screenshot now (Cmd+Shift+4 on macOS, or Cmd+S in Simulator)"
2. "Apply the changes"
3. "Take another screenshot"
4. "Open both in Preview.app — Window > Tile All to Left/Right for side-by-side"

**What to compare:**
- Content-to-chrome ratio: did it improve?
- Visual hierarchy: is the primary content more prominent?
- Color variety: did monochromatic sections gain differentiation?
- Space recovery: is content visible that was previously below the fold?
- Consistency: do the changes match the app's existing patterns?

### Batch Mode (`/ui-enhancer-radar batch [path]`)

Audit all views in a directory, build the View Profile in one pass, then rank views by severity.

**How it works:**
1. Glob for `*.swift` files in the specified path
2. For each file, classify the view type (Phase 2b) and run a lightweight analysis (skip interview — use default "General polish, All domains, Moderate")
3. Build the View Profile from all views simultaneously — this gives the strongest baseline for cross-view consistency
4. Rank views by overall severity score
5. Present the ranked list with top findings per view

**Output format:**
```
## Batch Audit: [path]
*[N] views analyzed | [date]*

| # | View | Type | Score | Top Finding |
|---|------|------|-------|-------------|
| 1 | PrivacyNetworkView | Settings/form | 3/10 | Monochromatic — 14/18 elements gray |
| 2 | ArchiveView | List | 5/10 | Section headers undifferentiated |
| 3 | DashboardView | Dashboard | 6/10 | Sidebar-content redundancy (macOS) |
| ... | ... | ... | ... | ... |

Run `/ui-enhancer-radar` on any view above for a full audit.
```

**After presenting the ranked list, offer a seamless transition:**

```
questions:
[
  {
    "question": "[ViewName] scored lowest ([score]/10). Start a deep audit on it now?",
    "header": "Next",
    "options": [
      {"label": "Deep audit worst view (Recommended)", "description": "Open [ViewName] in Canvas/simulator, then walk through findings visually"},
      {"label": "Pick a different view", "description": "Choose which view to audit from the ranked list"},
      {"label": "Done for now", "description": "Save batch results to handoff, audit views later"},
      {"label": "Explain more", "description": "What does a deep audit do that batch scan doesn't?"}
    ],
    "multiSelect": false
  }
]
```

**If user selects a view:** Transition directly into the full audit flow (Phase 1 interview → Phase 7 implementation). Do NOT require the user to re-invoke the skill — continue in the same session. The batch scan findings for that view become the starting point for Phase 5 (Domain Analysis), pre-populated with what the batch already found.

**Batch mode limitations:**
- No interview — uses defaults. Run individual audits for design-intent-aware analysis.
- No screenshot analysis — code-only. Provide screenshots for visual domains.
- No implementation — findings only. Run individual audits to apply fixes.
- **Transition to individual audit is seamless** — no need to re-invoke the skill.

---

## Analysis Heuristics Reference

### Content-to-Chrome Ratio

```
Chrome = status bar + nav bar + tab bar + custom headers + toolbars + search + pickers
Content = everything else

Targets:   iPhone >60% | iPad >70% | macOS >75%
Flags:     <50% Critical | 50-60% High | 60-70% Medium | >70% Good
```

### Vertical Space Budget (iPhone)

```
Viewport: ~667pt (SE) to ~852pt (Pro Max)
Status bar: 54pt (Dynamic Island) / 44pt (notch) / 20pt (none)
Nav bar: 44pt | Tab bar: 49pt + 34pt safe area

Budget: Header max 80pt | Actions max 44pt (one row) | Content >60% of remaining
```

### Visual Hierarchy Scoring

```
For each element, assign visual weight:
  Size: Large=3, Medium=2, Small=1
  Weight: Bold=2, Regular=1, Light=0
  Color: Bright=2, Standard=1, Muted=0
  Position: Top-left=3, Center=2, Bottom-right=1

Highest weight should be primary content.
If chrome/status/badge scores highest → hierarchy issue.
```

### Common Anti-Patterns

| Anti-Pattern | Example | Fix |
|-------------|---------|-----|
| Date Dominance | "Sep 1982" in title3.bold | Caption or status circle |
| Header Stack | Logo+title+subtitle+search+picker+buttons | Collapse to essentials |
| Badge Overload | 5 status badges on one row | Prioritize, hide secondary |
| Combined Controls | Two functions in one button | Separate into distinct controls |
| Permanent Hints | "Tap any field to edit" on every visit | Show once, then remove |
| Negative Numbers | "-15,892 days" for expired items | "Expired" label or icon |
| Orphaned Chrome | Parent header visible on child view | Ensure child replaces parent |
| Giant Padding | 100pt padding for 44pt floating button | Match to actual element size |
| Hardcoded Colors | `Color.white` in dark mode | Use semantic `.background` |
| Heavy View Body | 200-line body with inline logic | Extract computed properties |

---

## Edge Case Guardrails

**Known situations where the skill can cause problems if not handled carefully:**

| Edge Case | Risk | Guardrail |
|---|---|---|
| **No `#Preview` block** | Canvas verification recommended but impossible | Check for `#Preview` before recommending Canvas. If missing, offer to add one or suggest simulator instead. |
| **Shared component modification** | Changing a shared component (e.g., `ContentIllustratedHeader`) breaks all views that use it | NEVER modify shared components directly. Always apply changes at the call site. If a component needs changing, flag it as a cross-cutting change and confirm scope. |
| **Multiplatform views** | Platform-specific heuristics applied to the wrong platform; changes on one side break the other | See multiplatform guardrail below. |

### Multiplatform guardrail (MANDATORY for any view with `#if os()` blocks)

**Before making any changes to a multiplatform view:**

1. **Detect platform blocks** — grep the file for `#if os(iOS)`, `#if os(macOS)`, `#else`. If found, the view is multiplatform.
2. **Analyze each platform separately** — don't apply iPhone heuristics (44pt touch targets, 852pt viewport) to macOS code, or macOS heuristics (menu bar, sidebar, window chrome) to iOS code.
3. **After every change, check the other platform:**
   - If editing iOS-specific code: does macOS still have equivalent functionality? (e.g., dismiss buttons, theme toggle, toolbar actions)
   - If editing macOS-specific code: does iOS still have equivalent functionality?
   - If editing shared code (outside `#if` blocks): does it work on BOTH platforms?
4. **Watch for duplicate controls** — adding something to shared code that already exists in a platform-specific block creates duplicates on that platform (e.g., theme toggle in both header AND macOS toolbar).
5. **Platform-specific metrics:**

| Metric | iOS | macOS |
|---|---|---|
| Min touch/click target | 44pt | 24pt (but 44pt preferred) |
| Viewport height | 667-932pt | Variable (window) |
| Navigation | TabView, NavigationStack | NavigationSplitView, sidebar |
| Dismiss mechanism | Swipe down, X button | Close button, Esc key |
| Typography baseline | San Francisco, Dynamic Type | San Francisco, fixed sizes acceptable |
| **Large files (1000+ lines)** | Partial file reads may miss context, leading to incomplete findings | Read the full file in sections before generating findings. If the file exceeds 1000 lines, note it and focus on the visible sections. |
| **Rename cascades** | Renaming an enum case (e.g., `ToolCategory.input` → `.importExport`) requires updating every `switch` statement | After any rename, grep the codebase for the old name to verify no references remain. Build before moving to the next fix. |

---

## Decision Prompt Rules (MANDATORY — all user-facing decisions)

Every `AskUserQuestion` that presents a design decision, implementation choice, or finding resolution MUST include an **"Explain pros/cons"** option:

- **[Recommended option] (Recommended)** — [one-line description]
- **[Alternative(s)]** — [one-line description each]
- **Accept as-is** — [why this is safe to leave] (where applicable)
- **Explain pros/cons** — Walk through the tradeoffs before deciding

If the user selects "Explain pros/cons": present a brief analysis (3-5 bullets), then re-prompt with the same options (minus "Explain pros/cons").

**Never silently note findings "for future."** Every finding discovered during the audit must be presented with the full Issue Rating Table and a decision prompt (Fix / Defer / Accept / Explain pros/cons).

---

## Findings by File (auto-generated after findings table)

After the main findings table, re-group all findings by file path:

```
### Findings by File

**Sources/Views/Dashboard/DashboardView.swift** (3 findings)
- #1 (🔴 CRITICAL) — one-line summary
- #5 (🟡 HIGH) — one-line summary
- #9 (🟢 MEDIUM) — one-line summary

**Sources/Views/Components/StatusBadge.swift** (1 finding)
- #3 (🟡 HIGH) — one-line summary
```

- Sort files by highest-severity finding first (files with CRITICAL first)
- Finding numbers match the main table for cross-reference
- Skip this section entirely if fewer than 3 total findings
- For Senior/Expert users, omit the "no findings" file list

---

## Finding Resolution (MANDATORY — end of every run)

**Principle:** Every finding must reach a terminal state. "Deferred" is not terminal — it's temporary.

### Terminal States

| State | Meaning | How |
|-------|---------|-----|
| **Fixed** | Code changed, test written, committed | Phase 7 apply workflow |
| **Planned** | Added to `DEFERRED.md` with severity, effort, reason, release gate | User chose "save for later" |
| **Accepted** | User explicitly said "this is fine" | User chose "accept as-is" |

### Self-Resolution (end of every run)

After Phase 9 completes (or if the user chose "plan only"), check for unresolved findings in this session. If any exist, present:

```
You have [N] unresolved findings from this audit:

| # | Finding | Severity | Effort |
|---|---------|----------|--------|
| 1 | ... | ... | ... |

Every finding needs a decision:
1. **Fix now** — enter apply workflow for these items
2. **Plan it** — add to DEFERRED.md (tracked, reviewed before release)
3. **Accept as-is** — explicitly sign off (removed from tracking)
4. **Explain more** — walk through what each finding means
```

For each finding, the user chooses Fix / Plan / Accept. Update the handoff YAML accordingly:
- Fix → move to `findings_fixed` after apply completes
- Plan → move to `findings_planned`, write to `DEFERRED.md`
- Accept → move to `findings_accepted`

### `fix-deferred` Subcommand

When invoked via `/ui-enhancer-radar fix-deferred`:

1. Read own handoff YAML (`.agents/ui-audit/ui-enhancer-radar-handoff.yaml`)
2. Extract findings that were not applied in previous runs
3. If empty → "No deferred findings from previous ui-enhancer-radar runs."
4. If non-empty → present findings table (already rated from original run)
5. For each finding, ask: Fix now / Plan it / Accept as-is
6. Fix items enter Phase 7 apply workflow. Plan items go to DEFERRED.md. Accept items go to `findings_accepted`.
7. Update handoff YAML with resolved statuses

### `verify` Subcommand (lightweight re-check)

When invoked via `/ui-enhancer-radar verify`: Read own handoff YAML, grep for each finding's pattern in the codebase, classify as Still present / Resolved / Changed, update handoff accordingly. Print summary. Much faster than a full re-audit. See data-model-radar SKILL.md for full verify logic.

### Startup Check

On every invocation, check for `DEFERRED.md` at the project root. If it exists and contains ui-enhancer-radar items:

```
📋 You have [N] planned items from previous ui-enhancer-radar audits in DEFERRED.md.
   [M] are pre-release priority. Run `/ui-enhancer-radar fix-deferred` to resolve them.
```

### DEFERRED.md Format

If DEFERRED.md doesn't exist, create it when the first item is planned. Format:

```markdown
# Deferred Findings

Items intentionally deferred from radar audits. Review before each release.

| # | Finding | Source | Severity | Release Gate | Effort | Reason | Date | Review By |
|---|---------|--------|----------|-------------|--------|--------|------|-----------|
```

**Release Gate values:** Pre-release / Post-release / Next major

**Review By:** Default 90 days from deferral date. Capstone flags overdue items.

---

## Inline Cross-Skill Referrals

When a finding primarily belongs to another skill's domain, append this line to the finding:

`→ Deeper analysis: /[skill-name] [relevant-command]`

| If the finding involves... | Refer to |
|---------------------------|----------|
| Missing/incomplete model fields | `/data-model-radar [ModelName]` |
| Navigation dead ends or broken links | `/ui-path-radar` |
| Data loss through a complete user cycle | `/roundtrip-radar [workflow]` |
| Overall release readiness | `/capstone-radar` |

Do NOT refer to ui-enhancer-radar (that's this skill). Do NOT refer to a skill already running in this session.

---

## Cross-Skill Handoff

UI Enhancer Radar complements **data-model-radar** (model layer), **ui-path-radar** (navigation paths), **roundtrip-radar** (data safety), and **capstone-radar** (ship readiness). Findings from one skill inform the others.

### Cross-Skill Resolution (after fixing any finding)

When a fix resolves a finding that originated from ANOTHER skill's handoff, update that skill's handoff YAML. Read the other skill's handoff, find the matching finding in `findings_deferred[]` or `for_capstone_radar.blockers[]`, move it to `findings_fixed[]` (or `resolved[]`) with the fix commit hash and `resolved_by: "ui-enhancer-radar"`. This prevents stale handoffs from blocking capstone's ship recommendation.

### On Completion — Write Handoff

After completing a view audit, write/update `.agents/ui-audit/ui-enhancer-radar-handoff.yaml`:

```yaml
source: ui-enhancer-radar
date: <ISO 8601>
project: <project name>
views_audited: <count>

findings_fixed:
  - finding: "<description>"
    severity: "<CRITICAL|HIGH|MEDIUM|LOW>"
    fix_commit: "<git hash>"

findings_deferred:
  - finding: "<description>"
    severity: "<CRITICAL|HIGH|MEDIUM|LOW>"
    reason: "<why deferred>"

findings_planned:
  - finding: "<description>"
    severity: "<CRITICAL|HIGH|MEDIUM|LOW>"
    release_gate: "<Pre-release|Post-release|Next major>"
    reason: "<why deferred>"
    deferred_md_row: true

findings_accepted:
  - finding: "<description>"
    severity: "<CRITICAL|HIGH|MEDIUM|LOW>"
    reason: "<why accepted>"
    accepted_date: "<ISO 8601>"

for_ui_path_radar:
  # Visual issues that suggest structural navigation problems
  suspects:
    - view: "<view file>"
      finding: "<e.g., button with no visible action>"
      question: "<is this button wired to a destination?>"

for_roundtrip_radar:
  # Views with data binding concerns found during visual audit
  suspects:
    - workflow: "<affected workflow>"
      finding: "<e.g., form field not reflected in saved data>"
      file: "<file:line>"
      question: "<does this field round-trip correctly?>"

for_capstone_radar:
  # Visual/UX issues that affect ship readiness
  blockers:
    - finding: "<description>"
      urgency: "<CRITICAL|HIGH>"
```

**Automatic:** This file is always written so other audit skills can pick up where this one left off. No user action needed.

### On Startup — Read Handoffs (MANDATORY)

Before Phase 1 (Interview), read ALL companion handoff YAMLs that exist:

```
Read .agents/ui-audit/data-model-radar-handoff.yaml (if exists)
Read .agents/ui-audit/ui-path-radar-handoff.yaml (if exists)
Read .agents/ui-audit/roundtrip-radar-handoff.yaml (if exists)
Read .agents/ui-audit/capstone-radar-handoff.yaml (if exists)
```

**Parse `for_ui_enhancer_radar` sections.** Each companion can direct findings to this skill. Look for:
- `for_ui_enhancer_radar.suspects[]` — views another skill flagged as having visual issues
- `for_ui_enhancer_radar.priority_views[]` — views another skill wants audited first

If found, incorporate as context during the interview phase (e.g., "capstone-radar wants ToolsHelpView audited first — monochromatic icons flagged"). These are not pre-confirmed findings — verify each one independently.

**What each companion provides:**
- data-model-radar — model fields that should be displayed but aren't (missing UI for data)
- ui-path-radar — dead buttons to remove before visual audit
- roundtrip-radar — data issues that affect view correctness, computed data never displayed
- capstone-radar — priority views from ship readiness grading

If not found, proceed normally.

---

## Compliance Self-Check (MANDATORY — run before final summary)

**Before writing the final summary, handoff YAML, or session wrap-up, execute this mechanical checklist. Do NOT skip it. Do NOT summarize without running it first.**

Review your own output from this session and fill in each row:

```
| # | Gate | Check | Pass? | Gaps |
|---|------|-------|-------|------|
| 1 | Table Format | Every findings table has 8 columns (Finding, Confidence, Urgency, Risk:Fix, Risk:NoFix, ROI, Blast Radius, Fix Effort) | ? | |
| 2 | Test Gate | Every committed fix has a test — or a documented exemption (visual, dead code, singleton) | ? | |
| 3 | Visual Inspection | User confirmed they could see every view BEFORE any code changes were applied | ? | |
| 4 | Pattern Sweep | Every similar-view finding was presented with full table + decision prompt (no silent "noted for future") | ? | |
| 5 | Decision Prompts | Every design decision included "Explain pros/cons" option | ? | |
| 6 | Finding Resolution | Every finding reached terminal state (Fixed, Planned, Accepted) — no orphaned "deferred" items | ? | |
```

**If ANY gate fails**, print the gap, fix it, then proceed:
- **Visual Inspection fail:** If code was changed without user viewing the screen, flag it: "Changes to [view] were applied without visual confirmation. Verify in Canvas/simulator now, or revert."
- **Other gates:** See data-model-radar SKILL.md for full gate-checking instructions.

### User Experience Gate (applies to all findings)

Before accepting a "Deferred (Post-release)" classification, check: **When this feature fails, does the user discover it silently, eventually, or immediately and visibly?**

- **Silent** — Post-release deferral OK.
- **Eventually** — Post-release acceptable if documented.
- **Immediately and visibly** — **Cannot be Post-release. Must be Pre-release regardless of fix effort.**

### Deferred Finding Re-evaluation (on startup)

When reading existing DEFERRED.md or handoff files at startup, re-evaluate every deferred finding against the User Experience Gate. If a Post-release finding would be immediately visible to users, challenge the deferral.

---

## REMINDER (End-of-File — Survives Context Compaction)

**⚠️ VISUAL INSPECTION GATE:** NEVER modify UI code without the user visually confirming the view first. Phase 7b is non-negotiable. If the user cannot see the view, save the playbook and stop. Code analysis alone is insufficient for visual changes.

**CRITICAL:** After EVERY phase, EVERY commit, and EVERY view transition:
1. Print the progress banner (phase-level)
2. Immediately `AskUserQuestion` for the next step
3. NEVER leave a blank prompt

This reminder is placed at the end of the file because context compaction tends to preserve the beginning and end. If you are unsure whether to print the banner, **print it**.

**⚠️ CONTEXT EXHAUSTION GUARD:**

Track tool calls during the session. After **50 tool calls**, auto-downgrade new findings from `verified` to `probable (long context)`. Print a warning suggesting the user split the session. Tag findings with `confidence_note`. In the handoff YAML, add `context_exhaustion_after: [N]`. On session split, the next session re-verifies those findings FIRST and upgrades to `verified` if confirmed. See data-model-radar SKILL.md for full context exhaustion logic.

**⚠️ TABLE FORMAT GATE (MANDATORY — pre-output check before EVERY table):**

Before outputting ANY table that contains findings, issues, deferred items, or rated items, run this mechanical check:

1. Count the columns. If fewer than 8, STOP and rebuild.
2. Verify ALL of these columns exist: **Finding | Confidence | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort**
3. If any column is missing, add it before displaying.

This applies to ALL tables — no exceptions:
- Findings tables, fix plan tables, batch decision tables
- Summary tables, progress update tables, pattern sweep tables
- Deferred item tables, resolution tables, comparison tables
- ANY table where items have severity, urgency, or effort ratings

Common rationalizations that are NOT valid exceptions:
- "This is just a summary" → still needs all 8 columns
- "This is a decision prompt" → still needs all 8 columns
- "This is a quick list" → still needs all 8 columns
- "I'm showing recommendations, not findings" → still needs all 8 columns
- "The table would be too wide" → still needs all 8 columns (see terminal note below)

**Terminal width reminder:** If the 8-column table renders as a vertical stack of items instead of horizontal rows, tell the user: "The table may appear stacked. Widen your terminal window or use full-screen mode for the intended horizontal layout."

**⚠️ TEST GATE (MANDATORY — pre-commit check after EVERY fix):**

Before committing ANY fix, run this mechanical check:

1. Is there a test for this fix? If no, STOP.
2. Write the test BEFORE or ALONGSIDE the fix — not "later."
3. Run the tests: `xcodebuild test -scheme [TestScheme] -destination [simulator] -only-testing:[TestClass]` (or full test suite if quick). If any fail, fix before committing.
4. If the fix is not unit-testable (pure visual, singleton dependency, view-layer), document WHY in a code comment and note it in the commit message.

**What needs tests:**
- Any logic change (math, conditionals, data flow)
- Any model change (fields, relationships, computed properties)
- Any serialization change (backup, CSV, CloudKit mapping)
- Any state management change (lifecycle transitions, assignment cleanup)
- Any new code path (new save path, new error handling)

**What doesn't need tests (document why):**
- Pure visual changes (color, spacing, font) — verified by eye in Canvas/simulator
- Dead code removal — no behavior to test
- Singleton method calls added (e.g., adding SpotlightManager.reindexAll) — integration test, not unit-testable without protocol mock

**Common rationalizations that are NOT valid:**
- "I'll write tests after all fixes" → No. Test with each fix.
- "This is trivial" → Trivial fixes have trivial tests. Write them.
- "Tests would slow us down" → Untested fixes are unverified fixes.
- "The build passes" → Building is not testing.

**Phase 7 execution order:** 7a (Commit) → 7b (Visual Gate) → 7c (Guided Review) → 7d (Apply) → 7e (Pattern Sweep) → 7f (Refinement). Never skip 7b or 7c.

</ui-enhancer-radar>
