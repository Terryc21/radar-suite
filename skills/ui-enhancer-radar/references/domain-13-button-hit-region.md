# Domain 13: Button Hit Region — Three-Factor Interaction Bug

> Loaded by SKILL.md for full audit or single-domain command: hit-region.
> Seeded from a Stuffolio session on 2026-04-22 that found Export/Import Backup buttons tappable only on the trailing chevron on iPad. See CHANGELOG entry for ui-enhancer-radar 3.4.0.

## Why this domain exists

On iPad, a `Button` whose label ends with a manually drawn `Image(systemName: "chevron.right")`, styled with `.buttonStyle(.plain)`, and placed inside a `Form` / `List` `Section`, can collapse its hit region to the chevron alone. The body text and icon become visually tappable but functionally dead. The user taps what looks like a button and nothing happens.

iPad users abandon. iPhone users never see the bug because iPhone list rows don't reserve trailing accessory space. No audit, no crash, no warning, no failing test surfaces this. It only shows up when a real finger lands in the middle of the card.

The defect is a **three-factor interaction** that no single-file check can catch:

1. `Button { } label: { ... }` wrapping a custom HStack
2. `.buttonStyle(.plain)` on that Button (or `.borderless` in some cases)
3. The Button lives inside a `Form` or `List` cell AND the label's HStack ends with a trailing decorative `chevron.right` Image

When all three hold, iPadOS treats the button as if it were a disclosure row: the chevron is the accessory, and the rest of the row is non-interactive preview content. On iPhone, this never happens — iPhone rows don't have accessory semantics.

## Goal

Flag every `Button` in the codebase where:

1. The label contains a manually drawn `Image(systemName: "chevron.right")` (or `chevron.forward`)
2. The Button has `.buttonStyle(.plain)` or `.buttonStyle(.borderless)` applied
3. The Button is rendered inside a `Form` section, `List` section, or a cell-like container (`.listRowBackground`, `.listRowInsets`, or any view modifier suggesting list-cell semantics)
4. The label lacks `.contentShape(Rectangle())` or equivalent hit-region expansion

Recommend one of two fixes:

- **Fix A (preferred per HIG):** remove the decorative chevron. `.actionCard()` / colored row backgrounds already read as tappable. HIG says don't draw chevrons on Buttons; that's what NavigationLink renders automatically.
- **Fix B:** keep the chevron, add `.contentShape(Rectangle())` on the label's outer container.

## Scope

**In scope:**
- Any `Button { } label: { ... }` call site in `Sources/`
- `Button("Text", action:)` form — no custom label, so not affected
- `.buttonStyle(.plain)` and `.buttonStyle(.borderless)` variants

**Out of scope:**
- `NavigationLink { } label: { }` — chevrons here are system-rendered, not in scope
- `DisclosureGroup` — chevron is a control, intentional
- Buttons outside Form/List (freestanding cards on scrollable VStacks usually work correctly)
- Buttons with `.buttonStyle(.bordered)`, `.buttonStyle(.borderedProminent)`, or system styles — these don't get the list-cell disclosure treatment

## Why Domain 9's "Sheet pattern" check doesn't catch this

Domain 9 inspects a view's structure for design-system conformance. It would notice "this card lacks `.actionCard()`" but not "this Button inside a Form has a chevron that kills hit region on iPad." The check is about conformance to a component library, not about platform-specific hit-region interactions. Domain 13 is specifically about `Button` + list context + chevron + hit region.

## Detection heuristic

### Step 1: Enumerate candidate Buttons

```bash
# Find every Button with a custom label (the trailing `label:` closure form)
grep -rn --include="*.swift" -B 1 -A 30 "Button {" Sources/ \
  | grep -A 30 "label:"
```

For each hit, capture: file, line of the `Button {`, line of the `label:`, and the full label closure extent (until the matching `}` that closes the outer Button).

### Step 2: Check for manually drawn trailing chevron

Within the label closure text, look for:

```swift
Image(systemName: "chevron.right")
Image(systemName: "chevron.forward")
```

