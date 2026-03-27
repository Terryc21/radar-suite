# Pattern Sweep Reference — UI Enhancer Radar
> Loaded by SKILL.md during Phase 7e: Similar View Queue (after applying changes to one view).

## Phase 7e: Pattern Sweep — Similar View Queue (after applying changes to one view)

**After all approved changes are applied to a view, check if similar patterns exist in other views. Pre-generate tailored recommendations for each similar view, but require visual inspection before presenting or applying them.**

### Why pre-generate but gate on visual inspection

Code analysis CAN reliably detect structural similarity (same component, same color pattern, same layout issue). What it CANNOT do is tell you whether the fix from View A makes sense in View B — the context may be different. So:

- **Pre-generate:** Read each similar view's code, adapt the original fix to its specific structure, and prepare tailored recommendations. This is "thinking" work — safe to do without seeing the view.
- **Gate on viewing:** Present the tailored recommendations ONLY after the user can see the view. The user validates whether the recommendations make visual sense in this context.

This means the skill does the work upfront, and the user just validates — efficient without being blind.

### When to trigger

After Phase 7d completes (all approved changes applied or stopped), and at least one change was kept.

### Step 1: Find similar views and pre-generate recommendations

For each type of change that was applied:

1. **Build a grep query** from the change (e.g., if you changed `.blue` to `.purple` on a Privacy icon, search for other views with the same component/pattern)
2. **Search all view files** in Sources/
3. **For each matching view, read the code** and generate specific recommendations adapted to that view's structure. Don't just copy the original fix — account for differences:
   - Different number of sections/icons
   - Different semantic meanings (Privacy in one view vs. Network in another)
   - Different component parameters enabled
   - Different layout structure that may not need the same change

4. **Present the queue** with the full rating table:

```
Pattern: [description — e.g., "monochromatic blue icons in settings-style views"]

I found [N] views with the same pattern. I've read each one and prepared
specific recommendations based on what we changed in [original view]:

| # | View | Pattern Match | Tailored Recommendation | Severity |
|---|------|--------------|------------------------|----------|
| 1 | PrivacyNetworkView | 5/7 icons .blue | Change Network→cyan, VPN→purple, Cache→orange, keeping Privacy→blue | HIGH |
| 2 | CloudSyncView | 3/4 icons .blue | Change Zones→purple, Status→cyan, keeping Sync→blue | MEDIUM |
| 3 | NotificationSettingsView | 2/4 icons .blue | Minor — only 2 adjacent blues. Change Schedule→orange | LOW |
```

Then ask:

```
questions:
[
  {
    "question": "[N] similar views found. Walk through them one at a time? You'll view each before any changes.",
    "header": "Queue",
    "options": [
      {"label": "Start the queue (Recommended)", "description": "Open each view, review tailored recommendations, apply what looks right"},
      {"label": "Defer all", "description": "Add to DEFERRED.md for a future visual inspection session"},
      {"label": "Accept as-is", "description": "These views are fine — the pattern doesn't bother me elsewhere"},
      {"label": "Explain pros/cons", "description": "Walk through why consistency matters across views"}
    ],
    "multiSelect": false
  }
]
```

**There is no "Fix all now" option.** Every view requires visual inspection. Batch-applying visual changes across multiple views without looking at them is exactly what this skill is designed to prevent.

### Step 2: Walk through the queue (one view at a time)

For each view in the queue:

**2a. Direct user to open the view:**

> "Open **[ViewName]** in [Canvas / Simulator / device]. [Brief description of what the view shows — e.g., 'This is the privacy settings form with network, VPN, and cache sections.']"

Wait for user to confirm they can see it.

**2b. Present tailored recommendations:**

Once the user confirms, present the pre-generated recommendations for THIS specific view:

```
Based on what we changed in [original view], here's what I'd recommend for [this view]:

1. [Specific change — e.g., "Change Network section icon from .blue to .cyan"]
   Look at [specific element]. Does the blue blend with adjacent sections?

2. [Specific change — e.g., "Change VPN section icon from .blue to .purple"]
   Look at [specific element]. Would purple better distinguish this section?

Do you see the same issues here?
```

Then ask:

```
questions:
[
  {
    "question": "[ViewName]: [N] recommendations. How does it look?",
    "header": "Review",
    "options": [
      {"label": "Apply all", "description": "All recommendations look right for this view"},
      {"label": "Apply some", "description": "I'll tell you which ones to apply and which to skip"},
      {"label": "Skip this view", "description": "It looks fine as-is — move to next view"},
      {"label": "I see other things too", "description": "Apply recommendations + I'll add my own changes"},
      {"label": "Stop the queue", "description": "Done with similar views — keep remaining as-is or defer"}
    ],
    "multiSelect": false
  }
]
```

**If "Apply all":** Apply changes, direct user to verify visually, then Keep/Revert per Phase 7d flow.

**If "Apply some":** User specifies which. Apply only those.

**If "I see other things too":** Apply recommendations, then collect user-spotted issues (same as Phase 7c Part 2). This is valuable — the user is already looking at the view, so capture everything.

**If "Skip this view":** Mark as Accepted ("Looks fine on screen per user inspection"). Move to next view in queue.

**If "Stop the queue":** Ask whether remaining views should be Deferred (tracked) or Accepted (closed).

### Step 3: Queue progress

After each view in the queue, print a mini progress banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Similar views: [completed]/[total]
   [ViewA] ✅ Fixed | [ViewB] ✅ Skipped | [ViewC] ⏳ Next
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### What NOT to sweep

- Changes that were specific to one view's unique layout (not a pattern)
- Refactoring changes (sheet router enum) — these are per-view architectural decisions
- Changes the user "Skip"ped during visual review — if they said it looks fine in the original view, don't flag the same thing elsewhere
- Views the user already audited in this session — don't re-queue them
