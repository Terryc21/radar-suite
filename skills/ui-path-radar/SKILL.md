---
name: ui-path-radar
description: 'UI path tracer for SwiftUI/UIKit apps. 5-layer audit: discover entry points, trace flows, detect dead ends and broken promises, evaluate UX impact, verify data wiring. Supports targeted trace, diff against previous audits, and handoff to planning skills. Triggers: "trace UI paths", "find dead ends", "/ui-path-radar".'
version: 3.4.0
author: Terry Nyberg
license: MIT
allowed-tools: [Read, Grep, Glob, Bash, Edit, Write, AskUserQuestion]
metadata:
  tier: execution
  category: analysis
---

# UI Path Radar

> **Quick Ref:** 5-layer UI path audit: discover entry points → trace flows → detect issues → evaluate UX → verify data wiring. Output: `.ui-path-radar/` in project root.

You are performing a systematic UI path audit on this SwiftUI application.

**Required output:** Every finding MUST include Urgency, Risk, ROI, and Blast Radius ratings using the Issue Rating Table format. Do not omit these ratings.

## Quick Commands

| Command | Description |
|---------|-------------|
| `/ui-path-radar` | Full 5-layer audit |
| `/ui-path-radar layer1` | Discovery only — find all entry points |
| `/ui-path-radar layer2` | Trace — trace critical paths |
| `/ui-path-radar layer3` | Issues — detect problems across codebase |
| `/ui-path-radar layer4` | Evaluate — assess user impact |
| `/ui-path-radar layer5` | Data wiring — verify real data usage |
| `/ui-path-radar trace "A → B → C"` | Trace a specific user flow path |
| `/ui-path-radar diff` | Compare current findings against previous audit |
| `/ui-path-radar fix` | Generate fixes for found issues |
| `/ui-path-radar status` | Show audit progress and remaining issues |

## Overview

UI Path Radar uses a 5-layer approach:

| Layer | Purpose | Est. Time (small / large codebase) | Output |
|-------|---------|-------------------------------------|--------|
| **Layer 1** | Pattern Discovery — Find all UI entry points | ~1-2 min / ~3-5 min | Entry point inventory |
| **Layer 2** | Flow Tracing — Trace critical paths in depth | ~2-3 min / ~5-8 min | Detailed flow traces |
| **Layer 3** | Issue Detection — Categorize issues across codebase | ~2-4 min / ~5-10 min | Issue catalog |
| **Layer 4** | Semantic Evaluation — Evaluate from user perspective | ~1-2 min / ~3-5 min | UX impact analysis |
| **Layer 5** | Data Wiring — Verify features use real data | ~2-4 min / ~5-10 min | Data integrity report |

> **Codebase size guide:** Small = <200 files, Large = 500+ files. Estimate from `find Sources -name "*.swift" | wc -l`.

## Issue Categories

| Category | Severity | Description |
|----------|----------|-------------|
| Dead End | 🔴 CRITICAL | Entry point leads nowhere |
| Wrong Destination | 🔴 CRITICAL | Entry point leads to wrong place |
| Mock Data | 🔴 CRITICAL | Feature shows fabricated data when real data exists |
| Incomplete Navigation | 🟡 HIGH | User must scroll/search after landing |
| Missing Auto-Activation | 🟡 HIGH | Expected mode/state not set |
| Unwired Data | 🟡 HIGH | Model data exists but feature ignores it |
| Platform Parity Gap | 🟡 HIGH | Feature works on one platform, broken on another |
| Promise-Scope Mismatch | 🟡 HIGH | Specific CTA opens generic/broad destination |
| Buried Primary Action | 🟡 HIGH | Primary button hidden below scroll fold |
| Dismiss Trap | 🟡 HIGH | Only visible action is Cancel/back, no forward path |
| Context Dropping | 🟡 HIGH | Navigation path loses item context between platforms or via notifications |
| Notification Nav Fragility | 🟡 HIGH | Untyped NotificationCenter dict used for navigation context |
| Sheet Presentation Asymmetry | 🟡 HIGH | Different presentation mechanisms per platform for same feature |
| Two-Step Flow | 🟢 MEDIUM | Intermediate selection required |
| Missing Feedback | 🟢 MEDIUM | No confirmation of success |
| Gesture-Only Action | 🟢 MEDIUM | Feature only accessible via swipe/long-press |
| Loading State Trap | 🟢 MEDIUM | Spinner with no cancel/timeout/escape |
| Stale Navigation Context | 🟢 MEDIUM | Cached context with no clearing/validation mechanism |
| Inconsistent Pattern | ⚪ LOW | Same feature accessed differently |
| Orphaned Code | ⚪ LOW | Feature exists but no entry point |

## Design Principles

### 1. Honor the Promise
> When a button/card says "Do X", tapping it should DO X.
> Not "go somewhere you might find X."

### 2. Context-Aware Shortcuts
> If user's context implies a specific item, skip pickers.

### 3. State Preservation
> When navigating to a feature, set up the expected state.

### 4. Consistent Access Patterns
> Same feature should be accessed the same way everywhere.

### 5. Data Integrity
> If the app tracks data relevant to a feature, the feature must use it.
> Never show mock/hardcoded data when real user data exists.
> Never ignore model relationships that would improve decisions.