If present, and if it appears after a `Spacer()` or at the last position in an HStack → **chevron trigger matched**.

Ignore chevrons that are:
- Inside a sub-HStack that has its own action (e.g., an overlay button)
- Part of a DisclosureGroup-like custom component (check for `isExpanded:` binding)

### Step 3: Check for `.buttonStyle(.plain)` or `.buttonStyle(.borderless)`

Look at the Button's modifier chain (the lines between the closing `}` of the label and the next unrelated statement):

```swift
.buttonStyle(.plain)
.buttonStyle(.borderless)
.buttonStyle(PlainButtonStyle())
.buttonStyle(BorderlessButtonStyle())
```

If none is present → skip. Default button styles don't have this bug.

### Step 4: Check for Form/List context

This is the harder check. Walk upward from the Button to find whether it's inside a `Form` or `List`. Indicators:

**Structural (walk up the parent chain):**
- The Button is inside a `Section { ... }` that is itself inside a `Form { ... }` or `List { ... }`
- The Button is inside a file whose view body starts with `Form { ... }` or `List { ... }` (even if the Button is several layers deep)

**Modifier indicators on the Button itself or its parent:**
- `.listRowBackground(...)` on the Button or its parent Section
- `.listRowInsets(...)` on the Button or its parent Section
- `.listRowSeparator(.hidden)` on the Button

If any indicator is present → **list-context matched**.

### Step 5: Check for hit-region expansion

Look in the label closure for:

```swift
.contentShape(Rectangle())
.contentShape(.rect)
.contentShape(RoundedRectangle(cornerRadius: ...))
```

If present → **skip** (the author explicitly expanded the hit region, the bug is patched).

### Step 6: Emit the finding

When all four are true — custom label, trailing chevron, `.buttonStyle(.plain/.borderless)`, list context — and no `.contentShape`, flag the call site.

## Finding format

Each flagged site produces one row:

| Field | Example |
|---|---|
| **File:line** | `Sources/Features/Settings/Views/BackupDataSheet.swift:193` |
| **Button action** | `createBackup()` |
| **Label synopsis** | `HStack { icon; VStack { title; subtitle }; Spacer(); chevron.right }` |
| **Button style** | `.plain` |
| **Context** | Inside `Section` inside Form (SheetContainer) |
| **Why flagged** | Trailing chevron + .plain + Form context + no .contentShape |
| **Fix A (preferred)** | Remove `Image(systemName: "chevron.right")` from label (HIG: chevrons are for NavigationLinks, not Buttons) |
| **Fix B** | Add `.contentShape(Rectangle())` on the label's outer HStack |
| **Blast radius** | 1 call site |

## Severity

**Default:** 🟡 HIGH — user-visible interaction defect that makes the button look broken. Users tap and nothing happens.

**Elevated to 🔴 CRITICAL when:**
- The affected button is on a critical path (add-item, save, export, payment)
- 5+ sites share the pattern in a single view hierarchy (systemic UX failure)
- Accessibility audit shows VoiceOver announces the button but custom action fails on iPad

**Never lower than MEDIUM** — even "minor" buttons become trust-eroding when they don't respond to taps.

## Project-convention awareness

Reads `.radar-suite/conventions.yaml` for:

- `button_card_modifier` — e.g., `actionCard`, `destructiveCard`, `stuffolioCard`. Presence indicates the project uses custom Button card treatments, which combined with `.plain` style is the main risk zone.
- `hit_region_escape_hatch` — any project-specific modifier that applies `.contentShape(Rectangle())` internally. Treat as equivalent.

If no config is found, the detector runs on Apple API terms alone.

## Exclusions list

Skip if ANY of these hold:

- The Button is inside a `NavigationLink { } label:` or similar system-navigating container
- The Button is a toolbar item (`.toolbar { ToolbarItem { Button { ... } } }`)
- The Button has `.buttonStyle(.bordered)`, `.borderedProminent)`, or any system style other than `.plain` / `.borderless`
- The Button label is a plain `Text(...)` (no HStack, no chevron) — can't have the bug
- The file is a macOS-only view (`.macOS`, `#if os(macOS)` wrapping the whole body)
- The chevron is inside an animated DisclosureGroup custom implementation (`.rotationEffect(.degrees(isExpanded ? 90 : 0))`)

