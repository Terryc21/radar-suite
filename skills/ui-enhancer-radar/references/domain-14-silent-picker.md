# Domain 14: Silent Picker — Menu Picker Fails to Present in a Custom Container

> Loaded by SKILL.md for full audit or single-domain command: silent-picker.
> Seeded from a Stuffolio session on 2026-06-27 that found the Condition, Acquired From, Room, Remind me, and three Notification Settings pickers dead-on-tap in the Add Item form. See CHANGELOG entry for ui-enhancer-radar 3.5.0.

## Why this domain exists

A default/menu-style SwiftUI `Picker` — one with no explicit `.pickerStyle(...)`, often `.labelsHidden()` — renders as an enabled pop-up button but **its menu never presents on tap** when it lives inside a *custom container* rather than a genuine `Form`/`List` row. "Custom container" means a `VStack`/`HStack` card body inside a `DisclosureGroup`, a `borderedSectionCard`, or a freestanding `ScrollView`+`VStack` screen — anywhere the surrounding `List`/`Form` row chrome has been cleared (`.listRowBackground(.clear)`, `.listRowInsets`, `.listRowSeparator(.hidden)`, or a custom row-style modifier that does the same).

The user taps the control and nothing happens. The accessibility tree reports a healthy, enabled `AXPopUpButton` with the correct `AXValue`. There is no crash, no warning, no failing test, no anti-pattern token in the source. The picker's binding is valid, its tags are valid, its `onChange` is wired. **It only shows up when a real tap lands on the control in that container.**

This is a **two-factor interaction bug**, invisible to any single-token check:

1. The `Picker` has **no explicit `.pickerStyle(...)`** (it resolves to the automatic/menu style).
2. The `Picker` is in a **custom, non-`Form`/`List` container** (cleared row chrome, `DisclosureGroup` body, `ScrollView`+`VStack`, bordered card).

When both hold, the automatic menu presentation silently fails. Add an explicit `.pickerStyle(.menu)` and it works. The proof, verified live in the same form: "Warranty Length" (`HStack`, has `.pickerStyle(.menu)`) presents fine; "Acquired From" / "Condition" (same form, no `.pickerStyle`) were dead — adding `.pickerStyle(.menu)` to Acquired From fixed it on the device.

## Relationship to Domain 13 (Button Hit Region)

Domains 13 and 14 are **cousins, not duplicates**: both produce a control that is *visually present and accessibility-enabled but functionally dead on tap*, and both are invisible to static analysis. But the mechanisms — and therefore the detectors — are different:

| | Domain 13: Button Hit Region | Domain 14: Silent Picker |
|---|---|---|
| Control | `Button { } label: { }` | `Picker(...)` |
| Trigger tokens | `.buttonStyle(.plain)` + trailing `chevron.right` + Form/List context | no `.pickerStyle` + custom (non-Form/List) container |
| What fails | Hit region collapses to the chevron (tap *misses* the action) | Menu fails to *present* (tap *lands* but nothing opens) |
| Platform | iPad-specific | iOS/iPadOS confirmed; macOS unverified (spot-check separately — see note) |
| Fix | Remove chevron / add `.contentShape(Rectangle())` | Add `.pickerStyle(.menu)` (or rebuild on `Menu` for nested tiers) |

Domain 13 greps for `Button`/`chevron`/`buttonStyle` and walks straight past `Picker`. That is exactly why the Silent Picker bug shipped with Domain 13 already in place — same symptom family, unrelated detector. Domain 14 fills the gap.

**Platform note (macOS unverified).** The origin case, the fix, and every on-device confirmation were iOS/iPadOS. macOS uses a different menu-presentation engine, so this domain's deadness claim is **not** established there. On macOS, treat flagged pickers as a *separate spot-check*: run the same candidate detection, but verify each by clicking on a real macOS build before asserting anything — do not assume the iOS failure mode transfers. If a macOS scan finds no confirmed cases, say so rather than carrying the iOS conclusion across platforms.

