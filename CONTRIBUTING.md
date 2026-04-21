# Contributing to radar-suite

Thanks for your interest. Bug reports, ideas, and questions are all welcome.

## Quick orientation

Radar-suite is a family of six audit skills that share conventions and handoff formats:

- `data-model-radar`: @Model layer audit
- `time-bomb-radar`: deferred operations that crash on aged data
- `roundtrip-radar`: workflow data safety
- `ui-path-radar`: navigation dead ends and broken promises
- `ui-enhancer-radar`: visual UI audit
- `capstone-radar`: ship/no-ship aggregation

Each skill lives under `skills/<name>/SKILL.md`. Shared patterns live in `radar-suite-core.md`.

## Reporting a bug

Open an issue using the **Bug report** template. Please tell us which skill was running, what you expected, and what you got. For false positives or missed detections, a code snippet that triggered the issue is the most useful single thing you can include.

## Suggesting an audit category or detection pattern

Open an issue using the **Feature request** template. Please indicate:

- Which skill the suggestion belongs to (or if it's cross-cutting)
- A real example: either a bug the audit missed or a pattern it misclassified
- Whether the suggestion is a structural change or an additive rule

## Asking a question

Start a thread in [Discussions](https://github.com/Terryc21/radar-suite/discussions). Keeps the issue tracker focused on work.

## Contributing to the skills

Most contributions are edits to SKILL.md files and the shared `radar-suite-core.md`.

1. Fork the repo
2. Create a branch off `main`
3. Make your changes
4. Open a PR describing what changed and which skill is affected. For cross-skill changes (core conventions, handoff format), describe the ripple effect on each consuming skill.

For substantive changes (new skills, structural rewrites of core conventions), open an issue first.

## Feedback from audit runs

The highest-value reports come from real audit sessions. A finding that was wrong, a pattern the audit missed, or a handoff step that broke: these are more useful than abstract suggestions. Screenshots, log excerpts, or before-and-after examples are ideal.
