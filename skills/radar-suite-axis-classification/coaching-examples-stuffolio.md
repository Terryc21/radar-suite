# Coaching Examples — Stuffolio Overlay

> Project-specific overlay for Stuffolio (`/Volumes/2 TB Drive/Coding/GitHubDeskTop/Stufflio`). Every citation in this file points at a real, verified file:line in the Stuffolio codebase as of 2026-04-10.
>
> When a radar audits Stuffolio with `coaching_examples: [stuffolio, generic]`, this overlay takes priority. When a pattern has no Stuffolio example, the generic fallback from `coaching-examples-generic.md` is used.
>
> **Overrides:** Examples 1-5 override the generic equivalents by the same number. Examples 6-7 are Stuffolio-specific patterns with no generic equivalent.

---

## Example 1 — axis_1_bug — Async Operation Blocks Main Thread (overrides generic #1)

### Finding
CSV import freezes the UI for 10-30 seconds on large files. (This exact issue was already fixed in commit `9ec6026` — "CSV import async + cancel + progress" — but the pattern is reusable coaching for any future blocking-operation finding.)

### Full schema
```yaml
axis: axis_1_bug
before_after_experience:
  audience: end_user
  before: "User taps an import/export/large-sync button and the app freezes for 10-30 seconds with no feedback. Some users force-quit thinking the app crashed."
  after: "User sees a progress banner with row count or byte count, can cancel mid-operation, and the UI stays responsive because the work runs off the main actor."

current_approach: |
  The blocking operation is called directly on @MainActor from a SwiftUI event handler (onTapGesture,
  toolbar button, etc.). CPU-bound work (parsing, transformation, image normalization) runs on the
  main thread. No Task wrapping, no detached work, no cancellation hook.

suggested_fix: |
  Wrap the event handler body in `Task { @MainActor in ... }` to bridge the sync SwiftUI closure
  to async. Move CPU-bound work to `Task.detached(priority: .userInitiated)` so it does not block
  the main actor. Store the task in an @State var so a cancel button can call `.cancel()`. Show
  a progress overlay bound to @State var isImporting: Bool.

better_approach: |
  Follow the pattern at Sources/Managers/CloudSyncManager.swift:104-112 which shows both halves
  of the async bridge pattern in adjacent lines:

    Task { @MainActor [weak self] in
        await self?.initializeCloudKitIfNeeded()
        self?.loadSyncPreferences()
    }

    Task.detached(priority: .background) {
        CKRecordMapper.purgeStaleStagingFiles()
    }

  The @MainActor bridge handles actor-isolated state updates. The Task.detached handles CPU work
  that must not block. Stuffolio CLAUDE.md line ~180 documents this as the canonical "async bridge
  in sync callbacks" pattern. Reuse it here rather than inventing a new shape.

better_approach_tradeoffs: |
  Apply when: the operation is >200ms of CPU work OR involves file I/O on large files OR calls
  external services. The Task.detached cost (actor hop, reference capture) is worth it.

  Do not apply when: the operation is <50ms (parsing a single short string, updating an enum).
  The actor-hop overhead outweighs the benefit; just do the work on @MainActor.

verification_log:
  - check: pattern_citation_lookup
    result: "found canonical async-bridge pattern at Sources/Managers/CloudSyncManager.swift:104-112 (both @MainActor bridge and Task.detached in adjacent init lines)"
  - check: reachability_trace
    result: "operation is reached from a SwiftUI event handler; user-facing confirmed"
```

---

## Example 2 — axis_1_bug — Sheet Discards Unsaved Changes on Dismiss (overrides generic #2)

### Finding
A sheet presents a form with `@State` fields. Tapping the X button or swiping down discards input with no confirmation. (Pattern already fixed once at `ExpandedNotesSheet` per commit `10f4396`; this is reusable coaching for future form sheets.)