## How to present findings

### Default output

```
## Domain 13: Button Hit Region Findings

Scanned [N] Button call sites. Flagged [M] sites where a trailing chevron
+ .buttonStyle(.plain) + Form/List context + no .contentShape creates
an iPad hit-region collapse.

| # | File:line | Label | Fix (recommended) |
|---|---|---|---|
| 1 | BackupDataSheet.swift:193 | "Export Backup File" card | Remove chevron, add .contentShape |
| 2 | BackupDataSheet.swift:262 | "Import Backup File" card | Remove chevron, add .contentShape |
| 3 | [next] | ... | ... |
```

### Pattern sweep follow-up

After the first fix, run a pattern sweep across the full codebase — this bug is rarely isolated. If the project uses a shared `.actionCard()` or `.stuffolioCard()` modifier, grep for all call sites with that modifier + the chevron pattern.

## Acceptance criteria (for implementation)

A valid implementation must:

- [ ] Find every `Button { } label: { }` call site in `Sources/`
- [ ] Correctly classify each as `has-chevron-trigger` / `no-chevron` / `skipped-by-exclusion`
- [ ] Verify `.buttonStyle(.plain)` or `.buttonStyle(.borderless)` presence
- [ ] Detect Form/List context via structural walk OR modifier indicators
- [ ] Not flag Buttons that have `.contentShape(Rectangle())` in the label closure
- [ ] Not flag `NavigationLink`, `DisclosureGroup`, toolbar items
- [ ] On the Stuffolio April 2026 BackupDataSheet test case (pre-fix commit), find exactly 2 sites: `BackupDataSheet.swift:193` (Export) and `:262` (Import), with no false positives or negatives on the same file
- [ ] Produce findings in the radar-suite standard row format with file:line, action, label synopsis, context, and both fix options (A preferred, B fallback)
- [ ] Respect `.radar-suite/conventions.yaml` overrides
- [ ] Pattern-sweep mode: after a first fix is confirmed, list all other sites with the same shape across the codebase

## The bigger picture

This domain, like Domain 12 (iPad Sheet Sizing), is fundamentally a **three-factor interaction bug**: no single factor is wrong in isolation. `.buttonStyle(.plain)` is legal. Manual chevrons are legal. Buttons inside Forms are legal. The interaction between the three — on iPad specifically — breaks hit regions.

Single-file radars miss three-factor bugs because they reason about properties of one file at a time. Domain 13 is infrastructure for detecting a general class of interaction bugs where context (list cell) + component choice (`.plain` button) + content decoration (trailing chevron) combine to produce platform-specific failures.

The radar-suite memory note `cross_context_invisible_bug` covers the same pattern for SwiftData relationship bugs. UI has its own version of it, and this domain addresses one specific instance.

## Origin case detail

Stuffolio, 2026-04-22. `BackupDataSheet.swift` (iOS, iPad Pro 13" M5 sim, iOS 26.2).

Two Button call sites:

- Line 193: Export Backup File
- Line 262: Import Backup File

Both wrapped an HStack with icon + two-line text + `Spacer()` + `chevron.right`, styled with `.buttonStyle(.plain)` + `.actionCard()` / `.destructiveCard()`, placed inside a `Section` inside SheetContainer's Form.

User report: "A user must click on the Expand cheveron (>) on the Export Back-up file and Import back-up files for the cards to work. The whole card should be clickable."

Fix applied (Stufflio commit `2863e05`): removed both chevrons, added `.contentShape(Rectangle())` on the label HStack, kept `.buttonStyle(.plain)` and card modifiers. Verified — full-card tap now works on iPad.

Existing ui-enhancer-radar v3.3.0 did not flag this. Domain 9's "Sheet pattern" check looked at the sheet's use of SheetContainer (correct) and missed the inner Button hit-region bug. Domain 11's color audit had no basis to flag it. No existing domain had the three-factor heuristic. Domain 13 adds it.
