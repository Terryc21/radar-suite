# Domains 1-4 Reference — UI Enhancer Radar
> Loaded by SKILL.md for full audit or single-domain commands: space, hierarchy, density, interaction.

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