### Full schema
```yaml
axis: axis_1_bug
before_after_experience:
  audience: end_user
  before: "User fills out a form (title, description, notes, etc.) inside a sheet. Accidentally swipes down or taps X. All input lost. No warning, no undo, no recovery."
  after: "User swipes down or taps X. If the form has unsaved changes, a confirmation alert appears with Discard / Keep Editing. Keep Editing returns to the form with input intact."

current_approach: |
  A sheet uses local @State vars for form fields. The toolbar X button calls dismiss() directly.
  Swipe-to-dismiss is enabled by default. No hasUnsavedChanges computed, no interactiveDismissDisabled
  modifier, no confirmation dialog.

suggested_fix: |
  Add a computed `var hasUnsavedChanges: Bool` that compares current @State to initial values.
  Apply `.interactiveDismissDisabled(hasUnsavedChanges)` to the sheet root. Wrap the X button's
  dismiss() call in `if hasUnsavedChanges { showConfirmation = true } else { dismiss() }`. Add a
  `.confirmationDialog` with Discard / Keep Editing options.

better_approach: |
  Follow the pattern used at Sources/Features/ItemManagement/Views/AddItemSheetWrapper.swift:416,
  431, 441 which tracks sheet presentation state via @State bool flags and binds them to .sheet
  modifiers cleanly. Stuffolio CLAUDE.md has the sheet styling convention under "Sheet Styling"
  (SheetContainer + SheetHeader from SheetStyles.swift) — this is the conventional wrapper for
  any new sheet. Apply both: SheetContainer for styling consistency AND the unsaved-changes
  confirmation for data safety.

  If the same pattern is needed in 3+ form sheets, extract a SheetWithUnsavedChanges ViewModifier
  to Sources/Views/Components/ next to SheetStyles.swift.

better_approach_tradeoffs: |
  Apply when: the sheet has any user input that is not immediately persisted (notes, titles,
  multi-field forms). Stuffolio has 6+ form sheets; every new one needs this protection.

  Do not apply when: the sheet is read-only (detail view, image preview) or the fields are
  immediately bound to the model via @Bindable. Immediate binding removes the unsaved-changes
  window entirely and confirmation becomes noise.

verification_log:
  - check: pattern_citation_lookup
    result: "found sheet-presentation pattern at Sources/Features/ItemManagement/Views/AddItemSheetWrapper.swift:416,431,441"
  - check: whole_file_scan
    result: "scanned full sheet file; no existing hasUnsavedChanges or interactiveDismissDisabled"
```

---

## Example 3 — axis_2_scatter — Scattered State Handlers in a Large Stuffolio View (overrides generic #3)

### Finding
A SwiftUI view longer than 1000 lines has multiple state branches (loading / error / empty / loaded) handled in different regions of the file. The logic is correct but a developer reading the file has to scroll between regions to trace the state machine.

### Full schema
```yaml
axis: axis_2_scatter
before_after_experience:
  audience: code_reader
  before: "A developer reading LegacyWishesView.swift (1169 lines), SettingsView.swift (1108), or MyProductsView.swift (1101) sees state handling scattered across multiple view-builder regions. Tracing 'what does this view show in state X' requires grep + scroll + mental stitching."
  after: "Each large view has a state enum at the top of the file and a single switch at the top of body. Each case is a named subview. A new developer sees the full state machine in 20 lines at the top of the file."

current_approach: |
  The file is >1000 lines. State is tracked via multiple @State bools (isLoading, hasError, items,
  etc.). Body uses nested if/else with the branches spread across hundreds of lines of view
  builders. There is no explicit state enum.

suggested_fix: |
  Extract an enum ViewState at the top of the file. Add a computed `var state: ViewState` that
  maps the existing bools/arrays to the enum cases. Replace the scattered branches with a single
  switch state at the top of body. Each case returns a named subview (e.g.,
  @ViewBuilder private var emptyStateView: some View).

better_approach: |
  Follow the pattern at Sources/Views/Navigation/NavigationTypes.swift:21 which defines
  NavigationPhase as a String-backed enum with CaseIterable and computed properties
  (label, color) per case. That shape is already used for navigation phases; adopt the same
  shape for view state enums in oversized files.

  Combined with Stuffolio CLAUDE.md's "File Size Guidelines" rule (split views >1000 lines),
  the state enum extraction is the first step toward making a >1000-line view splittable: once
  state is explicit, subviews can take state as a parameter instead of reaching into outer @State.

better_approach_tradeoffs: |
  Apply when: the view is >800 lines AND has 3+ mutually exclusive states AND state handling is
  visibly scattered (not all in one region). Stuffolio has 6+ views meeting this bar.

  Do not apply when: the view is <400 lines, the state is loaded/empty only, or the existing
  if/else is already in one contiguous block at the top of body. Premature extraction adds
  indirection without saving reading time.

verification_log:
  - check: pattern_citation_lookup
    result: "found String-backed enum with per-case computed properties at Sources/Views/Navigation/NavigationTypes.swift:21"
  - check: whole_file_scan
    result: "scanned the flagged oversized file; confirmed state branches are not contiguous"
  - check: reachability_trace
    result: "all state branches are reachable; not dead code"
```

