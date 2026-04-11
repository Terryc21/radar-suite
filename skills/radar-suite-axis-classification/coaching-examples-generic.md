# Coaching Examples — Generic (any iOS/Swift project)

> Anonymized worked examples covering the three axes. Every example includes full schema: axis, audience, before/after, current approach, suggested fix, better approach, tradeoffs, verification log.
>
> These examples use anonymized file references (`Sources/Managers/SomeManager.swift:NNN`). They describe pattern SHAPES, not specific projects. Project-specific overlays override these examples when a matching pattern is available.

---

## Example 1 — axis_1_bug — Async Operation Blocks Main Thread

### Finding
CSV import freezes the UI for 10-30 seconds on files larger than ~500 rows. No cancel button, no progress feedback.

### Full schema
```yaml
axis: axis_1_bug
before_after_experience:
  audience: end_user
  before: "User taps Import CSV and the app appears frozen for 10-30 seconds with no feedback and no way to cancel. On older devices some users force-quit the app thinking it crashed."
  after: "User taps Import CSV, sees a progress bar with row count, and can cancel mid-import. The import runs off the main thread so the UI stays responsive."

current_approach: |
  In Sources/Features/ImportExport/ImportCSVView.swift:142, the onTapGesture handler calls
  importer.importCSV(url) directly on the main actor. The importer then loops rows synchronously,
  calling modelContext.save() every 50 rows, still on the main actor. Total main-thread time
  scales with file size.

suggested_fix: |
  Wrap the import call in a Task with @MainActor in sync closure, and move the CPU-bound parsing
  loop to Task.detached. Add a @State var isImporting: Bool and display a progress overlay while
  true. Add a cancel button that calls importTask?.cancel(). On cancellation, roll back the partial
  import via a ModelContext rollback.

better_approach: |
  Follow the pattern at Sources/Managers/SomeAsyncManager.swift:NNN which defines a reusable
  AsyncOperation protocol with progress, cancellation, and rollback. Extract an AsyncImportOperation
  type that any future import path (JSON, XML, backup restore) can reuse. The current one-off
  import logic is the third manual implementation of the same async pattern in this codebase;
  extracting it cuts duplicated cancellation / progress / rollback code in all three call sites.

better_approach_tradeoffs: |
  Apply when: the project has 2+ import or long-running operations with similar
  progress / cancel / rollback needs. The extraction pays off starting at the third use site.

  Do not apply when: this is the only long-running operation in the codebase. For a single import,
  the extracted AsyncImportOperation is overkill and the minimum suggested_fix is enough.

verification_log:
  - check: pattern_citation_lookup
    result: "found AsyncOperation pattern at Sources/Managers/SomeAsyncManager.swift:NNN (protocol with progress/cancel/rollback)"
  - check: reachability_trace
    result: "reached from Sources/Features/ImportExport/ImportCSVView.swift:142 onTapGesture; clearly user-facing"
```

---

## Example 2 — axis_1_bug — Sheet Discards Unsaved Changes on Dismiss

### Finding
A sheet presents a form with @State var fields. Tapping the X button or swiping down dismisses the sheet immediately, discarding all user input without warning.

### Full schema
```yaml
axis: axis_1_bug
before_after_experience:
  audience: end_user
  before: "User fills out an add-item form (title, description, 3 fields). Accidentally swipes down on the sheet. All input lost. No warning, no undo, no recovery."
  after: "User swipes down. If the form has unsaved changes, a confirmation alert appears: 'Discard changes?' with Discard / Keep Editing options. Keep Editing returns to the form with all input intact."

current_approach: |
  In Sources/Views/Sheets/SomeEditSheet.swift:NNN, the form uses local @State vars for all fields.
  The sheet is presented with .sheet(isPresented:). The X button in the toolbar calls dismiss()
  directly. Swipe-to-dismiss is enabled by default. No interactiveDismissDisabled() modifier. No
  hasUnsavedChanges check anywhere.

suggested_fix: |
  Add a computed var hasUnsavedChanges: Bool that compares local @State to the initial values.
  Apply .interactiveDismissDisabled(hasUnsavedChanges) to the sheet content. Wrap the X button's
  dismiss() call in: if hasUnsavedChanges { showConfirmation = true } else { dismiss() }. Add a
  .confirmationDialog for showConfirmation with Discard / Keep Editing options.

better_approach: |
  Follow the pattern at Sources/Views/Sheets/SomeExistingSheet.swift:NNN which uses a ViewModifier
  called SheetWithUnsavedChanges. The modifier takes a hasUnsavedChanges binding and handles the
  interactiveDismissDisabled, X-button interception, and confirmation dialog in one place.
  Applying it here means 4 fewer lines of boilerplate in this view and the same pattern is
  reusable for any other form sheet. The codebase has 6 form sheets; only 1 uses the modifier
  today. This is the second use site and will make the refactor pattern obvious for the other 4.

better_approach_tradeoffs: |
  Apply when: the project has multiple form sheets that need the same unsaved-changes protection.
  The modifier extraction pays off starting at the second use site.

  Do not apply when: this is the only form sheet with meaningful unsaved state. For a one-off,
  the inline suggested_fix is cleaner than a modifier abstraction.

verification_log:
  - check: pattern_citation_lookup
    result: "found SheetWithUnsavedChanges modifier at Sources/Views/Sheets/SomeExistingSheet.swift:NNN"
  - check: reachability_trace
    result: "sheet is reached from AddItemButton in main navigation; confirmed user-facing"
  - check: whole_file_scan
    result: "scanned full file; no existing hasUnsavedChanges or interactiveDismissDisabled logic"
```

