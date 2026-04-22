# Domain 12: iPad Sheet Sizing — Caller-Side Audit

> Loaded by SKILL.md for full audit or single-domain command: ipad-sheets.
> Seeded from a Stuffolio session on 2026-04-22 that found 25 iPad-truncating sheets missed by existing domains. See CHANGELOG entry for ui-enhancer-radar 3.3.0.

## Why this domain exists

Domain 9's existing "Sheet pattern" check (SKILL.md lines 775, 829-837) runs from the **presented view's side** — it asks "does this view's body start with `SheetContainer { ... }`?" That catches presented-view authors who didn't adopt the house-style container.

It does NOT catch the **caller-side defect**: a `.sheet(isPresented:)` or `.sheet(item:)` closure that presents a tall view which bypasses both the house container AND the Apple iPad-sizing APIs. On iPad, such sheets render as a floating form sheet (~540×620pt) that truncates long content. On iPhone, they render correctly because iPhone sheets default to full height.

The defect is quiet: it doesn't crash, doesn't warn, doesn't fail tests, and only manifests on iPad. It's the kind of bug ui-enhancer-radar's "Adaptive View Profile" is designed for, but no current domain enumerates `.sheet(...)` call sites.

## Goal

For every `.sheet(isPresented:)` and `.sheet(item:)` closure in the codebase, verify that tall presented content (Form / List / ScrollView) has been given an iPad sizing mechanism, via one of:

