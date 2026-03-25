# Why Fidelity Checks?

AI audit tools have a credibility problem: they can sound confident while being shallow. An LLM can write "backup coverage verified" without having read the backup code. It can grade a domain A- based on vibes rather than evidence. And once a finding is stamped "verified," nobody questions it.

The radar skills include fidelity checks — structural constraints that make deep work easier than shortcuts, and make shallow work visible when it happens.

## The Problem They Solve

Without fidelity checks, an AI auditor will:
- Claim a domain is "clean" without reading the relevant files
- Produce the same grade regardless of how thoroughly it checked
- Treat every finding as equally certain, whether it read 50 lines of code or zero
- Report what's easy to find rather than what's risky to miss

These aren't malfunctions — they're the default behavior of language models optimizing for plausible output. Fidelity checks redirect that optimization toward provable output.

## The Checks

### Tier 1: Implemented

**1. Work receipts.** Every "verified" finding must cite specific file:line evidence — what file was read, what was searched for, what was found. No receipt means automatic downgrade to "probable." This makes the difference between verified and unverified findings visible to the user, not hidden inside the AI's reasoning.

**2. Contradiction detection.** Before presenting grades, the AI runs a mechanical consistency check: if a domain has CRITICAL findings, its grade can't be above C; if it has HIGH findings, the grade can't be above B+. Simple arithmetic, but it catches the common failure mode where the AI writes serious findings and then assigns a high grade anyway.

**3. Template-driven verification.** Instead of asking the AI to "check serialization coverage," the skill provides a pre-populated table with every field from the model and columns for each serialization target. The AI fills in yes/no/? for each cell. This makes deep verification the path of least resistance — filling in a table is easier than deciding what to check.

**4. Three-category classification.** Every finding is classified as a bug (code does something wrong), stale code (code was correct when written but the codebase grew around it), or design choice (intentionally limited scope with documented evidence). Without this, the AI reports everything as "an issue" and the developer can't tell what needs fixing versus what was a deliberate decision.

**5. Staleness detection via git history.** When code looks incomplete, the skill checks when it was last modified and how the model has grown since then. "This mapper was written when Item had 36 fields. Item now has 92 fields. The mapper didn't keep up." This separates neglect from intent — and frames it as growth rather than criticism.

**6. Developer growth awareness.** A solo developer's codebase reflects multiple versions of themselves. Early code reflects early understanding. The skills frame findings as "your current code in [newer file] handles this correctly — this older code predates that pattern" rather than "this code is wrong." The developer who builds tools to audit their own code is already doing something most developers don't.

### Tier 2: Next

**7. Two-pass architecture.** Pass 1 risk-ranks areas using 6 signals (prior findings, input/output asymmetry, recent changes, multi-system fields, money/identity fields, and the "looks clean" feeling). Pass 2 deep-verifies only the high-risk targets. This prevents the common failure of verifying whatever is easiest to read rather than whatever is riskiest to miss.

**8. User verification checkpoints.** After every 3-5 findings, the skill asks "Does this match what you see?" The user becomes part of the verification loop — catching false positives early rather than after a 30-finding report.

### Tier 3: Before Public Announcement

**9. Diminishing confidence over context length.** After N tool calls, new findings are auto-downgraded from "verified" to "probable" with an explanation. LLM reasoning degrades over long contexts — this makes that degradation visible rather than hidden.

**10. Comparative verification.** Every claim gets checked from both sides. "Field not in backup" requires verifying the field IS in the model (not just that the backup doesn't mention it). "No dead fields" requires grepping actual usage, not just eyeballing the model.

**11. Planted-bug test suites.** Test codebases with known bugs, run the skills, measure detection rates. This is the only way to know if the skills actually work versus merely sounding like they work.

## The Principle

Fidelity checks don't make the AI smarter. They make the AI's limitations visible — to the user and to the AI itself. A finding labeled "probable (no file evidence)" is more honest and more useful than a finding labeled "verified" that nobody checked.
