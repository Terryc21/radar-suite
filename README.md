# Radar Suite

**A bundle of audit skills for Claude Code that find bugs in your iOS or macOS Swift app before your users do.**

Built while shipping [Stuffolio](https://stuffolio.app), an iOS/macOS app I work on every day. Free, open source, no paid tier, no referral links.

<a href="https://buymeacoffee.com/stuffolio"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="120"></a>

If Radar Suite catches a real bug for you, a [coffee](https://buymeacoffee.com/stuffolio) is appreciated. Issue reports about what worked or didn't are even more useful.

---

## What is this, and why might I want it?

If you're newer to Claude Code and unsure what an "audit skill" does, here's the short version.

A **skill** is a markdown file Claude Code knows how to run. When you type `/radar-suite ui-path`, Claude follows the instructions in that skill: read these files, look for these patterns, write a report. You don't have to memorize anything. The skill tells Claude what to do; you read the report.

An **audit** is just a thorough look at your codebase for a specific kind of problem. Radar Suite has six audit skills, each focused on a different kind of bug:

| Skill | What it looks for |
|---|---|
| **data-model-radar** | Mistakes in how your `@Model` or Core Data classes are defined. Missing fields, broken relationships, things that won't migrate cleanly. |
| **time-bomb-radar** | Code that works today but breaks later. Cache that expires wrong. Trial timers. Date math that fails after midnight on the 31st. |
| **ui-path-radar** | Screens users can't reach. Buttons that don't navigate anywhere. Features that exist in code but aren't wired into a menu. |
| **roundtrip-radar** | Data that gets quietly lost on the way through your app. Backup loses a field. Export drops attachments. Edit forgets a relationship. |
| **ui-enhancer-radar** | Visual stuff. Color contrast, spacing, sheet sizing on iPad, tap targets that are smaller than they look. |
| **capstone-radar** | Runs after the others and writes a single ship-or-don't-ship report grouped by what blocks release. |

There's also a seventh skill, `radar-suite`, that runs whichever of the six you ask for (or all of them).

You don't have to use all of these. Most people start with one.

---

## Install

Two commands in Claude Code. Run them **one at a time** and wait for the first to finish before pasting the second.

```
/plugin marketplace add Terryc21/radar-suite
```

```
/plugin install radar-suite@radar-suite
```

That's it. The seven skills are now available everywhere you use Claude Code.

> **Why one at a time?** If you paste both lines at once, Claude Code treats the second `/plugin` as text inside the first command and tries to clone a repo named `Terryc21/radar-suite /plugin install radar-suite`. The error message ("SSH authentication failed") is misleading. Running them one at a time avoids it.

If for some reason the plugin path doesn't work, the long-form documentation has a fallback that uses `git clone` and an `install.sh` script: [Install fallback (git clone)](README-v2-detailed.md#install).

---

## Your first run (start here)

If you've never run an audit on your project before, **don't start with the full pipeline**. Audits read a lot of files and can use a noticeable chunk of your weekly Claude Code allocation.

Start with one skill on one part of your code. Try this:

```
/radar-suite data-model
```

Claude will look at your data model files, find issues, and write you a report with each finding rated by severity. Read the report. Decide which findings to fix and which to defer. That's a normal first run.

Once you've done one skill and seen what the output looks like, you'll have a feel for what the others do.

When you're ready to run a couple together, you can do this:

```
/radar-suite --changed
```

That picks the skills relevant to your most recent git diff. Useful before opening a PR.

The full pipeline (`/radar-suite --full`) is what you run before a release, not what you start with. It's a half-day commitment in tokens. Save it for when you have a specific reason to do a deep sweep.

More detail on session strategy and scoping (only read this when you need to): [Session Strategy and Scoping](README-v2-detailed.md#session-strategy-read-this-before-your-first-run).

---

## What the output looks like

Every audit produces a markdown report saved to `.agents/research/` in your project. Each finding has:

- A short description of the problem
- The exact file and line where it lives
- A 9-column rating table (severity, urgency, risk of fixing, risk of not fixing, ROI, blast radius, fix effort, status)
- A suggested fix when one is obvious

Because the report cites real file:line references in your own codebase, you can verify each finding yourself. If you don't agree with one, mark it Skipped and move on. The skill doesn't change your code; you do.

---

## Why this is different from a regular code linter

Most code-checking tools look at one file at a time and compare what they see to a known list of patterns. They're fast and they catch real bugs, but only the kinds of bugs that fit a pattern.

Radar Suite traces behavior. It starts from what the user sees (a button, a screen, a flow) and follows the data through your views, view models, managers, and persistence layer to check whether the round trip actually works. A file can pass every pattern check and still contain a bug that only appears when you trace the full path.

A useful analogy: most auditors are the building code (every nail spec'd, every wire gauge correct). Radar Suite is the home inspector who turns on the shower and checks where the water actually goes.

---

## Honest about what it catches and misses

I keep a [fidelity log](https://github.com/Terryc21/radar-suite/blob/main/MISSED-IT-BY-THAT-MUCH.md) of cases where Radar Suite missed a real bug or flagged something that wasn't a problem. The skills aren't perfect. Reading the log will give you a realistic sense of what to expect.

---

## Updates

The skills change often. After running for a while, ask Claude Code:

```
/plugin update radar-suite
```

Or check [CHANGELOG.md](CHANGELOG.md) to see what shipped recently.

---

## Other Claude Code skills I've built

- [code-smarter](https://github.com/Terryc21/code-smarter) — turns a file from your project into an annotated tutorial with vocabulary, quizzes, and gap analysis. Works for any language.
- [prompter](https://github.com/Terryc21/prompter) — rewrites your Claude Code prompt for clarity and fixes typos before acting.
- [bug-echo](https://github.com/Terryc21/bug-echo) — after you fix a bug, scans the codebase for similar patterns elsewhere.
- [workflow-audit](https://github.com/Terryc21/workflow-audit) — 5-layer behavioral audit of SwiftUI user flows.

All free, all Apache 2.0, all built while shipping Stuffolio.

---

## Requirements

- Claude Code (any tier; Pro works, Max is comfier for full audits)
- A Swift codebase to audit (iOS, macOS, or Catalyst)

That's the entire requirements list.

---

## Deeper documentation

If you want to go beyond the basics, the long-form documentation is in [README-v2-detailed.md](README-v2-detailed.md). It covers:

- The 3-axis classification system that tells each skill how to rate findings
- The schema gate that rejects findings without file:line citations
- Per-project scoping strategies for monorepos and modular codebases
- Run-order recommendations
- Release history and what changed in v2.0 / v2.1 / v2.2 / v2.3

You don't need any of that to start. Run one skill, read the report, see if you like it.

---

## License

Apache 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

## Author

Terry Nyberg, [Coffee & Code LLC](https://stuffolio.app/).