1. A house-style container that handles iPad sizing internally (e.g., Stuffolio's `SheetContainer`)
2. Apple's `.presentationSizing(.page)` (iOS 18+)
3. Apple's `.presentationDetents([.large])` (iOS 17)
4. A project-specific convenience modifier that applies the above (e.g., Stuffolio's `.iPadPageSheet()`)

When none is present and the content is tall, flag the call site.

## Scope

**In scope:** `.sheet(isPresented:)` and `.sheet(item:)` call sites anywhere in `Sources/`.

**Out of scope (skip):**
- `.popover(...)` — popovers have separate sizing rules
- `.confirmationDialog(...)` — always small on iPad
- `.fileImporter(...)` / `ShareLink` — system-provided, not app-sized
- `.fullScreenCover(...)` — already fills the screen
- `.alert(...)` — fixed size
- Photo/document pickers (`PhotosPicker`, `PHPickerViewController` wrappers)
- Barcode/camera scanners — typically full screen by design
- Presented views whose body is a single-action view (one button, one message)

## Heuristic — step by step

### Step 1: Enumerate call sites

```bash
grep -rn --include="*.swift" -E "\.sheet\(isPresented:|\.sheet\(item:" Sources/
```

Record each hit as `{file, line, state_binding_or_item, closure_body_type}`.

### Step 2: Classify the presented view

For each call site, identify the top-level expression in the closure. Handle these shapes:

| Closure shape | Classification |
|---|---|
| `SomeView()` | Look up `SomeView`'s body. |
| `SomeView().modifier()` | Look up `SomeView`'s body. |
| `NavigationStack { SomeView() }` | Closure itself wraps — check `SomeView`'s body, and the NavigationStack is the outermost expression for modifier placement. |
| `if let x = y { SomeView(x) }` | Conditional — check the inner view's body. Apply the modifier inside the branch. |
| `if X { ViewA() } else { ViewB() }` | Conditional — each branch needs its own check (may apply to one branch only). |
| `PhotosPicker(...)`, `ShareSheet(...)`, `ScannerView`, `*PickerView` | **Skip** — see exclusion list. |

### Step 3: Read the presented view's body

Grep for the presented view's type definition (`struct SomeView.*: View`), then read its `body` property. Classify:

| Body starts with | Verdict |
|---|---|
| `SheetContainer { ... }` (or any project's house container with built-in iPad sizing) | **Skip** — already sized. |
| `NavigationStack { Form { ... } }` | **Tall** — qualifies for the modifier. |
| `NavigationStack { List { ... } }` | **Tall** — qualifies. |
| `NavigationStack { ScrollView { ... } }` | **Tall** — qualifies. |
| `NavigationStack { VStack { ... } }` | **Borderline** — tall if the VStack contains a scrollable child (ScrollView/List/LazyVStack-in-ScrollView) with dynamic content. Flag as medium-confidence. |
| `NavigationStack { Group { switch ... case ... } }` | **Borderline** — at least one case must be tall (List/ScrollView/Form). Flag as medium-confidence. |
| Bare `VStack`/`HStack` (no NavigationStack, no scroll container) | **Not tall** — skip unless the VStack contains very long content. |

### Step 4: Check the caller's modifier chain

Inspect the `.sheet { ... }` closure for existing sizing modifiers:

```bash
# Within the closure's text range, look for:
.presentationSizing(.page)
.presentationDetents(\[.large\])
.iPadPageSheet()
# or whatever project convenience modifier equivalent
```

If any are present → **skip**, already handled.

### Step 5: Emit the finding

When all of the following are true, flag:

- Call site is `.sheet(...)` (not an excluded presentation style)
- Presented view's body does NOT route through a recognized sizing container
- Presented view's body IS tall (Form / List / ScrollView at the top level, or medium-confidence equivalent)
- The sheet closure does NOT already have a sizing modifier

## Project-convention awareness

The heuristic above covers Apple APIs (`presentationSizing`, `presentationDetents`) in a vendor-neutral way. House-style containers and modifiers are project-specific; learn them from these sources, in order:

1. **Explicit config:** `.radar-suite/conventions.yaml` with keys `sheet_sizing_container` (e.g., `SheetContainer`) and `sheet_sizing_modifier` (e.g., `iPadPageSheet`). If present, treat these as recognized sizing mechanisms alongside Apple APIs.

2. **CLAUDE.md:** Search for phrases like `SheetContainer`, `iPadPageSheet`, `.presentationSizing`, `presentationDetents` in the project's CLAUDE.md. If the project documents a sheet-sizing convention, respect it.

3. **Codebase inference:** Grep for a `View` extension named `*PageSheet*`, `*IPadSheet*`, or similar in `Sources/Views/Components/`. If a modifier is defined with `presentationSizing(.page)` or `presentationDetents([.large])` inside it, treat calls to that modifier as satisfying the sizing requirement.

If none of the above finds a project convention, the detector still works on Apple APIs alone — findings will recommend `.presentationSizing(.page)` / `.presentationDetents([.large])` directly.

## Finding format

Each flagged site produces one finding row:

| Field | Example |
|---|---|
| **File:line** | `Sources/Views/Lists/RMAListView.swift:210` |
| **State binding** | `$showingAddRMA` |
| **Presented view** | `RMAFormView` (body: `NavigationStack { Form }`) |
| **Why flagged** | Tall Form/List/ScrollView content, no sizing container, no sizing modifier |
| **Confidence** | High (Form/List/ScrollView at top) / Medium (VStack wrapping scrollable) |
| **Suggested fix** | Append `.iPadPageSheet()` inside the sheet closure (project convention) OR `.presentationSizing(.page)` (Apple default) |
| **Blast radius** | 1 call site |

## Severity

Per radar-suite conventions:

- **Default:** 🟢 MEDIUM (user-visible iPad UX defect; not a crash or data-loss)
- **Elevated to 🟡 HIGH** when: (a) the app is actively iPad-facing, (b) 5+ sites share the issue (systemic), or (c) the presented view is a critical flow (add-item, settings root, legal/compliance sheet).

## Exclusions list (skip entirely)

Bake these into the detector as a deny-list of presented-view type-name patterns:

- `PhotosPicker`, `*PhotoPicker*`
- `PHPickerViewController`, any wrapper named `*PHPicker*`
- `*ScannerView`, `*BarcodeScannerView`, `*QRScannerView`
- `ShareSheet`, `ShareLink`, `UIActivityViewController` wrappers
- `*Picker*Sheet` — small selection pickers (item pickers, damaged-items pickers, AI product pickers)
- `ColorPicker`, `DatePicker` wrappers
- `SplashScreenView`, `OnboardingView`, `*IntroView*` (intentional full-screen or custom sizing)
- `*ChooserView`, `*ChooserSheet` (option chooser UIs — short by design)

Also skip any view whose file name or symbol name matches `*Picker*` if its body contains only a `List`/`Menu` with selection logic and no Form/ScrollView (pure selection UI).

## Borderline cases and how to present them

Views using `NavigationStack { VStack { Header; mainContent } }` where `mainContent` is a conditional tree (empty state, loading state, list state) are the common borderline pattern. Recommended approach:

- Flag as **Medium confidence** — don't auto-include in "High" batch.
- Provide a one-line synopsis of `mainContent`'s tallest state (e.g., "mainContent includes a `List` in the `resultsView` branch").
- Let the auditor decide whether to include in the fix.

## Integration with existing domains

- **Domain 9 "Sheet pattern":** complementary, not duplicate. Domain 9 fires on the presented view ("why doesn't this view use SheetContainer?"). Domain 12 fires on the caller ("why doesn't this call site apply a sizing modifier?"). A well-factored codebase may legitimately have caller-side sizing without using a house container (e.g., `.presentationSizing(.page)` directly), so both domains need to exist.
- **Domain 3c "Content-to-Chrome Ratio":** related symptom. A truncated iPad sheet shows less content; but 3c measures a single view's layout, not cross-file caller relationships. This domain finds the root cause for a subset of 3c failures.
- **Capstone-radar:** inherit findings; bump the "iPad readiness" sub-grade when this domain fires more than 5 times.

## Example — the Stuffolio case that seeded this domain

Stuffolio (April 2026) had 25 `.sheet(...)` call sites across 9 files that all qualified: tall presented content (Form/List/ScrollView in NavigationStack) with no `SheetContainer` route and no sizing modifier.

- Call-site examples: `SettingsView.swift:290` (OptInPreferencesView), `RMAListView.swift:210` (RMAFormView), `SystemView.swift:185` (InventoryPreferencesView).
- Fix was mechanical: append `.iPadPageSheet()` inside the sheet closure, wrapped in `#if os(iOS)` because the project's `.iPadPageSheet()` is iOS-only.
- Full audit took ~15 minutes manually; a single radar-suite pass should take the same time at most, and catch every site with deterministic reasoning.

Neither ui-enhancer-radar, ui-path-radar, nor roundtrip-radar found this class of defect, because each reasons about a single view or a single flow, not about caller→callee presentation metrics. That's the blind spot this domain closes.

## Acceptance criteria (for implementation)

A valid implementation of this domain must:

- [ ] Find every `.sheet(isPresented:)` / `.sheet(item:)` in `Sources/` in one pass.
- [ ] Correctly classify each as `apple-sized` / `house-container` / `modifier-applied` / `needs-sizing` / `skipped-by-exclusion`.
- [ ] On the Stuffolio April 2026 test case (if re-run against the pre-fix commit), find all 25 qualifying sites with no more than 3 false positives and no more than 2 false negatives.
- [ ] Produce findings in the radar-suite standard row format with file:line, state binding, presented view, and suggested fix (project convention or Apple API).
- [ ] Respect `.radar-suite/conventions.yaml` overrides if present.
- [ ] Skip all items on the exclusions list without false alarms.
