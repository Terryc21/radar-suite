# Domains 5-8 Reference — UI Enhancer Radar
> Loaded by SKILL.md for full audit or single-domain commands: accessibility, hig, dark-mode, performance.

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