## Goal

Flag every `Picker` in the codebase where:

1. The `Picker` has **no explicit `.pickerStyle(...)`** in its modifier chain, AND
2. The `Picker` is rendered in a **custom container that is not a genuine `Form`/`List` row** — i.e. inside a `VStack`/`HStack` whose enclosing context is a `DisclosureGroup` body, a `ScrollView`+`VStack` screen, or a card with cleared row chrome (`.listRowBackground`, `.listRowInsets`, `.listRowSeparator`, or a project row-style modifier that clears chrome).

Produce a **candidate worklist**, not a verdict: static analysis can prove the *risk* but not the *deadness* — only an on-device tap confirms it. Each candidate is emitted with a "verify on device" step.

**Recommended fix (one line):**

- **Fix A (preferred):** add `.pickerStyle(.menu)` to the Picker's modifier chain. Verified to restore menu presentation in the affected containers; lowest-risk, single-line.
- **Fix B (only when needed):** rebuild on `Menu { Button… } label: { … }` — required only when the control needs nested/two-tier menus (e.g. a primary picker that reveals a sub-condition picker), which `Picker` can't express cleanly.

## Scope

**In scope:**
- Any `Picker(...)` call site in `Sources/`, label-hidden or not, in a custom container.
- Both `Picker("Title", selection:)` and `Picker(selection:) { } label: { }` forms.

**Out of scope:**
- `Picker` inside a genuine `Form { Section { ... } }` or `List { ... }` row — menu pickers present correctly there; this is the *normal, recommended* usage and is NOT a bug.
- `DatePicker`, `ColorPicker`, `PhotosPicker` — different controls, not affected by this presentation failure (common false positive: a `DatePicker` whose name contains "Picker").
- Pickers that already have an explicit `.pickerStyle(.segmented)`, `.wheel`, `.inline`, `.radioGroup`, or `.menu` — the explicit style is the fix; they're already safe.
- Pickers already rebuilt on `Menu { }`.

## Why Domain 13's check doesn't catch this

Domain 13 enumerates `Button { } label: { }` call sites and reasons about chevrons, `.buttonStyle(.plain)`, and hit-region collapse. It never inspects `Picker` and has no concept of `.pickerStyle`. A `Picker` is not a `Button`, so it falls entirely outside Domain 13's candidate set. The symptom looks identical to a user ("I tapped it and nothing happened"), which is precisely why the gap was easy to miss — but the detectors share no logic.

## Detection heuristic

### Step 1: Enumerate candidate Pickers

```bash
# Every Picker call site (both label forms)
grep -rn --include="*.swift" "Picker(" Sources/
```

