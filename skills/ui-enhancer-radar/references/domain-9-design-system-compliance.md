# Domain 9: Design System Compliance

> Loaded by SKILL.md for full audit or single-domain command: design-system.
> Externalized from SKILL.md in ui-enhancer-radar 3.6.0 as the proof-of-pattern for migrating the inline domains (1–11) to the per-file structure already used by domains 12–14.

## Why this domain exists

A view can be flawless in isolation — correct colors, valid layout, no crashes — and still be *wrong for this project* because it ignores the design system the rest of the app follows. Custom card chrome where `.stuffolioCard()` exists, a hand-rolled header where `SheetHeader` exists, a hardcoded `.frame(width: 24, height: 24)` icon where the project uses `@ScaledMetric`. None of these are bugs; all of them are drift. Drift compounds: every off-pattern view makes the next author less sure what the pattern *is*.

Domain 9 is **project-specific by definition** — it has nothing to check until it has read the project's design-system source of truth (`CLAUDE.md`, `DESIGN_SYSTEM.md`, `StuffolioStyleGuide.swift`, or equivalents). With no design-system docs, it does not invent rules; it skips and recommends establishing a system.

Unlike domains 12–14 (single render-time interaction bugs), Domain 9 is a **conformance sweep**: a set of independent checks (9a–9e) plus a cross-view consistency pass that asks not just "what's off-pattern here?" but "what do sibling views include that this one is missing?"

## Goal

Compare the view under audit against the project's documented design system and flag, per check:

| Check | What to look for | Common fix |
|-------|-----------------|------------|
| Color palette | Colors outside the approved palette | Replace with design-system colors |
| Spacing values | Non-standard spacing/padding | Use `Spacing.*` constants |
| Component usage | Custom UI where a standard component exists | Replace with `SheetHeader`, `SemanticIconCircle`, etc. |
| Card styles | Cards not using `.stuffolioCard()` / `.actionCard()` | Apply standard modifiers |
| Icon style | Inconsistent icon rendering or sizing | Use `@ScaledMetric` + standard patterns |
| Section structure | Sections not using `CollapsibleSection` | Adopt the standard section component |
| Sheet pattern | Sheets not using `SheetContainer` + `SheetHeader` | Apply the standard sheet pattern |
| **Unused component capabilities** | Custom UI duplicating a feature a shared component already offers via a parameter | Enable the existing parameter; delete the custom UI |

## How it works

