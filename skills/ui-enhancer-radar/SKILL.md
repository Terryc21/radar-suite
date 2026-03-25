---
name: ui-enhancer-radar
description: 'Systematic iOS/SwiftUI UI audit with design intent interview, 11-domain analysis (including Color Audit with adaptive Color Profile), element compaction, cross-view consistency checks, layout reorganization, design-aware push-back, App Store guardrails, and incremental apply with revert safety. 17 subcommands. Run /ui-enhancer-radar help for all commands. Triggers: "enhance this UI", "ui enhancer radar", "improve this view", "screen review", "ux audit".'
version: 3.1.0
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

### Domain 1: Space Efficiency

**Goal:** Maximize content-to-chrome ratio; minimize wasted vertical space.

| Check | What to Look For | Common Fix |
|-------|-----------------|------------|
| Header overhead | Custom headers stacking on nav bar | Collapse or merge headers |
| Dual button rows | Action buttons on separate line from navigation | Merge into one row |
| Section headers | Oversized section titles with icons | Reduce font size, remove decorative icons |
| Bottom padding | Excessive padding for floating elements | Reduce to actual element height + margin |
| Hints/tips | Permanent hints that should dismiss after first use | Use coach marks or remove after learning |
| Photo sections | Separate photo rows when thumbnail could be inline | Merge photo into title/header row |
| Dividers/spacers | Excessive VStack spacing or explicit Spacer() | Reduce spacing values |
| **Mergeable sections** | Small sections (1-2 items) with their own header overhead | Merge into adjacent related section |
| **Relocatable controls** | Buttons/toggles in separate rows that could fit in an existing header or toolbar | Move into header, nav bar, or existing row |
| **Redundant entry points** | Same action accessible from both a toolbar button AND a content card/row | Remove the duplicate; keep the more discoverable one |

**Layout reorganization analysis (run for every view):**

Before recommending individual element changes, check whether **reorganizing the layout** would save more space than tweaking individual elements:

1. **Count items per section** — sections with 1-2 items are candidates for merging with adjacent sections
2. **Check for orphaned controls** — buttons, toggles, or status indicators in their own row that could be absorbed into an existing element (e.g., theme toggle → header)
3. **Identify duplicate entry points** — the same action accessible from both a toolbar/action bar AND a content card below; remove the less discoverable one
4. **Measure section header overhead** — each section header costs ~40pt; merging 2 sections saves ~40pt without touching content

**Metrics:**
- Content starts at: [Y position in points from top]
- First interactive element at: [Y position]
- Content-to-chrome ratio: [percentage]
- Target: Content should start within 120pt of safe area top on iPhone

---

### Domain 2: Visual Hierarchy

**Goal:** The most important information should be the most prominent.

| Check | What to Look For | Common Fix |
|-------|-----------------|------------|
| Title prominence | Is the item/screen title the dominant element? | Ensure title is largest text |
| Competing elements | Multiple elements fighting for attention | Differentiate with size/weight/color |
| Status overload | Status indicators louder than content | Reduce to subtle badges |
| Date/number sizing | Dates or numbers displayed too large | Use caption/footnote for secondary data |
| Action vs. content | Action buttons more prominent than content | Tone down button styling |
| Truncation | Important text truncated while less important text has room | Allow wrapping or reprioritize |
| Color dominance | Bright colors on secondary elements | Reserve bright colors for primary actions |

**Analysis technique:**
1. Squint at the screenshot — what stands out?
2. That should be the primary content, not navigation chrome
3. If navigation or status draws the eye first, hierarchy is wrong

---

### Domain 3: Information Density

**Goal:** Show the right amount of information — not too sparse, not too cluttered.

| Check | What to Look For | Common Fix |
|-------|-----------------|------------|
| Sparse rows | List rows with too much whitespace | Reduce padding, show more per row |
| Dense rows | Too much crammed into one row | Progressive disclosure |
| Redundant info | Same data shown in multiple places | Remove duplicates |
| Hidden useful info | Important data behind taps/scrolling | Surface in primary view |
| Badge overload | Too many status badges on one element | Prioritize, hide secondary |
| Empty states | Large empty areas when data is missing | Collapse section |
| Nonsense values | Negative numbers, meaningless dates | Use human labels or hide |

**Density targets:**
- List row: 2-3 lines max (title + subtitle + trailing status)
- Card: 4-6 data points visible without scrolling
- Form section: 3-5 fields visible without scrolling

---

### Domain 4: Interaction Patterns

**Goal:** Every interactive element should be discoverable, predictable, and satisfying.

| Check | What to Look For | Common Fix |
|-------|-----------------|------------|
| Touch targets | Elements smaller than 44x44pt | Increase frame/padding |
| Ambiguous buttons | Buttons that look like labels | Add clear button styling |
| Combined buttons | Two features sharing one button | Separate into distinct buttons |
| Gesture-only actions | Actions only via swipe/long-press | Add visible button alternative |
| Dead ends | Screens with no clear next action | Add CTA or navigation hint |
| Feedback gaps | Actions with no visual/haptic response | Add animation or haptic |
| Scroll discovery | Content below fold with no indicator | Add hint or gradient |
| Menu depth | Important actions buried in menus | Surface frequently-used actions |