For each hit, capture: file, line, and the full modifier chain (the lines from the closing `}` of the Picker's content to the next unrelated statement).

### Step 2: Check for an explicit `.pickerStyle`

Within the Picker's modifier chain, look for:

```swift
.pickerStyle(.menu)
.pickerStyle(.segmented)
.pickerStyle(.wheel)
.pickerStyle(.inline)
.pickerStyle(.radioGroup)
.pickerStyle(SomeCustomStyle())
```

If ANY `.pickerStyle(` is present → **skip** (the style is explicit; not the bug).

### Step 3: Reject non-Picker false positives

Skip if the call site is actually:

```swift
DatePicker(...)
ColorPicker(...)
PhotosPicker(...)
```

(The bare `grep "Picker("` matches these — filter them out by the preceding token.)

### Step 4: Classify the container (the deciding factor)

Walk upward from the Picker to determine whether it lives in a genuine `Form`/`List` row or a custom container.

**Genuine Form/List row → NOT a candidate (skip):**
- The Picker is inside a `Section { ... }` inside a `Form { ... }` or `List { ... }`, AND
- the enclosing row chrome is intact (no `.listRowBackground(.clear)` / `.listRowInsets` clearing it).

**Custom container → CANDIDATE (flag for verify):**
- The view body's top-level container is `ScrollView`, `VStack`, or `HStack` (no `Form`/`List` ancestor), OR
- the Picker is inside a `DisclosureGroup { ... }` content closure, OR
- the Picker's enclosing card/Section clears row chrome via `.listRowBackground(.clear)`, `.listRowInsets(...)`, `.listRowSeparator(.hidden)`, or a project row-style modifier (read `conventions.yaml`, see below), OR
- the Picker is inside a custom card modifier (`borderedSectionCard`, `.warrantyFormSectionBody()`, `.stuffolioCard()`, etc.).

### Step 5: Emit candidate (not verdict)

When Step 2 finds no explicit `.pickerStyle`, Step 3 confirms it's a real `Picker`, and Step 4 classifies the container as custom → flag the site as a **candidate** with a mandatory on-device verify step. Do NOT assert the picker is dead from static analysis alone; assert it is *at risk* and must be tapped on a real device/sim.

## Finding format

Each flagged site produces one row:

| Field | Example |
|---|---|
| **File:line** | `Sources/Views/Forms/WarrantyFormView+BasicSections.swift:193` |
| **Picker label** | `"Acquired From"` |
| **Style** | none (resolves to automatic/menu) |
| **Container** | `DisclosureGroup → VStack`, row chrome cleared via `.warrantyFormSectionRowStyle()` |
| **Status** | ⚠️ Candidate — verify on device |
| **Why flagged** | menu-style Picker, no `.pickerStyle`, custom non-Form container |
| **Fix A (preferred)** | Add `.pickerStyle(.menu)` |
| **Fix B (if nested tiers)** | Rebuild on `Menu { Button… }` |
| **Blast radius** | 1 call site |

## Severity

**Default:** 🟡 HIGH — a control the user taps and nothing happens; reads as a broken build.

**Elevated to 🔴 CRITICAL when:**
- The picker is on a critical path (add-item, edit-item, save, payment, onboarding). A dead control in the primary add/edit flow is a textbook **App Store Guideline 2.1 (App Completeness)** rejection trigger — "a control that does nothing."
- 3+ pickers in the same view hierarchy share the pattern (systemic).

**Never lower than MEDIUM** — even a "minor" settings picker erodes trust when it ignores taps.

## Project-convention awareness

Reads `.radar-suite/conventions.yaml` for:

- `cleared_row_style_modifiers` — project modifiers that clear List/Form row chrome (e.g. `warrantyFormSectionRowStyle`, any modifier applying `.listRowBackground(.clear)` + `.listRowInsets`). A `Picker` under one of these is in a custom container even if a `Form` ancestor exists.
- `custom_card_modifiers` — e.g. `borderedSectionCard`, `warrantyFormSectionBody`, `stuffolioCard`. A `Picker` inside one of these card bodies is a candidate.

If no config is found, the detector runs on Apple API terms alone (`Form`/`List`/`Section` ancestry + `.listRow*` modifiers + `DisclosureGroup`/`ScrollView`/`VStack` containers).

## Exclusions list

Skip if ANY of these hold:

- The Picker has an explicit `.pickerStyle(...)` of any kind.
- The Picker is in a genuine `Form`/`List` row with intact row chrome.
- The call site is a `DatePicker`, `ColorPicker`, or `PhotosPicker`.
- The Picker is already wrapped in / replaced by `Menu { }`.
- The file is a dev-only harness or `#Preview`-only view (flag at LOW / informational; not user-facing — but note it, since a reusable picker component used only by a harness today becomes a live bug the moment a real screen adopts it).

## How to present findings

### Default output

```
## Domain 14: Silent Picker Findings

Scanned [N] Picker call sites. Flagged [M] candidates where a menu-style Picker
with no .pickerStyle sits in a custom (non-Form/List) container — at risk of the
menu failing to present on tap. These are CANDIDATES: verify each on device.

| # | File:line | Picker | Container | Status | Fix |
|---|---|---|---|---|---|
| 1 | WarrantyFormView+BasicSections.swift:193 | "Acquired From" | DisclosureGroup/VStack, cleared chrome | ⚠️ verify on device | + .pickerStyle(.menu) |
| 2 | WarrantyFormView+BasicSections.swift:331 | "Room" | DisclosureGroup/VStack, cleared chrome | ⚠️ verify on device | + .pickerStyle(.menu) |
| 3 | [next] | ... | ... | ... | ... |
```

### Mandatory on-device verify step

Because static analysis cannot prove the menu fails to present, the radar MUST emit a verify instruction, not a fix-and-move-on:

> Build + run, navigate to each flagged picker, tap it, confirm the menu opens.
> A candidate whose menu opens is a false positive (some custom containers do present
> correctly); leave it and note it. A candidate whose menu does NOT open is confirmed —
> apply Fix A.

**A candidate is not a confirmed bug until tapped.** The report MUST present Domain 14 rows as *unconfirmed candidates*, never as a list of broken pickers — a hurried reader who skips the device tap will otherwise "fix" false positives. The saving grace: **Fix A (`.pickerStyle(.menu)`) is idempotent and safe to apply blindly.** Adding it to a picker that already presents correctly is a no-op (it just makes the already-implicit menu style explicit), so the worst case of acting on an unverified candidate is harmless noise in the diff, not a regression. State this trade-off in the output so the reader can choose: verify-then-fix (clean diff) or fix-all (faster, noisier, still safe).

### Pattern sweep follow-up

After the first confirmed-and-fixed case, sweep the full codebase for the same shape: `Picker` + no `.pickerStyle` + (cleared-chrome modifier OR `DisclosureGroup` body OR `ScrollView`/`VStack` screen). This bug travels in packs — the origin case had 7 instances across 4 files.

## Acceptance criteria (for implementation)

A valid implementation must:

- [ ] Find every `Picker(...)` call site in `Sources/`
- [ ] Correctly skip `DatePicker` / `ColorPicker` / `PhotosPicker` false positives
- [ ] Skip any Picker with an explicit `.pickerStyle(...)`
- [ ] Classify container as `genuine-form-list-row` (skip) vs `custom-container` (candidate) via Form/List ancestry + `.listRow*` clearing modifiers + `DisclosureGroup`/`ScrollView`/`VStack`
- [ ] Emit candidates as ⚠️ "verify on device", NOT as confirmed bugs
- [ ] Offer Fix A (`.pickerStyle(.menu)`) as default, Fix B (`Menu` rebuild) only for nested-tier pickers
- [ ] Pass the **synthetic fixture below** (portable; the authoritative acceptance test for any implementer)
- [ ] *(Maintainer-only origin reference, NOT a portable fixture — this commit lives in the private Stuffolio repo and is unrunnable by other users.)* On the Stuffolio June 2026 origin case (pre-fix commit `~32e8eb10`), flag exactly: `WarrantyFormView+BasicSections.swift:193` (Acquired From), `:331` (Room), `WarrantyFormView+AdvancedSections.swift:89` (Remind me), `NotificationSettingsView.swift:342/429/447` (3 sites), and `UnifiedFormComponents.swift` UnifiedPickerRow (LOW/component) — and NOT flag `WarrantyFormView+WarrantySections.swift:42` (Warranty Length, already `.pickerStyle(.menu)`), the three `AppleCareDetailsSection.swift` pickers (already `.menu`), or `LegacySettingsView.swift:63` (genuine Form)
- [ ] Respect `.radar-suite/conventions.yaml` overrides for cleared-row-style and custom-card modifiers
- [ ] Pattern-sweep mode after first confirmed fix

### Synthetic fixture (portable acceptance test)

Any implementer can run the detector against this self-contained sample. Expected: flag **A** and **B** as candidates; do **not** flag **C**, **D**, or **E**.

```swift
struct FixtureView: View {
    @State private var a = 0
    @State private var b = 0
    @State private var c = 0
    @State private var d = Date()

    var body: some View {
        ScrollView {                                  // custom container, not a Form
            VStack {
                // A — CANDIDATE: menu-style Picker, no .pickerStyle, custom container
                Picker("A", selection: $a) { Text("x").tag(0) }
                    .labelsHidden()

                DisclosureGroup("More") {              // custom container
                    // B — CANDIDATE: same shape inside a DisclosureGroup body
                    Picker("B", selection: $b) { Text("y").tag(0) }
                }

                // C — NOT a candidate: explicit .pickerStyle present
                Picker("C", selection: $c) { Text("z").tag(0) }
                    .pickerStyle(.menu)

                // D — NOT a candidate: DatePicker, not a menu Picker
                DatePicker("D", selection: $d)
                    .labelsHidden()
            }
        }

        Form {
            // E — NOT a candidate: genuine Form row, intact chrome
            Picker("E", selection: $a) { Text("w").tag(0) }
        }
    }
}
```

| Site | Verdict | Reason |
|---|---|---|
| A | ⚠️ candidate | menu Picker, no `.pickerStyle`, `ScrollView`/`VStack` container |
| B | ⚠️ candidate | menu Picker, no `.pickerStyle`, `DisclosureGroup` body |
| C | skip | explicit `.pickerStyle(.menu)` |
| D | skip | `DatePicker`, not a menu `Picker` |
| E | skip | genuine `Form` row with intact chrome |

A detector that flags C/D/E (false positives) or misses A/B (false negatives) fails this fixture. This is the authoritative, runnable acceptance check; the Stuffolio origin case above is a maintainer-only provenance note, not a portable test.

## The bigger picture

Like Domain 12 (iPad Sheet Sizing) and Domain 13 (Button Hit Region), this is an **interaction bug**: no single factor is wrong. A style-less `Picker` is legal and idiomatic. Custom containers are legal. The *interaction* — automatic menu presentation inside cleared-row-chrome / non-Form containers — is what fails, and only at runtime.

The deeper lesson the origin case taught: **static analysis structurally cannot find render-time presentation failures; only running the app and tapping the control can.** This domain does not pretend otherwise — it produces a *risk-ranked candidate list* and forces an on-device verify, rather than asserting deadness it can't prove. That is the honest shape of a detector for this bug class. The radar-suite memory note `cross_context_invisible_bug` covers the same "correct in isolation, broken in context" pattern for SwiftData; this is its Picker-presentation instance.

## Origin case detail

Stuffolio, 2026-06-27, build 54. Add Item form (iOS, iPhone 17 Pro sim).

User report: "While completing the rest of the item detail sheet, nothing happened when I clicked on the Condition Picker."

`ConditionPickerView` used a default-style `Picker("Condition", selection:)` `.labelsHidden()` inside `WarrantyFormView+BasicSections.swift`'s `Section → DisclosureGroup → VStack` with `.warrantyFormSectionBody()` + `.warrantyFormSectionRowStyle()` (which clears `.listRowBackground` / insets / separator). The menu was completely dead on tap. The adjacent Category control worked because it's a custom `Button` + `.sheet` (`MultiCategoryPicker`), not a `Picker` — the call-site diff was the tell.

Verified live on the sim: the dead-tap reproduced even in plain Manual Entry (not AI-specific). The fix for the two-tier Condition picker was a `Menu` rebuild (commit `32e8eb10`); bug-echo then found 6 siblings, all fixed with a one-line `.pickerStyle(.menu)` (commit `a2a64f2b`). Proof-of-mechanism pair verified on device: "Warranty Length" (`.pickerStyle(.menu)`) opened its menu; "Acquired From" (no style) was dead, then opened after adding `.pickerStyle(.menu)`.

Existing ui-enhancer-radar v3.4.0 did not flag this. Domain 13's three-factor check looked only at `Button` + chevron + hit region and had no `Picker`/`pickerStyle` logic. No existing domain inspected picker style or menu presentation. Domain 14 adds it.