---

## Example 3 — axis_2_scatter — Empty States Handled 500 Lines Apart

### Finding
A view has 3 different "empty" conditions (loading, error, empty result). The loading state is handled at line 120, the error state at line 480, and the empty result state at line 640. The logic is correct but a developer reading the file has to scroll between three regions to understand the state machine.

### Full schema
```yaml
axis: axis_2_scatter
before_after_experience:
  audience: code_reader
  before: "A developer reading SomeLargeView.swift for the first time sees three different VStack / if-let blocks handling what should be one state machine. To trace 'what does this view show when results are empty' they have to search the file and scroll through 500+ lines of unrelated code."
  after: "The view has a single enum ViewState { case loading, error(Error), empty, loaded([Item]) } and a single switch at the top of the body. Each case has its own subview, named explicitly. A new developer sees the full state machine in 20 lines at the top of the file."

current_approach: |
  Sources/Views/SomeLargeView.swift spans 1100 lines. The body uses nested if/else:
  if isLoading { ... } else if let error = error { ... } else if items.isEmpty { ... } else { ... }
  But the three "empty" branches are not adjacent — loading is at body line 120, error at 480
  (after a long section of view builders), and the empty-list case at 640 (inside a sub-VStack
  that was added later).

suggested_fix: |
  Extract an enum ViewState at the top of the file. Add a computed var state: ViewState that maps
  the existing @State vars to the enum cases. Replace the three scattered branches with a single
  switch state at the top of body, with each case returning a named subview. Delete the now-dead
  is-loading / error / empty checks from deeper in the body.

better_approach: |
  Follow the pattern at Sources/Views/SomeWellStructuredView.swift:NNN which already uses an
  enum-with-view-method approach (ViewState enum has a method @ViewBuilder view() that returns
  the appropriate subview for each case). The codebase has 3 views using this pattern and 12 that
  do not. Bringing this view into the pattern makes it the 4th and creates momentum for the other
  migrations. The enum-with-view-method approach also unit-tests better — you can assert state
  transitions without spinning up a full view hierarchy.

better_approach_tradeoffs: |
  Apply when: the view has 3+ mutually exclusive states and a file long enough (>500 lines) that
  scattered state handlers create real navigation friction.

  Do not apply when: the view has only 2 states (loaded vs empty) or is short enough (<200 lines)
  that an inline if/else is clearer than a separate enum. Premature extraction for simple views
  adds indirection without reducing reading time.

verification_log:
  - check: pattern_citation_lookup
    result: "found enum-with-view-method pattern at Sources/Views/SomeWellStructuredView.swift:NNN"
  - check: whole_file_scan
    result: "scanned all 1100 lines; confirmed 3 scattered state handlers at 120, 480, 640"
  - check: reachability_trace
    result: "view is reached from main navigation; all three states ARE reachable (not dead code)"
```

---

## Example 4 — axis_2_scatter — Duplicated Platform Branches Across Files

### Finding
Five different views all have the same `#if os(iOS)` / `#else` fork for showing a dismiss button: iOS shows `Image(systemName: "xmark.circle.fill")`, macOS shows `Text("Done")`. Each view duplicates the same 8 lines. A fix to the pattern (e.g., adding a keyboard shortcut) requires touching all 5 files.