---

## Example 4 — axis_2_scatter — Duplicated iOS/macOS Dismiss Button Blocks (overrides generic #4)

### Finding
Stuffolio has 266 `#if os(iOS)` blocks. Many dismiss buttons, toolbar placements, and keyboard handling blocks duplicate the same platform-branch shape across multiple views. CLAUDE.md explicitly flags the iOS-only-dismiss-button bug pattern.

### Full schema
```yaml
axis: axis_2_scatter
before_after_experience:
  audience: code_reader
  before: "A developer adding a new sheet copies the same #if os(iOS) / #else dismiss-button block from an existing sheet. Grep for 'xmark.circle.fill' returns many independent places that must stay in sync. Fixing one site means finding and updating all of them manually."
  after: "There is one DismissButton view (or a .dismissButton() toolbar modifier) in Sources/Views/Components/. Every sheet uses it. Fixing the pattern means editing one file."

current_approach: |
  Multiple sheet files repeat the same shape:

    ToolbarItem(placement: .cancellationAction) {
        Button {
            dismiss()
        } label: {
            #if os(iOS)
            Image(systemName: "xmark.circle.fill")
            #else
            Text("Done")
            #endif
        }
    }

  Stuffolio CLAUDE.md "Cross-Platform UI Verification" section shows this EXACT pattern as the
  "correct" shape to copy; the intended next step was to extract it once it appeared in 3+ places.
  That extraction never happened.

suggested_fix: |
  Extract DismissButton to Sources/Views/Components/DismissButton.swift (or extend SheetStyles.swift
  with a .dismissButton() modifier). Move the #if/#else into the extracted type. Replace each call
  site with the single-line invocation.

better_approach: |
  Follow the existing component-extraction pattern in Sources/Views/Components/ (e.g.,
  SheetStyles.swift's SheetContainer and SheetHeader). DismissButton belongs in the same file or
  as a sibling; it is conceptually part of the sheet-styling convention.

  When extracting, preserve the `placement: .cancellationAction` parameter so callers can still
  override placement for unusual sheets. Use @ToolbarContentBuilder to keep the API composable
  with the existing ToolbarItemGroup patterns.

better_approach_tradeoffs: |
  Apply when: 3+ sheets duplicate the same platform-branch dismiss button. The extraction pays off
  starting at the third duplication and scales linearly after.

  Do not apply when: a sheet has a deliberately different dismiss label (e.g., "Save & Close"
  instead of "Done") or uses a non-standard placement. Extracting such variations into a shared
  type hides the difference and makes future changes harder.

verification_log:
  - check: pattern_citation_lookup
    result: "found existing component-extraction pattern at Sources/Views/Components/SheetStyles.swift (SheetContainer, SheetHeader)"
  - check: branch_enumeration
    result: "read both #if and #else branches in 3 sample matches; confirmed mechanical duplication across files"
  - check: whole_file_scan
    result: "grepped codebase for '#if os(iOS)' with 'xmark.circle.fill'; multiple independent matches"
```

---

## Example 5 — axis_3_dead_code — Unreachable Branch in a Stuffolio View (overrides generic #5)

### Finding
A SwiftUI view has a conditional branch that is unreachable because an upstream guard or filter prevents the condition from ever being true.