### 6. Primary Action Visibility
> The primary action must be visible without scrolling after the user completes the key interaction.
> Pin Save/Continue/Done buttons outside ScrollView or in toolbar. Never bury them below tall content.

### 7. Escape Hatch
> Every view must have a visible way to go forward OR back. Cancel alone is not enough after user completes a step.

### 8. Gesture Discoverability
> Every action available via gesture (swipe, long-press) should also be accessible via a visible button or menu.

### Freshness

Base all findings on current source code only. Do not read or reference
files in `.agents/`, `scratch/`, or prior audit reports. Ignore cached
findings from auto-memory or previous sessions. Every finding must come
from scanning the actual codebase as it exists now.

---

## Before Starting

Ask the user:

**Question 1: "How should fixes be handled?"**
- **Auto-fix safe items (Recommended)** — Apply isolated, low-blast-radius fixes
  automatically. Present cross-cutting fixes and design decisions as a plan.
- **Plan only** — Do not change any code. Present all findings as a plan.

**Question 2: "How should results be delivered?"**
- **Display only (Recommended)** — Show findings in the conversation. No file written.
- **Report only** — Write findings to `.ui-path-radar/[DATE]-audit.md`.
  Minimal conversation output.
- **Display and report** — Show findings in the conversation AND write to file.

**Question 3: "What's your experience level with Swift/SwiftUI?"**
- **Beginner** — New to Swift or SwiftUI. Explain findings in plain language with analogies. Define technical terms on first use (e.g., "a sheet — a screen that slides up from the bottom").
- **Intermediate** — Comfortable with SwiftUI basics. Use standard terminology but explain non-obvious patterns (e.g., why an enum-based sheet router matters).
- **Experienced (Recommended)** — Fluent with SwiftUI, navigation, state management. Concise findings, no definitions, focus on what's wrong and where.
- **Senior/Expert** — Deep expertise. Terse output, file:line references only, skip explanations — just the findings table and code-level details.

**Question 4: "Will you be stepping away during the audit?"**
- **I'll be here (Recommended)** — Normal mode. Permission prompts may appear for writes/edits.
- **Hands-free (walk away safe)** — Restricts to read-only tools (Read, Grep, Glob) for Layers 1-4. No Bash, no Edit, no Write — nothing that would trigger a permission prompt. Layer 5 and fix mode are deferred until you return. Results are held in conversation output.
- **Pre-approved** — You have already configured Claude Code permissions for this session (see Permission Setup below). Run at full speed without restriction.

### Permission Modes

#### Normal Mode
- Read any file without asking.
- Edit files only if user chose auto-fix and the fix is isolated to the audited flow.
- Build and run tests without asking.
- If a fix breaks the build, restore the original code and document as "Documented."

#### Hands-Free Mode
**Guarantees no blocking prompts.** The skill will ONLY use these tools during Layers 1-4:
- `Read` — read file contents
- `Grep` — search file contents
- `Glob` — find files by pattern

It will NOT use:
- `Bash` — no shell commands (grep via Grep tool instead)
- `Edit` / `Write` — no file modifications
- `AskUserQuestion` — no interactive prompts