### Full schema
```yaml
axis: axis_2_scatter
before_after_experience:
  audience: code_reader
  before: "A developer adding a new form sheet has to copy the same 8-line #if os(iOS)/#else dismiss button block from one of the existing sheets. A developer fixing a bug in that block (e.g., adding a keyboard shortcut) has to find all 5 call sites and change each one. Grep for 'xmark.circle.fill' returns 5 independent places that must stay in sync."
  after: "There is one DismissButton view (or a .dismissButton() modifier). Every sheet uses it. Fixing the pattern means editing one file. Grep for 'DismissButton' returns one definition and 5+ usages, which is the correct shape."

current_approach: |
  Five files (SomeSheetA, SomeSheetB, SomeSheetC, SomeSheetD, SomeSheetE) each have:

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

  The duplication is mechanical. No file has a subtle platform variation; they are copy-pastes.

suggested_fix: |
  Extract a DismissButton view (or a .dismissButton() toolbar modifier) in
  Sources/Components/DismissButton.swift. Move the #if os(iOS)/#else block into the extracted
  type. Replace each of the 5 call sites with the single-line invocation.

better_approach: |
  Follow the pattern at Sources/Components/SomeExistingToolbarHelper.swift:NNN which defines a
  toolbar-placement helper that hides the platform branch from callers. The extracted DismissButton
  should follow the same shape: a @ToolbarContentBuilder func or a View conforming to ToolbarContent.
  The codebase's existing helper uses this shape; reusing it makes the new DismissButton consistent
  with the 2 existing helpers rather than introducing a 4th convention.

better_approach_tradeoffs: |
  Apply when: 3+ files duplicate the same platform-branch shape for the same concern. The
  extraction pays off at the third duplication.

  Do not apply when: the platform branches actually differ (one platform has extra logic the other
  doesn't). Extracting variable branches into a shared type hides the variation and makes debugging
  harder. If you cannot cleanly parameterize the differences, leave the duplicates.

verification_log:
  - check: pattern_citation_lookup
    result: "found toolbar helper pattern at Sources/Components/SomeExistingToolbarHelper.swift:NNN"
  - check: whole_file_scan
    result: "grepped codebase for 'xmark.circle.fill'; 5 matches across 5 files confirmed"
  - check: branch_enumeration
    result: "read both #if and #else branches in all 5 matches; confirmed mechanical duplication, no subtle differences"
```

---

## Example 5 — axis_3_dead_code — Unreachable Empty-State Branch

### Finding
A view has an `if items.isEmpty { EmptyStateView() }` branch. Tracing upstream, an outer filter removes any items collection that is empty before this view ever sees it. The empty-state branch has been unreachable since the filter was added 8 months ago.

### Full schema
```yaml
axis: axis_3_dead_code
before_after_experience:
  audience: future_maintainer
  before: "A developer reading SomeListView.swift sees an EmptyStateView branch and assumes the view handles empty collections. Spends 20 minutes tracing when that branch fires before realizing it cannot. Worse: a bug report arrives saying 'my empty collection shows no UI' and the developer trusts the branch exists, reports the bug as fixed, and does not test."
  after: "The unreachable branch is deleted. A comment at the upstream filter site documents WHY empty collections are filtered before reaching the list view. A future developer wondering 'how does this view handle empty state?' finds the answer at the filter site: it does not need to, the filter handles it."

current_approach: |
  Sources/Views/SomeListView.swift:NNN has:

    if items.isEmpty {
        EmptyStateView(message: "No items")
    } else {
        List(items) { ... }
    }

  items is a @State var assigned from a parent view. The parent filters via:
    let items = allItems.filter { $0.isActive }
  and passes items only if items.isEmpty == false (there is a ForEach containerView wrapper
  upstream that short-circuits empty collections and shows a different placeholder).

  Reachability trace confirmed: the else branch is always taken. The if branch has been
  unreachable for 8 months per git blame on the upstream filter.

suggested_fix: |
  Delete the if-empty branch. Replace the if/else with a direct List(items) call. Commit message
  should reference the upstream filter: "Delete unreachable empty state in SomeListView; upstream
  ContainerView handles empty collections at SomeContainer.swift:NNN."

better_approach: |
  In addition to deleting, add a comment at the upstream filter site
  (Sources/Views/SomeContainer.swift:NNN) documenting why the filter exists AND why downstream
  views do not need to handle empty collections. The comment is the missing context that future
  developers will look for when they reach the same confusion. Follow the pattern at
  Sources/Views/SomeOtherContainer.swift:NNN which already has a similar "empty collections are
  handled at the container level" comment.

better_approach_tradeoffs: |
  Apply when: the dead branch is genuinely unreachable (verified by reachability trace from all
  call sites) and the upstream filter or guard is not self-explanatory. A one-line comment at the
  filter site is cheap insurance against the same confusion returning.

  Do not apply when: the upstream filter is obvious from its own name (e.g.,
  nonEmptyActiveItems). In that case deleting the dead branch is enough; an extra comment adds
  noise.

verification_log:
  - check: reachability_trace
    result: "walked upstream from SomeListView.swift:NNN through 3 call sites; empty case is filtered at SomeContainer.swift:NNN before reaching the view"
  - check: pattern_citation_lookup
    result: "found existing upstream-filter documentation pattern at Sources/Views/SomeOtherContainer.swift:NNN"
  - check: whole_file_scan
    result: "scanned SomeListView.swift; no other handling of the empty case"
```

---

## Notes for Overlay Authors

Project-specific overlays (`coaching-examples-<projectname>.md`) should:

1. **Cover the same 5 pattern shapes above** at minimum (async cancel, sheet binding, scattered state, duplicated branches, unreachable branch)
2. **Replace the anonymized `Sources/Managers/SomeManager.swift:NNN` citations** with real file:line references verified to exist in the overlay's target project
3. **Add project-specific patterns** that have no generic equivalent (e.g., a project-specific framework convention, a known internal anti-pattern to contrast against)
4. **Note which examples override the generic equivalent** at the top of the file — so readers know when the overlay diverges from the generic template

A good overlay has at least 5 overrides of the generic examples plus 1-3 project-specific patterns, for a total of 6-8 worked examples.