1. Read `CLAUDE.md` for project-level design rules.
2. Read any design-system files (`DESIGN_SYSTEM.md`, `StuffolioStyleGuide.swift`, `FormStyles.swift`, etc.).
3. Compare the view against the documented patterns via checks 9a–9e below.
4. Run the cross-view consistency pass (what's *missing* vs. sibling views) using the Adaptive View Profile.

> **CRITICAL: Do NOT delegate Domain 9 checks to Explore subagents.** Run each check directly with Grep/Read. The conformance comparison needs the project docs and the view file held together; a subagent that reads only the view loses the baseline and produces false positives.

## Unused-capability check (run for every view)

When the view uses a shared component (`ContentIllustratedHeader`, `SheetHeader`, `CompactSheetHeader`, `SheetContainer`), read that component's `init` parameters. If the component supports a feature via a parameter the view isn't using — but the view builds *separate custom UI* for that same feature — flag it:

> "[ComponentName] already supports [feature] via `parameterName: true`, but this view builds a separate [custom element] instead. Enable the parameter and remove the custom UI."

How to check:

1. Identify shared components used in the view (headers, containers, cards).
2. Read each component's `init` signature — look for `Bool` parameters defaulting to `false`, optional closures defaulting to `nil`.
3. Compare unused parameters against custom UI in the view that serves the same purpose.
4. On a match, recommend enabling the parameter over keeping the custom UI.

## Automated detection

**Check 9a: Color palette violations**
```bash
# Step 1: Read the project's approved palette from CLAUDE.md or DESIGN_SYSTEM.md
# Step 2: Find all color references in the view
grep -n "\.foregroundStyle(\.\|\.foregroundColor(\.\|\.background(\.\|\.tint(\.\|Color\." <view_file>.swift
# Step 3: Flag any color not in the approved list
# Common violations: .green (if forbidden), .yellow (if sf3aYellow required), custom hex colors
```

**Check 9b: Component usage — custom UI duplicating shared components**
```bash
grep -rn "struct.*: View" Sources/Views/Components/ --include="*.swift" | head -20
grep -n "SheetContainer\|SheetHeader\|ContentIllustratedHeader\|SemanticIconCircle\|CollapsibleSection" <view_file>.swift
# Custom header/container code that doesn't use the shared component → flag
grep -n "VStack.*{" <view_file>.swift | head -5
```

**Check 9c: Modifier usage — missing standard modifiers**
```bash
grep -n "stuffolioCard\|stuffolioSection\|actionCard" <view_file>.swift
# Card-like UI without standard modifiers → flag
grep -n "\.background.*RoundedRectangle\|\.clipShape.*RoundedRectangle\|cornerRadius" <view_file>.swift
```

**Check 9d: Sheet pattern compliance**
```bash
grep -n "SheetContainer\|SheetHeader\|CompactSheetHeader" <view_file>.swift
# If none and it's a sheet (toolbar cancellationAction or NavigationStack) → flag
grep -n "cancellationAction\|NavigationStack" <view_file>.swift
```

**Check 9e: Icon sizing — @ScaledMetric**
```bash
grep -n "\.frame(width:.*height:" <view_file>.swift | grep -i "image\|icon\|symbol"
grep -n "@ScaledMetric" <view_file>.swift
# Icon frames without @ScaledMetric (won't scale with Dynamic Type) → flag
```

## Cross-view consistency additions (what's missing?)

**Goal:** detect features/controls that *should* be present based on what sibling views include. Domain 9 checks not only what to remove or change, but what to *add* for consistency.

How it works:

1. Identify shared components used in the current view (`ContentIllustratedHeader`, `SheetContainer`, …).
2. Grep the codebase for all other callers of the same component.
3. Compare which optional parameters/features each caller enables.
4. If a majority of sibling views enable a feature this view doesn't, flag it as a potential addition.

| Pattern | How to detect | Recommendation format |
|---|---|---|
| Missing header controls | Component used with `showThemeToggle: true` in 6/8 views but not here | "[N] of [total] views with [Component] enable [parameter]. Add it for consistency?" |
| Missing keyboard toolbar | iOS input view without `ToolbarItemGroup(placement: .keyboard)` | "This view has text inputs but no keyboard Done button" |
| Missing dismiss button | Sheet without close/done on macOS | "macOS sheets need an explicit dismiss button" |
| Missing empty state | List/collection with no `if items.isEmpty` handler | "This view shows a list but has no empty state" |
| Missing pull-to-refresh | Scrollable data view without `.refreshable` | "Data views should support pull-to-refresh on iOS" |
| Missing loading state | Async fetch with no loading indicator | "Data loads asynchronously but no ProgressView shown" |
| Missing error state | Async operation with no error UI | "Network/data operations have no error feedback" |

How to present (always frame as a recommendation with design-intent acknowledgment):

```
"[N] of [total] views with [ComponentName] enable [feature]. This view doesn't.
 - Add [feature] (Recommended) — matches [N/total] sibling views for consistency
 - Skip — intentionally omitted for this view (e.g., [possible reason])"
```

Possible reasons to skip (offer the relevant one):
- Settings views may omit theme toggle because theme *is* a setting on that page.
- Modal sheets may omit help because the parent already provides context.
- Simple utility views may not need pull-to-refresh if data is local-only.
- Single-purpose sheets may not need customization controls.

**Detection requires the Adaptive View Profile** (see SKILL.md § Detected Patterns / Adaptive View Profile). On first audit there's no baseline — record what this view uses. Subsequent audits provide the sibling-comparison data.

## Project-convention awareness

Domain 9's entire ruleset comes from the project, not from Apple APIs. Source the rules in this order:

1. **Explicit config:** `.radar-suite/conventions.yaml` keys, if present — `approved_palette`, `spacing_namespace` (e.g. `Spacing`), `card_modifiers` (e.g. `stuffolioCard`, `actionCard`), `sheet_container` (e.g. `SheetContainer`), `shared_components` (e.g. `SheetHeader`, `CollapsibleSection`). (Schema: `reference/conventions-schema.md` once it exists; until then these keys are the contract.)
2. **Doc fallback:** grep `CLAUDE.md` / `DESIGN_SYSTEM.md` / `Sources/Views/Components/` for the palette, spacing constants, and shared-component names.
3. **No config and no docs:** skip the domain (see Exclusions) — do NOT invent a design system.

## Finding format

Each flagged site produces one row:

| Field | Example |
|---|---|
| **File:line** | `Sources/Views/Detail/EnhancedItemDetailView.swift:412` |
| **Check** | 9c — missing standard card modifier |
| **What's off-pattern** | hand-rolled `RoundedRectangle().fill()` card instead of `.stuffolioCard()` |
| **Design-system rule** | `DESIGN_SYSTEM.md` "Stuffolio Card Style (SF4b)" |
| **Fix** | Replace custom background with `.stuffolioCard()` |
| **Blast radius** | 1 view (or N if a shared modifier is the right fix) |

## Severity

**Default:** 🟢 MEDIUM — drift, not breakage; the view works, it's just off-pattern.

**Elevates to 🟡 HIGH when:**
- The violation breaks a load-bearing accessibility rule the design system encodes (e.g. the project's colorblind-safe palette rule — an off-palette `.green`/`.red` co-occurrence, or a non-`@ScaledMetric` icon that defeats Dynamic Type).
- 5+ views share the same off-pattern shape (systemic drift; the fix is likely a shared modifier).
- A "missing state" gap (empty/loading/error) leaves a real user flow with no feedback — that crosses from cosmetic into UX-correctness.

**Never elevates to CRITICAL** on its own — design-system drift is not data loss or a dead control. (A drift that *also* trips another domain — e.g. a custom Picker that's also a Domain 14 Silent Picker — is flagged under that domain at its severity.)

## Exclusions list

Skip (without flagging) when ANY hold:

- **No design-system source exists** (no `conventions.yaml`, no `CLAUDE.md` design rules, no `DESIGN_SYSTEM.md` / style-guide file). Emit one note: "No design system found — establishing one would benefit consistency." Do not invent rules.
- The view is a dev-only harness, `#Preview`, or test fixture.
- The "violation" is an intentional, documented exception (the design system itself names it as allowed — e.g. a sanctioned one-off). Cite the exception and skip.
- A platform-guarded block that's correct for its platform (`#if os(macOS)` AppKit chrome that legitimately differs from the iOS pattern).

## How to present findings

```
## Domain 9: Design System Compliance Findings

Design system: [source — e.g. DESIGN_SYSTEM.md + StuffolioStyleGuide.swift].
Scanned [view]. [M] off-pattern sites, [K] missing-for-consistency suggestions.

| # | File:line | Check | Off-pattern | Fix |
|---|---|---|---|---|
| 1 | EnhancedItemDetailView.swift:412 | 9c | custom card chrome | .stuffolioCard() |
| 2 | EnhancedItemDetailView.swift:88 | consistency | 6/8 sibling sheets enable showHelp | add showHelp or confirm skip |
```

If the design system was not found, the entire output is the single "no design system" note above — nothing else.

## Acceptance criteria (for implementation)

A valid implementation must:

- [ ] Read the project design-system source (config → docs) BEFORE flagging anything
- [ ] Skip the whole domain with a single note when no design-system source exists (never invent rules)
- [ ] Run all of 9a–9e against the view file
- [ ] Run the unused-capability check on every shared component the view uses
- [ ] Run the cross-view consistency pass against the Adaptive View Profile when a baseline exists; record the baseline when none exists
- [ ] Frame every "missing for consistency" item as a recommendation with a skip option and a plausible skip reason
- [ ] Respect `.radar-suite/conventions.yaml` overrides for palette / spacing / card / container / component names
- [ ] Pass the synthetic fixture below
- [ ] Not delegate any check to Explore subagents

### Synthetic fixture (portable acceptance test)

Assume a project whose design system defines: approved card modifier `.appCard()`, spacing namespace `Spacing`, shared header `AppHeader`, and a rule "icons use `@ScaledMetric`." Expected: flag **A**, **B**, **C**; do **not** flag **D**.

```swift
struct FixtureView: View {
    var body: some View {
        VStack(spacing: 11) {                                   // B — off-pattern: magic spacing, not Spacing.*
            // A — off-pattern: hand-rolled card instead of .appCard()
            VStack { Text("Card") }
                .background(RoundedRectangle(cornerRadius: 12).fill(.gray))

            // C — off-pattern: fixed icon frame, no @ScaledMetric
            Image(systemName: "star").frame(width: 24, height: 24)

            // D — compliant: uses the shared header + approved modifier
            AppHeader(title: "OK")
            VStack { Text("Good") }.appCard()
                .padding(Spacing.medium)
        }
    }
}
```

| Site | Verdict | Reason |
|---|---|---|
| A | flag (9c) | custom `RoundedRectangle` card; `.appCard()` exists |
| B | flag (spacing) | literal `11`; project uses `Spacing.*` |
| C | flag (9e) | fixed icon frame, no `@ScaledMetric` |
| D | skip | uses `AppHeader` + `.appCard()` + `Spacing.medium` |

A detector that flags D (false positive) or misses A/B/C (false negatives) fails this fixture. With **no** design-system definition supplied, the correct output for the entire fixture is the "no design system found" note and zero flags.

## The bigger picture

Domains 12–14 detect specific render-time bugs; Domain 9 enforces *project conformance*, which is a fundamentally different shape — it has no fixed ruleset, only the project's. That's why it's the right proof-of-pattern for externalizing the inline domains: it's the largest of 1–11 and it exercises the parts of the template (config-awareness, "skip when no baseline," fixture) that the simpler inline domains (1–8) will reuse with less ceremony. If this externalization reads well, domains 1–8 follow the same skeleton with shorter bodies.

## Origin note

This file was created during a 2026-06-27 radar-suite session as the proof-of-pattern for skill-reviewer finding #1 (ui-enhancer-radar 3.5.0 review): "SKILL.md is a 2,914-line 'index' that holds the spec." Domain 9 was the largest inline domain (~130 lines). Externalizing it cut SKILL.md's always-loaded footprint and established the template for migrating domains 1–8, 10, 11. The inline Domain 9 block in SKILL.md was replaced with a stub pointing here, matching the structure of domains 12–14.