---

### Domain 5: Accessibility

**Goal:** Every user, regardless of ability, can use the view effectively.

| Check | What to Look For | Common Fix |
|-------|-----------------|------------|
| Color-only info | Information conveyed only by color | Add icon + text (triple redundancy) |
| Fixed fonts | `.system(size:)` instead of semantic | Use Dynamic Type |
| Missing labels | Images/icons without accessibility labels | Add `.accessibilityLabel()` |
| Small text | Text below 11pt that doesn't scale | Use `.caption` minimum |
| Contrast ratio | Low contrast text on backgrounds | Ensure 4.5:1 (WCAG AA) |
| VoiceOver order | Reading order doesn't match visual | Reorder or group |
| Motion | Animations without Reduce Motion check | Check accessibility setting |

---

### Domain 6: HIG Compliance

**Goal:** Follow Apple Human Interface Guidelines for platform consistency.

| Check | What to Look For | Common Fix |
|-------|-----------------|------------|
| Navigation | Custom back buttons, non-standard patterns | Use system NavigationStack |
| Tab bar | Incorrect icons or labels | Follow SF Symbol + short label |
| Sheet presentation | Missing drag indicator or dismiss | Add `.presentationDragIndicator(.visible)` |
| System colors | Hard-coded colors | Use `.primary`, `.secondary` |
| Platform differences | iOS-only patterns on macOS | Use `#if os(iOS)` |
| Safe areas | Content under notch or home indicator | Respect safe area insets |
| Standard controls | Custom controls duplicating system | Use SwiftUI standard controls |

---

### Domain 7: Dark Mode

**Goal:** The view should look correct and intentional in both light and dark mode.

| Check | What to Look For | Common Fix |
|-------|-----------------|------------|
| Hardcoded colors | `Color.white`, `Color.black`, hex values | Use semantic colors (`.primary`, `.background`) |
| Background assumptions | `.background(Color.white)` | Use `.background(Color(.systemBackground))` |
| Shadow visibility | Shadows invisible in dark mode | Use `.shadow` with adaptive opacity |
| Image contrast | Images with white/transparent backgrounds | Add dark mode variants or tinted backgrounds |
| Separator visibility | Light separators disappearing | Use `.separator` system color |
| Accent consistency | Accent colors that clash in dark mode | Test all accent colors in both modes |
| Material usage | Solid backgrounds where materials work better | Use `.ultraThinMaterial` for overlays |

**Analysis:** If screenshot provided, check if the view uses light or dark mode. If code available, grep for hardcoded colors.

---

### Domain 8: Performance Impact

**Goal:** UI patterns should not cause frame drops, excessive redraws, or memory issues.

| Check | What to Look For | Common Fix |
|-------|-----------------|------------|
| Heavy body | Complex expressions in view body | Extract to computed properties |
| Inline images | Image decoding in body | Use `AsyncCachedImage` or background decoding |
| Missing lazy | Large lists without `LazyVStack` | Switch to lazy containers |
| Excessive state | Too many `@State` vars causing redraws | Consolidate or use `@Observable` |
| Geometry readers | GeometryReader in scroll views | Use `.onGeometryChange` or remove |
| Conditional complexity | Deep if/else chains in body | Extract to `@ViewBuilder` functions |
| Animation cost | Heavy animations on low-end devices | Reduce or check Reduce Motion |

**Analysis:** Read the SwiftUI file and check for known performance anti-patterns. Flag files over 500 lines that could benefit from extraction.

---

### Domain 9: Design System Compliance

**Goal:** The view should follow the project's established design system.

**How it works:**
1. Read `CLAUDE.md` for project-level design rules
2. Read any design system files (`DESIGN_SYSTEM.md`, `StuffolioStyleGuide.swift`, etc.)
3. Compare the view against documented patterns

| Check | What to Look For | Common Fix |
|-------|-----------------|------------|
| Color palette | Colors outside the approved palette | Replace with design system colors |
| Spacing values | Non-standard spacing/padding | Use `Spacing.*` constants |
| Component usage | Custom components where standard ones exist | Replace with `SheetHeader`, `SemanticIconCircle`, etc. |
| Card styles | Cards not using `.stuffolioCard()` or `.actionCard()` | Apply standard modifiers |
| Icon style | Inconsistent icon rendering or sizing | Use `@ScaledMetric` and standard patterns |
| Section structure | Sections not using `CollapsibleSection` | Adopt standard section component |
| Sheet pattern | Sheets not using `SheetContainer` + `SheetHeader` | Apply standard sheet pattern |
| **Unused component capabilities** | Custom UI that duplicates a feature already available in a shared component | Enable the existing parameter instead of building separate UI |

