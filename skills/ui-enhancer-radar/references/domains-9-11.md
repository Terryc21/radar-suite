# Domains 9-11 Reference — UI Enhancer Radar
> Loaded by SKILL.md for full audit or single-domain commands: design-system, color.

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

1. **Colored section header icons** — Each section gets a semantically colored icon circle (e.g., Network = blue cloud, Privacy = red shield, Cache = purple database). This alone breaks the monochrome wall into scannable zones.
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

**Refinement History** records what was tried during the refinement loop (Phase 7f) — both kept and reverted changes. This serves two purposes:
1. If the user returns and says "I liked the spacing we tried last time," the history shows what values were used
2. It reveals patterns — if the user consistently asks for tighter spacing, future audits should start with tighter recommendations