When the audit completes (or hits a layer that needs restricted tools), it prints:
```
⏱ Hands-free audit complete through Step [N] of 5: [plain description of what was completed].
  Steps requiring your input: [list with plain descriptions]
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

> **Tip:** If you frequently run audit-only layers (1-4), the Hands-free mode eliminates permission prompts entirely without changing any settings.

### Context Budget

If context is running low, prioritize in this order:
1. Finish the current phase
2. Emit findings for what you've audited so far
3. Skip remaining unaudited flows

Never start auditing a new flow you can't finish.

### Experience-Level Adaptation

Adjust ALL output (findings, explanations, progress updates, summaries) based on the user's experience level:

#### Beginner
- **Finding descriptions**: Use plain language with real-world analogies. Example: "The 'View Warranty' button opens an empty screen — like clicking a door that leads to a blank wall."
- **Technical terms**: Define on first use in parentheses. Example: "a sheet (a screen that slides up from the bottom)"
- **Flags/categories**: Explain what each means and why it matters. Don't assume the user knows what "dead end" or "promise mismatch" means in a code context.
- **File references**: Include but explain what the file does. Example: "DashboardView.swift (the main home screen) line 118"
- **Recommendations**: Explain the "why" behind each suggestion. Don't just say "add navigation" — explain what the user would experience.
- **Tables**: Use the compact 4-column format (# / Finding / Urgency / Fix Effort). Put full details in prose below each finding.

#### Intermediate
- **Finding descriptions**: Use standard SwiftUI terminology (sheet, NavigationLink, @State) without defining them, but explain non-obvious patterns. Example: "The sheet routing enum has a `.warranty` case but no matching handler in `sheetContent(for:)` — so tapping 'View Warranty' opens nothing."
- **File references**: Standard file:line format.
- **Recommendations**: Explain the approach, not the basics. "Add a case to the switch in `sheetContent(for:)` that presents `WarrantyDetailView`."
- **Tables**: Full 8-column format with brief finding descriptions.

#### Experienced (default)
- **Finding descriptions**: Concise. "Dead end: `.warranty` case unhandled in `DashboardView+SheetContent.swift:194`"
- **No definitions or explanations** of standard patterns.
- **Recommendations**: What to fix, where. No "why" unless the fix is non-obvious.
- **Tables**: Full 8-column format, terse findings.

#### Senior/Expert
- **Finding descriptions**: Minimal. "Dead end: `.warranty` → unhandled @ DashboardView+SheetContent:194"
- **No prose between tables**. Findings table IS the output.
- **Recommendations**: File:line + one-line fix description only.
- **Skip**: Progress explanations, design principle citations, category definitions. Just the data.
- **Tables**: Full 8-column format, maximally compressed finding text.

#### Enforcement Rule
At the **start of each layer**, silently check: "Am I writing at the selected experience level?" If the user selected Intermediate, findings must explain non-obvious patterns. If Senior/Expert, findings must be terse. Do NOT drift toward "Experienced" as a default. When in doubt, re-read the level descriptions above before writing findings.

---

## Execution Instructions

### Skill Introduction (MANDATORY — run before anything else)

On first invocation, ask the user two questions in a single `AskUserQuestion` call:

**Question 1: "What's your experience level with Swift/SwiftUI?"**
- **Beginner** — New to Swift. Plain language, analogies, define terms on first use.
- **Intermediate** — Comfortable with SwiftUI basics. Standard terms, explain non-obvious patterns.
- **Experienced (Recommended)** — Fluent with SwiftUI. Concise findings, no definitions.
- **Senior/Expert** — Deep expertise. Terse, file:line only, skip explanations.

**Question 2: "Would you like a brief explanation of what this skill does?"**
- **No, let's go (Recommended)** — Skip explanation, proceed to audit.
- **Yes, explain it** — Show a 3-5 sentence explanation adapted to the user's experience level (see below), then proceed.

**Experience-adapted explanations for UI Path Radar:**

- **Beginner**: "UI Path Radar checks every button, link, and menu item in your app to make sure they actually work. Think of it like walking through every door in a building to verify none are locked, lead nowhere, or open to the wrong room. It finds 'dead ends' (buttons that do nothing), 'broken promises' (a button says 'Export PDF' but opens the wrong screen), and missing features. It runs in 5 layers, each going deeper — from finding all the buttons, to tracing what happens when you tap them, to checking if the data behind them is real."

- **Intermediate**: "UI Path Radar systematically audits all UI entry points (sheets, navigation links, toolbar buttons, deep links, notifications) across your SwiftUI app. It traces user flows end-to-end, flags dead ends, promise-scope mismatches, platform gaps, and orphaned state. Five layers: discovery → flow tracing → issue detection → UX evaluation → data wiring verification."

- **Experienced**: "5-layer UI path audit: entry point discovery, flow tracing, issue detection (dead ends, promise mismatches, orphaned state, platform gaps), semantic UX evaluation, and data wiring verification. Outputs issue rating tables with fix plans."

- **Senior/Expert**: "Entry point → flow trace → issue scan → UX eval → data wiring. Rating tables + fix plans."

Store the experience level as `USER_EXPERIENCE` and apply to ALL output for the session (see Experience-Level Adaptation section).

---

### Terminal Width Check (MANDATORY — run first)

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

Store the result as `TERMINAL_WIDE` (true/false) and apply to ALL tables in the session — discovery tables, issue tables, and summaries. If the user later says "show full table", "wide table", or "full ratings", re-render the most recent findings table in full 8-column format regardless of terminal width.

---

## Plain Language Communication (MANDATORY)

All user-facing prompts must be understandable by someone who has never used this skill before. Apply these rules to every `AskUserQuestion`, progress banner, and completion message:

1. **Describe what was found** in plain terms ("3 dead-end screens, 2 navigation bugs") — not internal categories ("3 Layer 3 findings")
2. **Describe next steps by what they DO**, not by skill name ("check your data models for backup gaps" not "proceed to data-model-radar")
3. **Describe options by outcome and time cost** ("Fix navigation dead ends now (~10 min)" not "Wave 1: Safe fixes")
4. **Add an "Explain more" option** to every transition `AskUserQuestion` so users can get context without slowing down experienced users
5. **Define jargon on first use:**
   - "Layer" → "step" or "analysis phase" (a stage in the audit process)
   - "Wave" → "fix batch" (a group of related fixes applied together)
   - "Handoff" → a file this skill writes so other audit skills can pick up where it left off
   - "Dead end" → a screen the user can reach but can't navigate away from
   - "Broken promise" → a button or link that appears but doesn't work or leads nowhere
   - "Entry point" → a way to reach a feature (tab, button, deep link, etc.)
6. **Exception:** If user selected Senior/Expert experience level, terse references are acceptable

### Completion Prompt Template

When the audit is complete, use this pattern:

```
I found [X] issues in your app's navigation and user flows:
- [N] dead ends (screens users can't leave)
- [N] broken paths (buttons/links that don't work)
- [N] missing features (advertised but not reachable)

You can:
1. **Fix the critical issues now** (~[time]) — [one-line description]
2. **Fix just the quick wins** (~[time]) — [one-line description]
3. **Keep auditing other areas first** — I'll check [plain description of next analysis] next
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

---

When invoked, perform the audit:

### If no arguments or "full":

**Before starting, print:**
```
⏱ Full Audit: 5 steps — estimated total: ~10-30 min depending on codebase size
  Step 1: Find all entry points → Step 2: Trace how users navigate → Step 3: Detect issues → Step 4: Evaluate user impact → Step 5: Verify data wiring
```

Run all 5 layers sequentially, outputting findings to `.ui-path-radar/` in the project root.
**Between layers, print:** `⏱ ✓ Step [N] of 5 complete: [plain description of what was done] — starting Step [N+1]: [plain description of what's next]`

### If "layer1" or "discovery":

**Before starting**, count Swift files and print an estimate:
```
⏱ Layer 1: Discovery — scanning [N] Swift files
  Estimated time: ~[1-2 min for <200 files / 3-5 min for 500+ files]
  Progress will be shown after each tier completes.
```

**Scan in 3 tiers, from top-level down. After completing each tier, print a progress line:**

#### Tier 1: Top-Level Structure
1. Find the app's navigation skeleton: `TabView`, `NavigationSplitView`, sidebar sections
2. For each top-level destination, identify the view file
3. Scan for sheet routing enums: `grep -r "enum.*Sheet\|enum.*SheetType" Sources/`
4. Scan for navigation state: `grep -r "selectedSection\|selectedTab\|activeSheet" Sources/`

**After Tier 1, print:** `⏱ Layer 1: ✓ Tier 1 Structure (1/3) — found [N] tabs, [N] sidebar items, [N] sheet enums`

#### Tier 2: Entry Point Patterns
Scan for these patterns across ALL source files:

| Pattern | Search | Priority |
|---------|--------|----------|
| Sheets | `.sheet(`, `.fullScreenCover(` | HIGH — primary feature access |
| Navigation | `NavigationLink(`, `.navigationDestination(` | HIGH — screen transitions |
| Tab views | `TabView`, `.tabItem(` | HIGH — top-level entry points |
| Buttons with state | `Button(.*{` near `showing` or `activeSheet` or `selected` | HIGH — action triggers |
| Deep links | `onOpenURL`, `DeepLinkRouter`, URL scheme handlers | HIGH — external entry points |
| Notification nav | `.onReceive(NotificationCenter`, `NotificationCenter.default` near navigation/sheet state | HIGH — invisible triggers |
| Spotlight/Handoff | `onContinueUserActivity`, `CSSearchableItemActionType` | HIGH — system search entry |
| File operations | `.fileImporter`, `.fileExporter`, `PhotosPicker` | MEDIUM — data entry paths |
| Context menus | `.contextMenu {` | MEDIUM — long-press actions |
| Swipe actions | `.swipeActions` | MEDIUM — list row shortcuts |
| Toolbars | `.toolbar {` with `Button` | MEDIUM — persistent actions |
| Keyboard shortcuts | `.keyboardShortcut` | MEDIUM — power user entry |
| Promotion cards | `PromotionCard`, `CompactPromotionCard`, dismissable feature cards | MEDIUM — conditional entry |
| Confirmation dialogs | `.confirmationDialog(`, `.alert(` | LOW — exit gates, not entry points |

**After Tier 2, print:** `⏱ Layer 1: ✓ Tier 2 Patterns (2/3) — found [N] entry points across [N] patterns`

#### Tier 3: Container View Enumeration
For views that are **feature hubs** (tools, settings, reports, dashboards), don't just log the hub as one entry point — enumerate each actionable card/row inside it as a sub-entry-point. These hubs often contain 10-20+ features that the Tier 2 scan misses because they're wired through enum-based routing, not direct `.sheet()` modifiers.

Also identify the **primary detail view** (the view users spend the most time in) and audit its sheet/action surface separately — it often has the largest entry point count.

**After Tier 3, print:** `⏱ Layer 1: ✓ Tier 3 Containers (3/3) — enumerated [N] hub views, [N] sub-entry-points added`

#### Catalog Rules

**For each entry point found:**

| Field | Description |
|-------|-------------|
| Label | What the user sees (button text, card title, menu item) |
| Location | File and line where the trigger lives |
| Action type | Sheet, navigation, state change, deep link, notification, keyboard shortcut |
| Destination | What view/screen opens |
| Depth | Hierarchy level: L0 (tab/sidebar) → L1 (section view) → L2 (detail/sheet) → L3 (sub-sheet) |
| Condition | When is this entry point visible? (e.g., "only if items exist", "after dismissal: never") |
| Flags | Suspicious patterns (see below) |

**Flags to apply during discovery:**

| Flag | Description |
|------|-------------|
| `dead_end` | Trigger exists but destination is missing or broken |
| `promise_mismatch` | Specific label opens generic/broad destination |
| `incomplete_nav` | Lands on section top, not the specific feature |
| `missing_state` | Navigation without setting up expected mode/state |
| `two_step` | Requires intermediate picker before reaching feature |
| `no_feedback` | Action completes without confirmation |
| `orphaned` | View exists but has no entry point |
| `platform_gap` | Works on one platform, broken on another |
| `alias` | Entry point mirrors another entry point's destination (e.g., QuickFind item that opens the same sheet as a toolbar button). Group aliases separately — they confirm redundancy, not new paths |
| `conditional` | Entry point disappears after user action. **Scan for:** `@AppStorage` keys containing `hasDismissed`, `hasUsed`, `hasScanned`, `hasSeen`; `if !settings.someFlag` guards around UI elements; `.onboardingComplete` checks. These are features visible only to new users or until a milestone is reached — they affect first-session discoverability. |
| `invisible` | Entry point triggered by notification, deep link, or Spotlight — not visible in the UI hierarchy |

#### De-duplication Rules

- **Context menus repeated on identical UI elements** (e.g., same menu on product/receipt/nameplate photos): catalog once, note multiplier (e.g., "×3 photo types")
- **QuickFind / Spotlight / Siri Shortcuts** that mirror other entry points: tag as `alias`, group in a separate "Meta-Entry-Points" section at the end
- **Confirmation dialogs**: list separately as "Exit Gates" — they guard destructive actions, not open features

#### Discovery Output

Group the table by hierarchy level, not flat:

```
## L0: Top-Level Navigation (tabs, sidebar)
| # | Label | Location | Action | Destination | Flags |

## L1: Section Views (dashboard, tools, settings, detail)
| # | Label | Location | Action | Destination | Flags |

## L2: Feature Sheets & Sub-Navigation
| # | Label | Location | Action | Destination | Flags |

## Meta-Entry-Points (QuickFind, Spotlight, Deep Links, Keyboard Shortcuts)
| # | Label | Location | Action | Mirrors # | Flags |

## Exit Gates (Confirmation Dialogs)
| # | Label | Location | Guards |
```

After the tables, list:
- Total entry points found (primary + aliases)
- Count by flag type
- Count by depth level
- Recommended flows to audit in Layer 2 (flagged entries first, deepest paths second)

### If "layer2" or "trace" (no path argument):

**Before starting, print:**
```
⏱ Layer 2: Flow Tracing — [N] flagged entry points to trace
  Estimated time: ~[2-3 min for <5 flows / 5-8 min for 10+ flows]
```

1. Read flagged entry points from Layer 1
2. For each flagged entry point, trace the complete user journey. **After each flow, print:** `⏱ Layer 2: ✓ Flow [N]/[total] — "[flow name]"`
3. Document in `layer2-traces/flow-XXX.yaml`
4. Identify gaps between expected and actual journeys

### If "trace" with path argument (e.g., `trace "Dashboard → Add Item → Photo → Save"`):
Targeted flow trace — trace a specific user journey described in natural language:
1. Parse the path description into discrete steps (split on `→`, `->`, or `,`)
2. For each step, identify the SwiftUI view, button, or action that triggers it:
   - Search for view names, sheet triggers, navigation actions matching each step
   - Use `grep -r` for button labels, sheet cases, navigation destinations
3. Trace the complete code path step by step:
   - File and line number for each transition
   - State changes (sheet presentations, navigation, @State mutations)
   - View transitions (what view appears at each step)
4. At each step, check for issues:
   - Is the expected next action visible without scrolling? (Buried Primary Action)
   - Does the user have a forward path? (Dismiss Trap)
   - Does the CTA match the destination scope? (Promise-Scope Mismatch)
   - Is feedback shown on completion? (Missing Feedback)
5. Document the trace and any issues found
6. Output: Issue Rating Table for any findings, plus the step-by-step trace

### If "layer3" or "issues":

**Before starting, print:**
```
⏱ Layer 3: Issue Detection — scanning [N] entry points for issues
  Estimated time: ~[2-4 min for <100 entries / 5-10 min for 200+]
```

**Step 0 — Cross-layer verification (MANDATORY):**
Before scanning for new issues, re-verify ALL flagged findings from Layer 1 and Layer 2. For each:
- Check whether the flag still holds when you look at extension files (`+Sections.swift`, `+Actions.swift`, etc.) and ViewModel bindings (`@Bindable`, `Binding<Bool>` parameters)
- If a finding was based on "this @State var is never set to true" — also check if it's passed as a `$binding` to a ViewModel method or child view that sets `.wrappedValue = true`
- **Retract** false positives explicitly: `~~#N — [original finding]~~ RETRACTED: [reason]`
- Print: `⏱ Layer 3: ✓ Cross-layer verification — [N] confirmed, [N] retracted`

**Then proceed with new checks:**

1. Scan ALL entry points for common issues. **After each check, print:** `⏱ Layer 3: ✓ [check name] ([N]/[total]) — [N] findings so far`
2. Check for orphaned sheet cases (enum vs handler mismatch)
3. Check for orphaned views (defined but never instantiated)
4. Check for orphaned @State vars — but verify against extension files AND ViewModel bindings before flagging (see Step 0 methodology)
5. Categorize by severity
6. Output to `layer3-results.yaml`

### Verification Template (MANDATORY for Layer 3)

Before grading issues, produce this table for each flagged entry point from Layer 1:

```
| # | Entry Point | Flag | Verified? | Receipt | Status |
|---|-------------|------|-----------|---------|--------|
| 1 | [label] | [flag] | ? | (file:line checked) | confirmed / retracted / needs-runtime |
```

Rules:
- Every flagged entry point from Layer 1 must appear in this table
- `?` in the Verified column means the finding hasn't been checked in Layer 3 yet
- Layer 3 cannot produce a grade while any flagged entry has `?` in Verified
- Retracted findings stay in the table with strikethrough — they prove you checked, not just confirmed

### If "layer4" or "evaluate":

**Before starting, print:**
```
⏱ Layer 4: Semantic Evaluation — [N] issues to evaluate
  Estimated time: ~[1-2 min for <10 issues / 3-5 min for 20+]
```

1. For each issue, assess user impact using these **4 criteria** (score each 1-5):

| Criterion | 1 (no impact) | 3 (moderate) | 5 (severe) |
|-----------|--------------|--------------|------------|
| **Discoverability** | Feature is obvious, multiple entry points | Requires learning but findable | Hidden, gesture-only, or buried 4+ taps deep |
| **Efficiency** | One tap from context | 2-3 taps, minor detour | 4+ taps, navigation required, context lost |
| **Feedback** | Clear confirmation + undo | Confirmation but no undo | No feedback, user unsure if action completed |
| **Recovery** | Easy undo, no data loss | Partial undo, minor data loss possible | No undo, data loss, or must recreate from scratch |

2. For each finding, assign a **confidence level**:
   - `verified` — confirmed by grep, file read, or code trace. The issue definitely exists.
   - `probable` — code suggests the issue but not fully traced through all code paths.
   - `needs-runtime` — static analysis can't determine; requires running the app to confirm (e.g., animation timing, race conditions).

3. Map violations to design principles (#1-#8)
4. **After each evaluation, print:** `⏱ Layer 4: ✓ Issue [N]/[total] — [confidence] — [D/E/F/R scores]`
5. Output to `layer4-semantic-evaluation.md`

### If "layer5" or "data-wiring" or "wiring":

**Before starting, print:**
```
⏱ Layer 5: Data Wiring — inventorying models and cross-referencing features
  Estimated time: ~[2-4 min for <20 features / 5-10 min for 40+]
```

1. Inventory model properties and relationships (what data the app tracks). **Print:** `⏱ Layer 5: ✓ Model inventory (1/4) — [N] models, [N] properties`
2. **Select features to cross-reference.** Don't try to check every feature — select the **top 5-8** using these criteria (in priority order):
   - Features that **make decisions** based on model data (advisors, calculators, suggestion engines) — these are most likely to have unwired data
   - Features with the **most model properties available** but unclear how many they actually use
   - Features flagged in earlier layers (Layer 3 orphans, Layer 2 traced flows)
   - The **primary detail view** (it reads the most model data)

   For each selected feature, check what model data it actually reads vs what's available. **Print:** `⏱ Layer 5: ✓ Feature scan (2/4) — [N] features checked`
3. Detect mock/hardcoded data patterns (asyncAfter delays, static arrays, placeholder strings). **Print:** `⏱ Layer 5: ✓ Mock data scan (3/4)`
4. Cross-reference: model capabilities vs feature consumption
5. Flag unwired integrations (e.g., data exists but decision engine ignores it)
6. Check platform parity (extension files, #if os() blocks, dismiss buttons). **Print:** `⏱ Layer 5: ✓ Platform parity (4/4)`
7. Output to `layer5-data-wiring.yaml`

**Data wiring detection patterns:**
```
# Fake fetch pattern — asyncAfter with hardcoded data
asyncAfter(deadline:) { self.data = HardcodedResult(...) }

# Static arrays pretending to be computed results
let alternatives = [Alternative(name: "Product X", price: "$299")]

# Decision logic ignoring available model data
func computeDecision() {
    // Uses 2 of 10+ available properties
    if item.age > lifespan { return .replace }
    return .keep
}

# Manager/service exists but feature doesn't reference it
// SomeManager exists — does the feature use it?
```

**Cross-reference matrix:**

| Feature | Data Available | Data Used | Data Ignored |
|---------|---------------|-----------|--------------|
| [name] | [model properties] | [what it reads] | [gap] |

### If "diff":
Compare current codebase against the previous audit to show what changed:
1. Read existing `.ui-path-radar/layer3-results.yaml` and `.ui-path-radar/handoff.yaml`
2. For each previously-reported issue, check if the referenced file + line still has the problem:
   - Read the file at the reported line number
   - Check if the problematic pattern still exists
   - If fixed, mark as "RESOLVED"
   - If file was modified but pattern persists, mark as "STILL OPEN"
   - If file was deleted or moved, mark as "FILE CHANGED — verify manually"
3. Run a quick scan for NEW issues not in the previous report (new files, new ScrollView+button combos, new sheets without handlers)
4. Output a diff summary:
   ```
   Audit Diff: <previous date> → <current date>
   ✅ Resolved: <count> issues fixed since last audit
   🔴 Still Open: <count> issues remain
   🆕 New: <count> new issues detected
   📁 Changed: <count> files modified since audit (may need re-verification)
   ```
5. Show the full Issue Rating Table with a Status column prepended (✅/🔴/🆕)

### If "fix" or "fixes":
1. Read `layer3-results.yaml` and `layer5-data-wiring.yaml` for unfixed issues
2. Generate specific code fixes
3. Prioritize by severity (critical first)
4. Group into:
   - **Safe fixes** — isolated, low blast radius
   - **Cross-cutting fixes** — touch shared code
   - **Requires design decision** — multiple valid approaches
   - **Deferred** — no action needed now
   - **Out of scope** — belongs to a different audit type

### If "status":
1. Read existing audit files
2. Report: issues found, fixed, remaining
3. Show priority queue for unfixed issues

---

## Output Format

> **CRITICAL FORMATTING RULE:** The Issue Rating Table below IS the output. Do NOT create separate sections for "Critical Issues", "Data Wiring Issues", "Recommendations", or any other vertical breakdown of findings. Every finding — navigation issues, data wiring issues, orphaned code, missing feedback, design violations — goes into ONE table as ONE row. Context goes in the Finding column. No exceptions.

### Layer Transition Summary (between each layer)

When completing a layer and moving to the next, print:
```
⏱ ✓ Step [N] of 5 complete: [plain description] — [M] findings ([X] verified, [Y] probable, [Z] needs-runtime)
  Retracted from prior steps: [count or "none"]
  Cumulative: [total] findings ([C] critical, [H] high, [M] medium, [L] low)
  Next: Step [N+1] — [plain description of what it does and why it matters given current findings].
  → "proceed" | "explain #[N]" | "stop here"
```

This gives the user a checkpoint to explore risky findings, ask questions, or stop the audit before investing more time.

### Final Output (after all layers or after a single layer run)

After completing the audit, provide these **6 items in order**:

1. **One-line summary** — entry point count, issue count by severity (one sentence, not a section)
2. **Issue Rating Table** — every finding in a single table (see below). Each finding MUST include a confidence tag (`verified` / `probable` / `needs-runtime`) in the Finding column.
3. **Proactive risk callout** — Auto-identify the top 3 riskiest findings by scanning Risk:Fix, Risk:No Fix, and Blast Radius columns. Print:
```
⚠ Before proceeding, these findings have elevated risk profiles:
  #[N] — [short description] (Risk:Fix [indicator], Blast [count] files)
  #[N] — [short description] (Risk:No Fix [indicator], [consequence])
  → Say "explain #[N]" for a detailed risk breakdown before deciding.
```
4. **Cross-skill handoff notes** (if applicable) — If any findings fall into another skill's domain, note them:
```
🔗 Related areas to check next:
  #[N] → Check whether saved data survives editing round-trips (data safety audit)
  #[N] → Check visual layout and spacing for this screen (visual quality audit)
```
5. **Limitations disclaimer** — What this audit can't see:
```
📋 Limitations: Static analysis only. Not checked: animation smoothness,
   real-device timing, race conditions under memory pressure, subjective
   UX feel, accessibility with VoiceOver. Consider runtime testing for
   findings marked "needs-runtime."
```
6. **One-line next step** — suggest next action ("proceed to fixes", "check data safety for affected workflows", etc.)

No other sections. Items 3-5 may be omitted if not applicable (no risky findings, no handoffs, experienced/senior user who doesn't need the disclaimer).

### Issue Rating Table

**Hard formatting rule — Table, not list:** ALL findings MUST be in a single markdown table. Each finding is ONE ROW. Ratings are COLUMNS read left-to-right. Never expand findings into individual sections, vertical blocks, or bullet-pointed ratings. Do NOT create separate headed sections for categories of findings. ALL categories go in the same table. The Finding column carries the context.

All findings MUST be presented in this format, sorted by Urgency then ROI:

**Full table (160+ cols):**
```markdown
| # | Finding | Confidence | Urgency | Risk: Fix | Risk: No Fix | ROI | Blast Radius | Fix Effort |
|---|---------|------------|---------|-----------|-------------|-----|-------------|------------|
| 1 | Dead end: ".warranty" unhandled | verified | 🔴 Critical | ⚪ Low | 🔴 Critical | 🟠 Excellent | 🟢 2 files | Trivial |
| 2 | AI dismiss→sleep(0.3)→present | probable | 🟢 Medium | 🟢 Medium | 🟢 Medium | 🟢 Good | 🟢 2 files | Small |
```

**Compact table (under 160 cols):**
```markdown
| # | Finding | Conf. | Urgency | Fix Effort |
|---|---------|-------|---------|------------|
| 1 | Dead end: ".warranty" unhandled | verified | 🔴 Critical | Trivial |
| 2 | AI dismiss→sleep→present fragile | probable | 🟢 Medium | Small |
```

### Indicator Scale

| Indicator | General meaning | ROI meaning |
|-----------|----------------|-------------|
| 🔴 | Critical / high concern | Poor return — reconsider |
| 🟡 | High / notable | Marginal return |
| 🟢 | Medium / moderate | Good return |
| ⚪ | Low / negligible | — |
| 🟠 | Pass / positive | Excellent return |

- **Urgency:** 🔴 CRITICAL (dead end, wrong destination, mock data) · 🟡 HIGH (broken promise, missing activation, unwired data) · 🟢 MEDIUM (two-step flow, missing feedback) · ⚪ LOW (inconsistency, orphaned code)
- **Risk: Fix:** Risk of the fix introducing regressions
- **Risk: No Fix:** User-facing consequence of leaving the issue
- **ROI:** 🟠 Excellent · 🟢 Good · 🟡 Marginal · 🔴 Poor
- **Blast Radius:** Number of files the fix touches (e.g., `🟢 3 files`, `⚪ 1 file`). Do not use `<br>` tags. Count by grepping for callers/references before rating.
- **Fix Effort:** Trivial / Small / Medium / Large

---

## Fix Application Workflow

After presenting findings, apply fixes in **waves**. After each wave (including commits), **always** print the progress banner and auto-prompt for the next wave. Never leave the user with a blank prompt.

### Waves

| Wave | Section | Est. Time | Description |
|------|---------|-----------|-------------|
| 1 | Safe fixes + tests | ~10-15 min | Isolated, low blast radius. Auto-apply. Write tests for each fix. |
| 2 | Cross-cutting fixes + tests | ~15-25 min | Touch shared code. Present for review first. Write tests. |
| 3 | Design decisions | ~5-15 min | Multiple options. Requires user input per item. |
| 4 | Build + Test + Commit | ~5 min | Build both platforms, run tests, stage, commit. |

**Every fix must have a test.** Do not move to the next wave until tests for the current wave's fixes are written and compiling. The test verifies the fix works; without it, the fix is unverified code.

Skip empty waves.

### Progress Banner (MANDATORY after every wave)

**CRITICAL — BLOCKING requirement.** After EVERY wave and EVERY commit, your NEXT output MUST be the progress banner followed by the next-wave `AskUserQuestion`. Do not output anything else first. Do not wait for user input. Do not leave a blank prompt.

After completing each wave, **always** print:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Wave [N] of [total] complete: [wave name]
   [X] findings fixed, [Y] remaining, [Z] deferred

⏱  Next: Wave [N+1] — [wave name] (~[time estimate])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then immediately ask: "Ready for Wave [N+1]?" with options:
- **Proceed (Recommended)** — Start the next wave
- **Commit first** — Commit current changes before continuing
- **Stop here** — End for now, resume later

---

## Handoff Brief Generation

After completing all layers (full audit) or `fix` mode, generate `.ui-path-radar/handoff.yaml` for consumption by planning skills.

### When to Generate

- After a full 5-layer audit completes
- After `fix` mode completes (refreshes the brief with current state)
- NOT after individual layer runs (layer1, layer2, etc.)

### Format

```yaml
# Handoff Brief — generated by ui-path-radar
# Consumed by planning skills

project: <project name from directory>
audit_date: <ISO 8601 date>
source_files_scanned: <count>

summary:
  total_issues: <count>
  critical: <count>
  high: <count>
  medium: <count>
  low: <count>

file_timestamps:
  <file path>: "<ISO 8601 mod date>"
  # one entry per unique file referenced in issues[]

issues:
  - id: <sequential number>
    finding: "<description>"
    category: <dead_end|wrong_destination|mock_data|incomplete_navigation|missing_activation|unwired_data|platform_gap|promise_scope_mismatch|buried_primary_action|dismiss_trap|two_step_flow|missing_feedback|gesture_only_action|loading_state_trap|context_dropping|notification_nav_fragility|sheet_presentation_asymmetry|stale_navigation_context|inconsistent_pattern|orphaned_code>
    urgency: <critical|high|medium|low>
    risk_fix: <critical|high|medium|low>
    risk_no_fix: <critical|high|medium|low>
    roi: <excellent|good|marginal|poor>
    blast_radius: "<description, e.g. '1 file' or '4 files'>"
    fix_effort: <trivial|small|medium|large>
    files:
      - <file path>
    suggested_fix: "<what to do, not how>"
    group_hint: "<optional grouping suggestion, e.g. 'missing_confirmations'>"
```

### File Timestamps

For each unique file path referenced across all issues, record its modification date at audit time. This enables planning skills to detect staleness — if a file changed after the audit, affected issues may need re-verification.

```bash
# Get file mod date (macOS)
stat -f "%Sm" -t "%Y-%m-%dT%H:%M:%SZ" "<file path>"
```

### Group Hints

Optional field suggesting how planning skills might batch issues:
- Issues with the same `group_hint` are candidates for a single task
- The planning skill is free to ignore hints and group differently
- Common hints: `missing_confirmations`, `missing_feedback`, `orphaned_features`, `dead_code`, `platform_parity`

---

## Cross-Skill Handoff

UI Path Radar complements **data-model-radar** (model layer), **roundtrip-radar** (data safety), **ui-enhancer-radar** (visual quality), and **capstone-radar** (ship readiness). Findings from one skill inform the others.

### On Completion — Write Handoff

After completing an audit, write `.agents/ui-audit/ui-path-radar-handoff.yaml`:

```yaml
source: ui-path-radar
date: <ISO 8601>
project: <project name>

for_roundtrip_radar:
  # Dead ends and broken promises suggest data flow issues
  suspects:
    - workflow: "<affected workflow>"
      finding: "<what was found>"
      file: "<file:line>"
      question: "<specific question for roundtrip-radar to verify>"

for_ui_enhancer_radar:
  # Dead buttons and orphaned views should be removed or fixed before visual audit
  suspects:
    - view: "<view file>"
      finding: "<what was found>"
      action: "remove or wire up before visual audit"

for_capstone_radar:
  # Critical/high findings that affect ship readiness
  blockers:
    - finding: "<description>"
      urgency: "<CRITICAL|HIGH>"
```

**Automatic:** This file is always written so other audit skills can pick up where this one left off. No user action needed.

### On Startup — Read Handoffs

Before starting the audit, check for handoff files from other skills:
- `.agents/ui-audit/roundtrip-radar-handoff.yaml` — data safety issues that may have UI implications
- `.agents/ui-audit/ui-enhancer-radar-handoff.yaml` — visual issues that may indicate structural problems

If found, incorporate relevant items as **suspects** in the appropriate layer. If not found, proceed normally — the other skills may not be installed or haven't been run yet.

---

## REMINDER (End-of-File — Survives Context Compaction)

**CRITICAL:** After EVERY wave, EVERY commit, and EVERY layer transition:
1. Print the progress banner (wave-level or layer-level)
2. Immediately `AskUserQuestion` for the next step
3. NEVER leave a blank prompt

This reminder is placed at the end of the file because context compaction tends to preserve the beginning and end. If you are unsure whether to print the banner, **print it**.