**Unused capability check (run for every view):**

When the view uses a shared component (e.g., `ContentIllustratedHeader`, `SheetHeader`, `CompactSheetHeader`), read that component's `init` parameters. If the component supports a feature via a parameter that the view isn't using — but the view builds separate custom UI for the same feature — flag it:

> "[ComponentName] already supports [feature] via `parameterName: true`, but this view builds a separate [custom element] instead. Enable the parameter and remove the custom UI."

**How to check:**
1. Identify shared components used in the view (headers, containers, cards)
2. Read each component's `init` signature — look for `Bool` parameters defaulting to `false`, optional closures defaulting to `nil`
3. Compare unused parameters against custom UI in the view that serves the same purpose
4. If there's a match, recommend enabling the parameter over keeping the custom UI

**Note:** This domain is project-specific. If no design system docs are found, skip this domain and note that establishing a design system would benefit consistency.

#### Cross-View Consistency Additions (What's Missing?)

**Goal:** Detect features or controls that *should* be present based on what sibling views include. The skill checks not just what to remove or change, but what to *add* for consistency.

**How it works:**
1. Identify shared components used in the current view (e.g., `ContentIllustratedHeader`, `SheetContainer`)
2. Grep the codebase for all other callers of the same component
3. Compare which optional parameters/features each caller enables
4. If a majority of sibling views enable a feature that this view doesn't, flag it as a potential addition

**What to check:**

| Pattern | How to Detect | Recommendation Format |
|---|---|---|
| **Missing header controls** | Component used with `showThemeToggle: true` in 6/8 views but not here | "[N] of [total] views with [Component] enable [parameter]. Add it for consistency?" |
| **Missing keyboard toolbar** | iOS form/input view without `ToolbarItemGroup(placement: .keyboard)` | "This view has text inputs but no keyboard Done button" |
| **Missing dismiss button** | Sheet without close/done on macOS | "macOS sheets need an explicit dismiss button" |
| **Missing empty state** | List/collection with no `if items.isEmpty` handler | "This view shows a list but has no empty state" |
| **Missing pull-to-refresh** | Scrollable data view without `.refreshable` | "Data views should support pull-to-refresh on iOS" |
| **Missing loading state** | Async data fetch with no loading indicator | "Data loads asynchronously but no ProgressView shown" |
| **Missing error state** | Async operation with no error UI | "Network/data operations have no error feedback" |

**How to present findings:**

Always frame as a recommendation with design-intent acknowledgment:

```
"[N] of [total] views with [ComponentName] enable [feature]. This view doesn't.
 - Add [feature] (Recommended) — matches [N/total] sibling views for consistency
 - Skip — intentionally omitted for this view (e.g., [possible reason])"
```

**Possible reasons to skip (provide the relevant one):**
- Settings views may omit theme toggle because theme *is* a setting on that page
- Modal sheets may omit help because the parent view already provides context
- Simple utility views may not need pull-to-refresh if data is local-only
- Single-purpose sheets may not need customization controls

**Detection requires the Adaptive View Profile** (see below). On first audit, there's no baseline — the skill records what this view uses. On subsequent audits, the profile provides the sibling comparison data.

---

### Domain 10: Competitive Comparison (On Request)

Only runs when user provides a competitor screenshot during interview.

| Analysis | What to Compare |
|----------|----------------|
| Information density | How much data is visible without scrolling? |
| Visual hierarchy | What does each app emphasize first? |
| Interaction patterns | How many taps to accomplish the same task? |
| Space efficiency | Content-to-chrome ratio comparison |
| Unique strengths | What does each app do better? |

Output as a side-by-side comparison table.

---

### Domain 11: Color Audit

**Goal:** Ensure intentional, consistent, and effective use of color throughout the view. Detect monochromatic flatness, semantic drift, opacity inconsistencies, and missing visual differentiation.

**Adaptive Color Profile:** On first run, this domain reads CLAUDE.md and design system files to learn the project's palette rules. Findings are saved to `.agents/ui-enhancer-radar/color-profile.md` so subsequent audits can compare views against established patterns.

#### 11a. Color Inventory Table

**Build a table of every colored element in the view:**

| Element | Color | Opacity | Role | Category |
|---|---|---|---|---|
| Header bg | `.blue` | 100% | Branding | Chrome |
| Section icon | `.secondary` | 100% | Decoration | Chrome |
| Toggle (on) | `.blue` | 100% | Interactive | System |
| Row text | `.primary` | 100% | Content | Text |

**Categories:** Chrome (navigation, headers, borders), Content (user data, labels), Interactive (buttons, toggles, pickers), Status (badges, indicators), Decoration (icons, backgrounds, separators)

**How to build:** Grep the SwiftUI file for `.foregroundStyle`, `.foregroundColor`, `.fill(`, `.background(`, `.tint(`, `Color(`, `.opacity(`, and `.shadow(`. Record each with its context.

#### 11b. Color Distribution

Count unique colors and how many elements use each:

```
Color Distribution:
  .secondary / .gray:  14 elements  ████████████████  (58%)  ⚠️ DOMINANT
  .blue:                4 elements  ████              (17%)
  .primary:             3 elements  ███               (12%)
  .red:                 2 elements  ██                 (8%)
  .tertiary:            1 element   █                  (4%)
```

**Flag:** Any color family used by >50% of elements → "Monochromatic risk"
**Flag:** Any color used only once → "Orphan color — is it intentional?"

#### 11c. Monochromatic Detection (Form Flatness)

**This is the most critical check for form/settings views.** When a view is visually flat — same background, same text color, same icon color everywhere — users cannot scan it effectively.

**Color Variance Score:** Count distinct color *families* (not counting opacity variants) visible in the view, excluding system chrome (status bar, nav bar).

| Score | Distinct Colors | Assessment |
|---|---|---|
| 1-2 | Monochromatic | **Critical** — view appears as a flat, undifferentiated wall |
| 3-4 | Low variety | **High** — sections blend together, hard to scan |
| 5-6 | Adequate | **Medium** — functional but could benefit from more differentiation |
| 7+ | Good variety | **Pass** — clear visual zones |

**When monochromatic is detected, recommend (in order):**

1. **Colored section header icons** — Each section gets a semantically colored icon circle (e.g., Network = blue cloud, Privacy = red shield, Data = purple database). This alone breaks the monochrome wall into scannable zones.
2. **Section background tints** — Subtle colored backgrounds (5-8% opacity) behind each section group, using the section's accent color.
3. **Icon colorization** — Replace `.secondary` gray icons with semantically meaningful colors from the project palette (shield = red, cloud = blue, sparkles = yellow).
4. **Interactive row highlighting** — Rows with pickers, navigation chevrons, or buttons get a subtle accent indicator to distinguish from static display rows.

#### 11d. Section Distinguishability

**Can you tell where one section ends and another begins without reading the text?**

| Check | What to Look For | Fix |
|---|---|---|
| Section headers same style as row labels | Headers use same font/color as content | Make headers bolder, colored, or add accent bar |
| No visual boundary between sections | Sections separated only by thin dividers | Add section background tints or spacing |
| All icons same color | Every icon is `.secondary` gray | Assign semantic colors per section |
| Sections run together visually | No color or weight change at section boundaries | Add colored section headers or dividers |

#### 11e. Interactive vs. Static Contrast

**Can users instantly identify which elements are tappable?**

| Check | What to Look For | Fix |
|---|---|---|
| Buttons look like labels | Navigation rows with no chevron/color distinction | Add `.blue` text or chevron indicator |
| Pickers look like static text | Picker values in same color as labels | Use accent color for picker values |
| Destructive actions blend in | "Clear History" looks like "Activity History" | Use `.red` for destructive, accent for navigation |
| Toggle rows vs info rows | Both look identical except for the toggle | Add subtle leading tint or icon color |

#### 11f. Opacity Consistency

**Group elements by role and check if similar elements use matching opacities:**

| Role | Elements | Opacities Found | Consistent? |
|---|---|---|---|
| Subtitles | Row descriptions, section footers | 70%, 85%, `.secondary` | No — standardize to `.secondary` |
| Backgrounds | Section tints, hover states | 6%, 8%, 45% | Check if intentional variation |
| Shadows | Card shadows, text shadows | 10%, 20%, 30%, 35% | Acceptable range |
| Borders | Card borders, row separators | 15%, 20%, 30% | Narrow to 2 values |

**Flag:** Same-role elements with >20% opacity variance → "Inconsistent opacity"

#### 11g. Semantic Drift

**Does the same color mean different things in different parts of the view?**

| Color | Location A | Meaning A | Location B | Meaning B | Drift? |
|---|---|---|---|---|---|
| `.blue` | Sidebar | "Own" phase | Dashboard | Primary action | Minor |
| `.orange` | Sidebar | "Dispose Of" phase | Dashboard | Import/Export | Yes — different semantic |

**Flag:** Same color with clearly different meanings in adjacent or related areas.

#### 11h. Light/Dark Mode Delta

For each element, note whether color/opacity changes between modes:

| Check | What to Look For | Fix |
|---|---|---|
| Hardcoded `.white` or `.black` | Won't adapt to mode switch | Use `.primary`, `.background`, semantic colors |
| Hex colors without dark variant | `Color(hex: "#FFFFFF")` in both modes | Use `Color(.systemBackground)` or asset catalog |
| Shadows invisible in dark mode | `Color.black.opacity(0.1)` disappears | Use adaptive opacity or colored shadows |
| Tints that wash out | Light tints (5% opacity) invisible on dark backgrounds | Increase dark mode opacity (e.g., 3% light → 8% dark) |

#### 11i. Contrast Pairs (WCAG AA)

Check text-on-background combinations:

| Pair | Ratio Needed | Common Failures |
|---|---|---|
| Body text on background | 4.5:1 | `.secondary` on `.systemGroupedBackground` in light mode |
| White text on colored cards | 4.5:1 | White on `.yellow` or `.cyan` (low contrast) |
| Caption text on tinted backgrounds | 4.5:1 | `.tertiary` on subtle tints |
| Interactive text on background | 3:1 (large text) | `.blue` on dark backgrounds can be low |

#### 11j. Design System Compliance

**Compare actual color usage against project rules:**

1. Read CLAUDE.md for palette restrictions (e.g., "never use green", "use AccessibleColor.sf3aYellow instead of .yellow")
2. Read design system files for approved colors
3. Flag any color not in the approved palette
4. Flag any use of restricted colors

### Adaptive View Profile

The View Profile is a persistent file that grows with each audit, enabling cross-view consistency checks for both color (Domain 11) and component usage (Domain 9). Stored at `.agents/ui-enhancer-radar/view-profile.md`.

**On first audit of a project:**

1. Check for `.agents/ui-enhancer-radar/view-profile.md` — if it doesn't exist, create it
2. Record the Color Inventory Table, opacity conventions, and semantic color map from this audit
3. Record which shared components the view uses and which optional parameters it enables
4. Note the project's palette rules from CLAUDE.md

**On subsequent audits:**

1. Load the View Profile
2. **Color comparison:** Flag views that deviate from established color/opacity conventions
3. **Component comparison:** Flag views that don't enable features most sibling views use
4. Update the profile with any new patterns discovered
5. If a previously recorded convention has changed in the majority of views, update the convention (not the outlier)

**View Profile format (`.agents/ui-enhancer-radar/view-profile.md`):**

```markdown
# UI Enhancer View Profile
*Last updated: [date] | Views audited: [count]*

## Project Palette
[Colors from CLAUDE.md or design system]

## Color Conventions
| Role | Standard Color | Standard Opacity | Views Using |
|---|---|---|---|
| Section header icon | Semantic per section | 100% | DashboardView, ToolsView |
| Row subtitle | .secondary | 100% | SettingsView, ItemDetailView |
| Card shadow | sectionColor | 20% resting | DashboardView |

## Semantic Color Map
| Color | Meaning | Consistent Across Views? |
|---|---|---|
| .blue | Primary actions, Own phase | Yes |
| .orange | Dispose Of, data flow | Yes |

## Component Usage
| Component | Parameter | Enabled In | Not Enabled In | Adoption |
|---|---|---|---|---|
| ContentIllustratedHeader | showThemeToggle | Dashboard, Tools, Reports, MyProducts, StuffScout, LegacyWishes | Settings, Archive | 75% |
| ContentIllustratedHeader | showHelp | Dashboard, Tools, Reports | Settings, Archive, MyProducts | 50% |
| ContentIllustratedHeader | solidBackground | Dashboard | All others | 12% (intentional — dashboard only) |
| SheetContainer | showHelp | AddItem, StuffScout, Backup | Restore, Export | 60% |

## Detected Patterns
| Pattern | Views Using | Views Missing | Notes |
|---|---|---|---|
| Keyboard Done toolbar | All form views | — | Universal |
| Pull-to-refresh | Dashboard, MyProducts | Reports, Archive | Data views only |
| Empty state handling | MyProducts, Dashboard | Loans, Locations | Gap — should add |

## Refinement History
| Date | View | Change | Kept? | Notes |
|---|---|---|---|---|
| 2026-03-22 | DashboardView | VStack spacing 24→16→12pt | Kept 12pt | User wanted tighter |
| 2026-03-22 | DashboardView | Solid header background | Kept | More punch in light mode |
| 2026-03-22 | DashboardView | Quick Stats collapsed padding -8pt | Kept | Closer to MY STUFF |
```

**Refinement History** records what was tried during the refinement loop (Phase 7c) — both kept and reverted changes. This serves two purposes:
1. If the user returns and says "I liked the spacing we tried last time," the history shows what values were used
2. It reveals patterns — if the user consistently asks for tighter spacing, future audits should start with tighter recommendations

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

## Phase 6b: Content & Identity Preservation Check (MANDATORY before removing UI)

**When any finding recommends removing or replacing a UI element, check whether it contained informational text OR visual identity elements that serve a purpose beyond decoration.**

### What to check

For each element being removed, ask:
- Does it contain **explanatory text** (descriptions, subtitles, instructions)?
- Does it contain **status information** (counts, states, labels)?
- Would a **first-time user** lose context about what this screen does?
- Does it contain **branding elements** (app icon, section icon, colored backgrounds) that establish visual identity?
- Does it contribute to **visual consistency** across the app (same component used in multiple views)?
- Is it tagged `[PRESERVE]` from the Design Intent interview?

**If text content would be lost**, the text must be **relocated, not deleted**. Propose one of these options to the user:

**If visual identity would be lost** (icons, colors, branded backgrounds), route to **Phase 6c (Element Compaction)** instead of removing — compaction preserves identity at reduced size.

