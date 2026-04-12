# Missed It By That Much
**Sayeth Maxwell Smart**

Six audit skills passed my codebase. Each one verified its own domain correctly. They collectively missed 38 fields where users enter data, save, and can never see it again.

## What happened

The extended warranty form collects 14 contact fields: phone, address, website, notes. User fills them out, hits save. The detail view shows company name and policy number. The rest vanish. Same story in the RMA model: return address, shipping costs, resolution notes. The list view shows the RMA number. 17 fields invisible unless you tap Edit.

The data was never lost. Correctly persisted, backed up, synced through CloudKit. Every auditor said "all clear."

## Why behavioral auditing didn't catch it

These aren't grep-based tools. The roundtrip auditor traces data from form entry through backup, restore, and sync. The UI path auditor walks every navigation path checking for dead ends. The data model auditor verifies every field has a consumer. They understand context and intent.

The problem is subtler: each skill's behavioral model stops at its own domain boundary.

- The roundtrip auditor asks "does the data survive the journey?" It does. Job done.
- The UI path auditor asks "can the user reach every screen and dismiss every sheet?" They can. Job done.
- The data model auditor asks "does every field have a consumer?" It does — the edit form reads it. Job done.

Every skill verified its own concern correctly. The bug lives in the gap *between* those three correct answers. The roundtrip auditor doesn't check what happens after the data arrives. The path auditor doesn't check what's displayed on the screens it verified as reachable. The data model auditor doesn't distinguish a form reading a field for editing from a view reading it for display.

## Nobody owned the user's mental model

The user's expectation is simple: "I entered data. I saved. I can see it." That expectation spans three domain boundaries: form entry (data model), persistence (roundtrip), and display (UI path). Each skill verified its slice. Nobody verified the whole thing.

If you've worked with microservices, you've seen this before. Every service passes its tests. The integration test passes. The user gets a broken experience because the contract between services was technically met but experientially wrong.

## The fix: cross-skill handoffs

I didn't need more grep or deeper behavioral tracing. We needed a new question.

The data model auditor now classifies every field consumer as `form` (read for editing), `detail` (read for display), `serialization`, or `compute`. A field with `form` + `serialization` but no `detail` consumer gets flagged and handed to the UI path auditor, which traces the post-save journey: "After save, does the destination screen actually display this field?"

Neither skill catches this alone. The data model auditor knows a field has no display consumer but can't trace navigation. The UI path auditor traces navigation but doesn't enumerate form fields. The handoff between them is what closes the gap.

## The takeaway

Domain-scoped auditing finds domain-scoped bugs. The bugs that erode user trust live in the seams between domains, where one skill's "all clear" becomes another skill's blind spot. The fix isn't smarter individual skills. It's skills that know what they can't see and hand off to the skill that can.

This is now implemented as Domain 5 in data-model-radar (form-to-detail parity) with a handoff target in ui-path-radar.
