# Compaction Rules Reference — UI Enhancer Radar
> Loaded by SKILL.md when findings recommend removing or replacing UI elements.
> Covers Phase 6b (Content Preservation), Phase 6c (Element Compaction), Phase 6d (Visual Compensation).

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
      {"label": "Both — headers + accents", "description": "Full treatment: colored header icons + per-section accent colors from project palette"},
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