### Full schema
```yaml
axis: axis_3_dead_code
before_after_experience:
  audience: future_maintainer
  before: "A developer reading the view assumes the branch handles the condition. Spends time tracing when it fires before realizing it cannot. Worse: a bug report arrives, the developer trusts the branch exists, and ships without testing."
  after: "The unreachable branch is deleted. A comment at the upstream guard site documents WHY the downstream view does not need to handle the condition."

current_approach: |
  The view has an if/else or guard branch whose condition is always false (or always true) in
  production because an upstream guard, filter, or init-time check removes the case before the
  view is rendered. Reachability trace confirmed via walking call sites.

suggested_fix: |
  Delete the unreachable branch. Commit message references the upstream guard by file:line
  to explain the deletion ("upstream guard at X.swift:NNN ensures this case never reaches the
  view").

better_approach: |
  In addition to deleting, add a 1-2 line comment at the upstream guard site documenting that
  downstream views rely on the guard. The comment is the missing context that prevented the dead
  code from being deleted earlier.

  For the specific pattern of type-depth crash avoidance, follow the pattern at
  Sources/Views/Detail/EnhancedItemDetailView+Sections.swift:760-772 which explicitly documents
  WHY the sections are split into 3 groups (prevents a runtime crash from excessive generic
  type nesting). That kind of "here is why this split exists" comment is the template for
  upstream-guard documentation.

better_approach_tradeoffs: |
  Apply when: the dead branch has been dead for >3 months AND the upstream guard is not
  self-documenting. The comment at the guard site is cheap insurance against future re-introduction.

  Do not apply when: the upstream guard is obviously named (e.g., nonEmptyActiveItems). In that
  case deleting the dead branch is enough; an extra comment adds noise.

verification_log:
  - check: reachability_trace
    result: "walked upstream call sites; branch is unreachable due to guard/filter at [cite actual file:line]"
  - check: pattern_citation_lookup
    result: "found documented-split pattern at Sources/Views/Detail/EnhancedItemDetailView+Sections.swift:760-772"
  - check: whole_file_scan
    result: "confirmed no other handling of the unreachable case in the same file"
```

---

## Example 6 — axis_1_bug — Device-Only Crash from Swift Generic Type Depth (Stuffolio-specific)

### Finding
A SwiftUI view with a large `VStack` containing many conditional sections crashes on-device with `SubstGenericParametersFromMetadata failure`. The crash does not reproduce in the simulator because the simulator's Swift runtime handles deeper generic type metadata than the device runtime. This is a real active issue in Stuffolio (per MEMORY.md `device_crash_detail_view.md`).

### Full schema
```yaml
axis: axis_1_bug
before_after_experience:
  audience: end_user
  before: "User taps an item in My Products on their iPhone. App crashes. The crash does not happen in the simulator, so developers do not see it until a TestFlight tester reports it."
  after: "User taps the item. The detail view loads normally. The view hierarchy has been restructured so the Swift type checker produces shallower generic metadata, below the device runtime's limit."

current_approach: |
  A SwiftUI view's body is a single large VStack (or similar ViewBuilder container) containing
  12+ conditional branches, @ViewBuilder calls, or ForEach + if combinations. The Swift compiler
  produces deeply nested generic metadata for the combined View type. On-device, the Swift runtime
  hits a metadata-size limit and throws SubstGenericParametersFromMetadata failure at render time.
  Simulator runtime tolerates the deeper metadata; device does not.

suggested_fix: |
  Split the large ViewBuilder container into 2-4 smaller @ViewBuilder computed properties grouped
  by concern. Each group becomes its own "chunk" in the type metadata tree, keeping any single
  type's generic depth below the device runtime limit. Test the fix on a physical device, not
  just in the simulator.

better_approach: |
  Follow the exact pattern at Sources/Views/Detail/EnhancedItemDetailView+Sections.swift:760-772
  which solves this crash by splitting a single large VStack into 3 @ViewBuilder groups:
  coreSectionsGroup, collapsibleSectionsGroup, supplementarySectionsGroup. The file has a doc
  comment explaining WHY the split exists ("A single VStack with 16+ conditional sections caused
  runtime crashes on device (SubstGenericParametersFromMetadata failure due to excessive type
  nesting)") — that comment is the template for documenting similar splits elsewhere.

  When you apply this pattern, ALWAYS write the same style of WHY comment at the split point.
  A future developer who sees 3 @ViewBuilder groups might be tempted to "clean up" by merging
  them back into one VStack; the comment is the only thing stopping that regression.

better_approach_tradeoffs: |
  Apply when: a view's body contains 10+ conditional branches OR crashes only on device with
  SubstGenericParametersFromMetadata. The split is necessary, not optional.

  Do not apply when: the view has <6 branches. Premature splitting for small views adds
  indirection without fixing a real crash.

verification_log:
  - check: pattern_citation_lookup
    result: "found canonical type-depth split pattern at Sources/Views/Detail/EnhancedItemDetailView+Sections.swift:760-772 with explanatory doc comment at 760-762"
  - check: reachability_trace
    result: "crash is reached from My Products item tap; user-facing, device-reproducible"
```

---

