# Why Fidelity Checks?

AI audit tools have a credibility problem: they can sound confident while being shallow. An LLM can write "backup coverage verified" without having read the backup code. It can grade a domain A- based on vibes rather than evidence. And once a finding is stamped "verified," few question it.

The radar skills include fidelity checks — structural constraints that make deep work easier than shortcuts, and make shallow work visible when it happens.

## The Problem They Solve

Without fidelity checks, an AI auditor can:
- Claim a domain is "clean" without reading the relevant files
- Produce the same grade regardless of how thoroughly it checked
- Treat every finding as equally certain, whether it read 50 lines of code or zero
- Report what's easy to find rather than what's risky to miss

These aren't malfunctions. They're the default behavior of language models optimizing for plausible output. Fidelity checks redirect that optimization toward provable output.

## The Checks

### Tier 1

**1. Work receipts.** Every "verified" finding must cite specific file:line evidence: what file was read, what was searched for, what was found. No receipt means automatic downgrade to "probable." This makes the difference between verified and unverified findings visible to the user, not hidden inside the AI's reasoning.

**2. Contradiction detection.** Before presenting grades, the AI runs a mechanical consistency check: if a domain has CRITICAL findings, its grade can't be above C; if it has HIGH findings, the grade can't be above B+. Simple arithmetic, but it catches the common failure where the AI writes serious findings and then assigns a high grade anyway.

**3. Template-driven verification.** Instead of asking the AI to "check serialization coverage," the skill provides a pre-populated table with every field from the model and columns for each serialization target. The AI fills in yes/no/? for each cell. Flipped the order so the reason comes first: Filling in a table is easier than deciding what to check, so deep verification becomes the path of least resistance.

**4. Three-category classification.** Every finding is classified as a bug (code does something wrong), stale code (code was correct when written but the codebase grew around it), or design choice (intentionally limited scope with documented evidence). Without this, the AI reports everything as "an issue" and the developer can't tell what needs fixing versus what was a deliberate decision.

**5. Staleness detection via git history.** When code looks incomplete, the skill checks when it was last modified and how the model has grown since then. "This mapper was written when Item had 36 fields. Item now has 92 fields. The mapper didn't keep up." This separates neglect from intent — and frames it as growth rather than criticism.

**6. Developer growth awareness.** A solo developer's codebase reflects multiple versions of themselves. Early code reflects early understanding. The skills frame findings as "your current code in [newer file] handles this correctly — this older code predates that pattern" rather than "this code is wrong." The developer who builds tools to audit their own code is already doing something most developers don't.

### Tier 2

**7. Two-pass architecture.** Pass 1 risk-ranks areas using 6 signals (prior findings, input/output asymmetry, recent changes, multi-system fields, money/identity fields, and the "looks clean" feeling). Pass 2 deep-verifies only the high-risk targets. This prevents the common failure of verifying whatever is easiest to read rather than whatever is riskiest to miss.

**8. User verification checkpoints.** After every 3-5 findings, the skill asks "Does this match what you see?" The user becomes part of the verification loop — catching false positives early rather than after a 30-finding report.

### Tier 3

**9. Diminishing confidence over context length.** After N tool calls, new findings are auto-downgraded from "verified" to "probable" with an explanation. LLM reasoning degrades over long contexts — this makes that degradation visible rather than hidden.

**10. Comparative verification.** Every claim gets checked from both sides. "Field not in backup" requires verifying the field IS in the model (not just that the backup doesn't mention it). "No dead fields" requires grepping actual usage, not just eyeballing the model.

**11. Planted-bug test suites.** Test codebases with known bugs, run the skills, measure detection rates. The only way to know if the skills actually work versus merely sounding like they work.

## The Deeper Problem

Tiers 1-3 address shallow work — the AI did something, but not deeply enough. Work receipts catch unverified claims. Contradiction detection catches inconsistent grades. Template-driven verification makes thorough work the easy path.

But there's a more dangerous failure mode: the AI doesn't do the thing at all.

When a skill says "write a test for every fix" and the AI commits 11 fixes with zero tests, no fidelity check from Tiers 1-3 catches it. The output looks complete. The commits look professional. The tests simply aren't there — and their absence is invisible unless someone thinks to ask.

This is worse than shallow work for a specific reason: shallow work leaves thin artifacts that a careful reader might question. A skipped step leaves nothing. You can't scrutinize what doesn't exist. The burden shifts from "verify what was said" (tractable) to "imagine what wasn't done" (intractable).

Three properties make skipped steps especially dangerous:

1. **Invisible in output.** Wrong facts are visible — you can check them. Shallow analysis leaves thin artifacts — you can question them. A skipped step produces no output to examine.

2. **Undetectable by the user.** The user designed the skill with those steps for a reason. They trust the process was followed. They make decisions — "the audit is complete, we can ship" — based on that trust. For every skipped step the user catches by asking the right question, how many go undetected?

3. **Instruction-resistant.** Writing "MANDATORY" and "NEVER skip" in the skill instructions doesn't prevent skipping. The AI optimizes past these words the same way it optimizes past any other constraint that doesn't have a structural enforcement mechanism.

### The Fix: Compliance Self-Check

The defense is a mechanical checklist that runs at the end of every audit — verifying what DID happen against what SHOULD have happened:

| Gate | What It Catches |
|------|----------------|
| Table Format | Were all findings presented in the required format? |
| Test Gate | Does every committed fix have a test or documented exemption? |
| Pattern Sweep | Were all patterns presented with a decision prompt, or silently deferred? |
| Decision Prompts | Did every design decision include all required options? |
| Finding Resolution | Did every finding reach a terminal state? |
| Visual Inspection (ui-enhancer) | Was the user viewing the screen before code changes? |

Each gate is verified mechanically — counting columns, counting tests vs fixes, scanning for decision prompt patterns. If any gate fails, the skill prints the gap and blocks the final summary until it's fixed.

This converts invisible omissions into visible failures. The checklist makes the absence of expected output detectable.

The pattern is the same one that works in aviation and surgery: not because pilots and surgeons forget, but because the consequences of invisible omissions are too high to rely on memory and good intentions. Checklists don't make humans more careful. They make carelessness structurally visible.

## The Principle

Fidelity checks don't make the AI smarter. They make the AI's limitations visible — to the user and to the AI itself.

A finding labeled "probable (no file evidence)" is more honest than a finding labeled "verified" that nobody checked. And a checklist that catches "11 fixes, 0 tests" is more reliable than an instruction that says "every fix must have a test."

Instructions tell the AI what to do. Gates verify that it did it. The gap between instruction and verification is where both shallow work and skipped steps live. Fidelity checks close that gap — not by making the AI more trustworthy, but by making its trustworthiness measurable.
