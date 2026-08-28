# Radar Suite alongside your linter

*Pulled out of the README on 2026-08-28 so the front page stays a 5-minute read. Nothing was
cut — this is the full comparison.*

Radar Suite and linters are complementary, not competitive. They look at code through different lenses and find different classes of bugs. A thorough pre-release audit runs both — neither alone is sufficient.

**Pattern-based tools (SwiftLint, custom linters, single-file audit skills)** check individual files against a rule catalog: force unwraps, missing `@MainActor`, `try?` swallowing errors, deprecated APIs, naming conventions, style. They're fast, precise, run on every save, and catch a real and important class of bugs cheaply. **They will find issues Radar Suite won't** — anything that lives inside one file's text and can be expressed as a grep pattern.

**Radar Suite** traces behavior across files. It starts from what the user sees (a screen, a flow, a backup round-trip) and follows the data through views, view models, managers, and persistence to verify the loop actually closes. It catches bugs that live in the *handoff* between files: data flow gaps, navigation dead ends, round-trip integrity loss. **It will find issues linters won't** — anything that requires reading multiple files together to spot.

Concrete example of the difference: a SwiftData `@Model` with a non-optional inverse relationship is correctly declared. SwiftLint and any pattern audit will say it's fine, because the declaration is fine. A backup→restore→edit→save cycle that loses one of those relationships in the round trip is a bug, but no single file is wrong — each file's view of the data is locally correct. Radar Suite catches the silent loss by reading the round-trip path; the linter has no reason to flag it because there's nothing in any individual file to flag.

Useful framing: pattern-based tools are the building inspector confirming each bolt is torqued to spec. Radar Suite is the home inspector who turns on the shower and checks where the water actually goes. **The inspection isn't complete without both.**

| What linters do better | What Radar Suite does better |
|---|---|
| Run on every save (cheap, fast) | Run before release (deeper, slower) |
| Catch style and pattern violations | Catch behavior and data-flow bugs |
| Single-file context | Cross-file traces |
| Hundreds of well-understood rules | Domain-specific behavior verification |
| Mature ecosystem | New approach, narrower scope |

If your project already uses SwiftLint or another pattern-based audit, keep it. Radar Suite layers on top.