## Example 7 — axis_2_scatter — Singleton `.shared` Without Protocol Abstraction (Stuffolio-specific)

### Finding
Stuffolio has 1014 `.shared` references across 228 files. Only 3 of 35+ managers currently have protocol abstractions (CloudSyncManaging, BackupManaging, KeychainManaging). The codebase has an incremental code-quality strategy documented in MEMORY.md: when touching a manager file, add a protocol if missing and update callers in files you are already editing.

### Full schema
```yaml
axis: axis_2_scatter
before_after_experience:
  audience: code_reader
  before: "A developer writing a test for any view that depends on a manager (e.g., ShoppingManager, AnalyticsManager) cannot inject a mock. The view holds ShoppingManager.shared directly, so tests either hit the real manager (slow, flaky) or the test is skipped. New ViewModels copy this shape because it is the only pattern that exists."
  after: "Every manager that is depended on by a testable ViewModel has a matching protocol (ShoppingManaging, AnalyticsManaging, etc.). Views and ViewModels receive the protocol via init. Tests inject a mock conforming to the protocol. The migration is incremental: each manager gets its protocol the next time it is touched for another reason."

current_approach: |
  A manager is referenced as Manager.shared across N files. The manager does not have a matching
  protocol. ViewModels and views hold the concrete type. Tests cannot substitute a mock. New code
  copies this shape from adjacent code that does the same.

suggested_fix: |
  1. Create Sources/Protocols/<ManagerName>Managing.swift with the protocol (methods + observable
     properties the callers actually use)
  2. Conform the existing manager to the protocol
  3. Update the ViewModels and views in files being touched in the current task to receive the
     protocol via init (use an environment dependency or direct injection)
  4. Do NOT refactor callers in files outside the current task's scope — that is scope creep.

better_approach: |
  Follow the exact shape at Sources/Protocols/CloudSyncManaging.swift:14-15:

    @available(iOS 17.0, macOS 14.0, *)
    @MainActor
    protocol CloudSyncManaging: AnyObject {
        // state properties and methods...
    }

  The @available annotation matches the project's iOS 17.6+ / macOS 14.6+ deployment target. The
  @MainActor annotation matches the Swift 6.2 concurrency rule from CLAUDE.md ("@MainActor on
  ViewModels, not individual methods"). AnyObject enables the `as AnyObject` equality that
  Observable classes use.

  Stuffolio MEMORY.md documents this as the incremental code quality strategy: do not refactor
  the whole codebase; add protocols the next time you touch a manager. This coaching recommends
  exactly that: introduce the protocol, update the callers in the current task's scope, move on.

better_approach_tradeoffs: |
  Apply when: the current task touches a manager file AND the manager has no protocol AND there
  is at least one caller in the same task scope that would benefit from testability.

  Do not apply when: the current task does not touch the manager file. Following the manager
  across the codebase to add a protocol is scope creep and violates the incremental strategy.
  Save the protocol work for the next session that naturally lands in that manager's file.

verification_log:
  - check: pattern_citation_lookup
    result: "found existing protocol pattern at Sources/Protocols/CloudSyncManaging.swift:14-15 (@available, @MainActor, AnyObject)"
  - check: whole_file_scan
    result: "scanned current task's touched files for .shared references; identified N sites that can be converted in scope"
  - check: reachability_trace
    result: "not applicable for axis_2 scatter; audience is code_reader not end_user"
```

---

## Notes for Future Overlay Maintenance

**When adding a new Stuffolio pattern:**

1. Verify the cited file:line actually exists in the current HEAD (file paths and line numbers drift as the codebase evolves)
2. Prefer citing patterns from `Sources/Protocols/`, `Sources/Views/Components/`, `Sources/Utilities/`, or `Sources/Features/*/Views/` — these are the most stable locations
3. Re-verify citations when a major refactor lands (e.g., when any view in CLAUDE.md's "Implementation Status" table moves from ⏳ Planned to ✅ Complete)

**When removing an example:**

- If a pattern is deprecated (e.g., Stuffolio moves from @StateObject to @State per MEMORY.md modernization notes), update the example to cite the new pattern, do not delete it. Coaching readers need to see what the modern shape looks like.

**When Stuffolio grows new framework conventions:**

- New patterns for Foundation Models, CloudKit SyncEngine, SwiftData VersionedSchema, etc. should be added as additional examples (8, 9, 10...). Do not overwrite the existing 7.