### Relocation options

| Option | When to use | Example |
|--------|------------|---------|
| **Help button (`?`)** | Descriptive text that experienced users don't need | Toolbar `?` button → popover with description |
| **Info icon (`i`)** | Context that's useful but not essential to scan | Small `ℹ️` next to a title, expands on tap |
| **First-visit only** | Onboarding text that should disappear after learning | Show once via `@AppStorage`, hide after first visit |
| **Nav bar subtitle** | Short taglines (< 40 chars) | `.navigationSubtitle("Identify & Appraise")` |
| **Tooltip / help text** | Secondary info on macOS | `.help("Identify and value antiques...")` |
| **Keep as-is** | The text is truly decorative and losing it is fine | Marketing copy repeated elsewhere |

### How to present

After listing findings but before implementation, flag any content at risk:

```
questions:
[
  {
    "question": "Removing [element] would also remove the text '[text]'. Where should this information go?",
    "header": "Content",
    "options": [
      {"label": "Drop it (Recommended)", "description": "The text isn't needed — users understand from context"},
      {"label": "Help button (?)", "description": "Add a toolbar help button that shows this on tap"},
      {"label": "First-visit only", "description": "Show on first use, hide after"},
      {"label": "Keep the element", "description": "Don't remove this element after all"}
    ],
    "multiSelect": false
  }
]
```

**If "Keep the element"** — remove that finding from the playbook and adjust space savings estimates.

### Skip this check when

- The removed element contained only a **title that's already in the nav bar**
- The removed element contained only **color/icon decoration** with no text
- The text is **displayed elsewhere on the same screen** (e.g., in a banner below)

---

## Phase 6c: Element Compaction (MANDATORY when recommending removal of visual elements)

**When a finding recommends removing a decorative or branding element for space efficiency, the user may want to preserve the element's visual identity at a smaller footprint. Always offer compaction as an alternative to removal.**

### Cross-View Consistency Check (run before compaction decisions)

Before recommending removal or compaction of any visual element, check whether it's part of a cross-view pattern:

1. **Grep the codebase** for the component name (e.g., `ContentIllustratedHeader`, `SheetHeader`, custom component names)
2. **Count how many views** use the same component
3. **If used in 3+ views**, flag it as a **consistency pattern**:

```
⚠️ Cross-view pattern detected: [ComponentName] is used in [N] views:
  - ViewA.swift (line X)
  - ViewB.swift (line Y)
  - ViewC.swift (line Z)

Removing it from this view would break visual consistency.
Recommendation: Compact (not remove), or apply the change across all [N] views.
```

**If a consistency pattern is detected:**
- Default to **Compact** instead of Remove
- If the user chooses Remove, warn: "This will make [ViewName] visually inconsistent with [N] other views that use [ComponentName]. Apply the same change to all, or just this one?"
- Offer: "Apply to all [N] views" / "Just this view" / "Cancel"

### When to trigger

This check runs when ANY finding recommends removing:
- Illustrated headers (ContentIllustratedHeader, custom banners)
- Branded sections with icons, backgrounds, or imagery
- Photo rows, hero images, or visual feature cards
- Any element the user may consider part of the view's visual identity
- Any element tagged `[PRESERVE]` during the Design Intent interview

### What to ask

For each element recommended for removal, present compaction as the default:

```
questions:
[
  {
    "question": "The [element] uses ~[N]pt. How would you like to handle it?",
    "header": "Element",
    "options": [
      {"label": "Compact (Recommended)", "description": "Preserve visual identity at reduced size (~[M]pt savings)"},
      {"label": "Remove entirely", "description": "Maximum space savings (~[N]pt recovered)"},
      {"label": "Keep as-is", "description": "No change to this element"}
    ],
    "multiSelect": false
  }
]
```

### Compaction techniques by element type

| Element Type | Full Size | Compaction Techniques | Target Size |
|---|---|---|---|
| **Illustrated header** (icon + title + subtitle + background) | ~100-140pt | Inline icon (28pt) + title only, reduce background height, drop subtitle | ~44-56pt |
| **Section header** (decorative circle + title) | ~40-48pt | Smaller circle (18pt), reduce font, tighten padding | ~28-32pt |
| **Photo/hero row** | ~80-120pt | Thumbnail (40pt) inline with title instead of full-width | ~44pt |
| **Status banner/card** | ~60-80pt | Compact badge or chip instead of card | ~28-36pt |
| **Tip/hint section** | ~60-100pt | Collapsible disclosure, or single-line with `(i)` | ~20-44pt |
| **Feature card** | ~80-120pt | Reduce padding, smaller icon, tighter text | ~48-64pt |

### How to generate compact code

When "Compact" is selected, apply these reductions in order until target height is reached:

1. **Reduce icon size** — e.g., 48pt → 28pt, 32pt → 20pt
2. **Inline layout** — switch from VStack to HStack where possible
3. **Drop secondary text** — remove subtitles, taglines, descriptions (relocate per Phase 6b if needed)
4. **Tighten spacing** — reduce padding and VStack/HStack spacing by 30-50%
5. **Reduce background** — shrink or remove decorative backgrounds, keep accent color as border or tint
6. **Simplify** — remove shadows, reduce corner radius, flatten visual layers

### Playbook format for compaction

When compaction is chosen, the playbook entry should show the before/after with measurements:

```
### Fix #N: Compact [element name]

**File:** `Sources/Views/[file].swift`
**Lines:** [range]

**Before:** (~[N]pt height)
[exact code block]

**After:** (~[M]pt height, [savings]pt saved)
[exact replacement code — compacted version]

**Why:** Preserves visual identity while reclaiming [savings]pt of vertical space

**Test:** Verify element is visually recognizable at smaller size on iPhone SE and Pro Max
```

### When NOT to compact

- The element is **purely redundant** (same title shown in nav bar AND header AND banner) — removal is better
- The element **cannot be meaningfully reduced** (already near minimum viable size)
- The user explicitly chose "Remove entirely"

---

## Phase 6d: Visual Compensation Check (MANDATORY when removing visual elements)

**When findings remove headers, icons, colored elements, or decorative components, the result may look visually flat. Before implementing, check whether the remaining UI needs visual enrichment to compensate.**

### When to trigger

This check runs when ANY finding:
- Removes a header component (SheetHeader, ContentIllustratedHeader, custom headers)
- Removes colored backgrounds, accent bars, or decorative elements
- Consolidates multiple visual sections into fewer elements
- Strips icons or imagery from the view

### What to ask

```
questions:
[
  {
    "question": "Removing [element] will reduce visual richness. How would you like to compensate?",
    "header": "Visual",
    "options": [
      {"label": "Colored section headers (Recommended)", "description": "Add colored icon circles to section headers for visual anchoring"},
      {"label": "Per-section accent colors", "description": "Use project palette to differentiate sections (icons, borders, or backgrounds)"},
      {"label": "Both \u2014 headers + accents", "description": "Full treatment: colored header icons + per-section accent colors from project palette"},
      {"label": "No compensation needed", "description": "The view looks fine without it"}
    ],
    "multiSelect": false
  }
]
```

### Compensation techniques (by view type)

| View Type | Best Compensation | Why |
|-----------|------------------|-----|
| **Help / reference** | Colored icon circles in section headers | Provides visual anchoring without distracting from linear reading |
| **Dashboard / overview** | Colored card backgrounds + accent bars | Scanning views benefit from strong visual differentiation |
| **Form / input** | Subtle section tints or header icons | Keep focus on inputs, use color sparingly |
| **Detail / inspector** | Accent bars on cards + status colors | Help users scan for specific information |
| **List / table** | Alternating row tints or leading color indicators | Help distinguish items at a glance |

### Color palette for compensation

**Always check the project's design system first.** Before applying any colors:

1. Read `CLAUDE.md` for documented color rules or palette restrictions
2. Search for design system files (`DESIGN_SYSTEM.md`, `StyleGuide.swift`, `Colors.swift`, `Theme.swift`)
3. Check for existing color constants or enums in the codebase (`grep` for `static let`, `Color(`, `UIColor(`)

**If a project palette exists:** Use only colors from that palette. Follow any restrictions (e.g., "never use green", "use semantic colors only"). Reference the project's color constants in code, not raw SwiftUI colors.

**If no project palette exists:** Use this default set, which provides good contrast and variety across common forms of color vision:

| Color | Use for |
|-------|---------|
| Blue | Primary, required, actions |
| Purple | Secondary, optional, analysis |
| Teal/Cyan | Tools, utilities, coverage |
| Orange | Media, images, discovery |
| Pink | Support, resources, special |
| Yellow | Tips, highlights, warnings |
| Gray | Notes, neutral, settings |

### When to skip

- The view is already visually rich after removal (e.g., content itself has color/imagery)
- Only minor chrome was removed (a single label or small spacer)
- The user explicitly chose "No compensation needed"

---

## Phase 7: Implementation Playbook

**MANDATORY: Before ANY code edits, complete Phase 7a (User Commit Offer) and Phase 7b (Incremental Apply). These are NOT optional. Skipping them removes the user's ability to safely revert.**

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

## Phase 7b: Incremental Apply with Keep/Revert (MANDATORY — execute after EACH finding)

**This phase is NOT optional. Each finding is applied ONE AT A TIME. After each one, the user decides whether to keep it before the next finding is applied. Never batch-apply multiple findings without asking.**

### Why This Is Mandatory

Without per-finding review, users lose the ability to:
- Accept some improvements but reject others
- See the effect of each change before the next one lands
- Revert a single change that looked wrong without losing everything

### Per-Finding Flow

For each finding in the playbook:

1. **Apply the fix** (Edit tool)
2. **If testable** (accessibility fix, dead code removal, component wiring change) — write a test. If purely visual (spacing, color, layout reorder) — skip the test, visual verification via screenshot is the appropriate check.
3. **Show what changed** (brief description + files modified + test if added)
4. **Ask the user:**

```
questions:
[
  {
    "question": "Fix #N applied: [description]. Keep this change?",
    "header": "Review",
    "options": [
      {"label": "Keep", "description": "This looks good, move to next fix"},
      {"label": "Compact instead", "description": "Revert removal, apply compacted version preserving visual identity"},
      {"label": "Revert this fix", "description": "Undo this specific change, continue with others"},
      {"label": "Revert all", "description": "Undo everything back to checkpoint"},
      {"label": "Stop here", "description": "Keep changes so far, skip remaining fixes"}
    ],
    "multiSelect": false
  }
]
```

**If "Keep":**
After each kept fix that removes a reference to a component/property/array, check for dead code:
1. Grep the codebase for the removed reference (e.g., if you removed `quickActionIconsRow` from the body, grep for `quickActionIconsRow`)
2. If the definition is now unreferenced, flag it: "The definition of `[name]` at [file:line] is now unused. Clean up?"
3. If the user confirms, remove the dead definition as part of the same fix

**If "Compact instead":**
1. Revert the removal: `git checkout -- [files modified by this fix]`
2. Apply compaction using the techniques from Phase 6c (reduce icon size, inline layout, tighten spacing, drop secondary text)
3. Show the compacted result and re-ask with Keep / Revert options

**If "Revert this fix":**
```bash
# Undo the last edit(s) for this specific fix
git checkout -- [files modified by this fix]
```
Then continue to the next fix.

**If "Revert all":**
```bash
git checkout -- [all files modified by ui-enhancer-radar in this session]
```
Report: "All UI Enhancer changes reverted."

**If "Stop here":**
Skip remaining fixes. Offer to save the remaining playbook entries to a file for later.

### Batch Revert Command

Available anytime after an enhancement session:

```
/ui-enhancer-radar revert
```

This command:
1. Shows files changed during the session
2. Asks for confirmation:

```
questions:
[
  {
    "question": "Revert UI Enhancer changes? This will undo modifications made during this session.",
    "header": "Revert",
    "options": [
      {"label": "Revert all", "description": "Undo all UI Enhancer changes"},
      {"label": "Show diff first", "description": "Show what would be reverted before deciding"},
      {"label": "Cancel", "description": "Keep current changes"}
    ],
    "multiSelect": false
  }
]
```

### Safety Rules

1. **Never force-push** — revert only affects local changes
2. **Never revert past user commits** — only revert ui-enhancer-radar edits
3. **No revert if already pushed** — if changes were pushed to remote, warn and suggest `git revert` instead

---

## Phase 7c: Refinement Loop (after all findings applied)

**After all findings are applied (or stopped early), offer the user a chance to refine the result. This is where users request tweaks like "add a background tint," "make the icon bigger," or "change the color."**

### When to trigger

After the last finding in Phase 7b is resolved (Keep / Stop here), ask:

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

**After EVERY phase and EVERY commit, your NEXT output MUST be the progress banner followed by the next-phase `AskUserQuestion`. Do not output anything else first. Do not leave a blank prompt.**

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
| 7 | Implementation | ~10-20 min |
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

**Batch mode limitations:**
- No interview — uses defaults. Run individual audits for design-intent-aware analysis.
- No screenshot analysis — code-only. Provide screenshots for visual domains.
- No implementation — findings only. Run individual audits to apply fixes.

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

## Cross-Skill Handoff

UI Enhancer Radar complements **data-model-radar** (model layer), **ui-path-radar** (navigation paths), **roundtrip-radar** (data safety), and **capstone-radar** (ship readiness). Findings from one skill inform the others.

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

### On Startup — Read Handoffs

Before Phase 1 (Interview), check for handoff files:
- `.agents/ui-audit/ui-path-radar-handoff.yaml` — dead buttons to remove before visual audit
- `.agents/ui-audit/roundtrip-radar-handoff.yaml` — data issues that affect view correctness

If found, incorporate as context during the interview phase (e.g., "ui-path-radar found this button is dead — should we remove it?"). If not found, proceed normally.

---

## REMINDER (End-of-File — Survives Context Compaction)

**CRITICAL:** After EVERY phase, EVERY commit, and EVERY view transition:
1. Print the progress banner (phase-level)
2. Immediately `AskUserQuestion` for the next step
3. NEVER leave a blank prompt

This reminder is placed at the end of the file because context compaction tends to preserve the beginning and end. If you are unsure whether to print the banner, **print it**.

**NEVER simplify the Issue Rating Table.** Every finding shown to the user MUST use the full table format with ALL columns (Confidence, Urgency, Risk: Fix, Risk: No Fix, ROI, Blast Radius, Fix Effort). No abbreviated tables for summaries, progress updates, or layer transitions. If you are presenting findings, use the full table.

</ui-enhancer-radar>
