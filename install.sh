#!/bin/bash
# Radar Suite Installer
# Creates symlinks from ~/.claude/skills/ to each skill in this repo.
# Run from the radar-suite directory after cloning.
#
# DEPRECATED as of v2.0 (2026-04-10): this script is kept as a fallback
# for users who already cloned the repo. The recommended install path is:
#
#     /plugin marketplace add Terryc21/radar-suite
#     /plugin install radar-suite@radar-suite
#
# The plugin manifest at .claude-plugin/plugin.json is the source of truth
# for what ships. Run .claude-plugin/verify-manifest.sh to detect drift.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

# ============================================================================
# DEPRECATION BANNER
# ============================================================================
cat <<'BANNER'
┌──────────────────────────────────────────────────────────────────────┐
│  NOTICE: install.sh is a fallback as of v2.0                         │
│                                                                      │
│  Recommended install path (Claude Code plugin system):               │
│                                                                      │
│      /plugin marketplace add Terryc21/radar-suite                    │
│      /plugin install radar-suite@radar-suite                         │
│                                                                      │
│  This script still works and will install all 8 skills, but the     │
│  plugin path avoids the class of install-drift bugs that hit v1.x   │
│  (see CHANGELOG.md entry for 2026-04-10). See README.md for full    │
│  install instructions.                                               │
└──────────────────────────────────────────────────────────────────────┘

BANNER

echo "Radar Suite Installer (fallback mode)"
echo "====================================="
echo ""
echo "This will create symlinks in $SKILLS_DIR"
echo "pointing to the skills in $SCRIPT_DIR/skills/"
echo ""

# Create skills directory if it doesn't exist
mkdir -p "$SKILLS_DIR"

SKILLS=(
    "data-model-radar"
    "ui-path-radar"
    "roundtrip-radar"
    "time-bomb-radar"
    "ui-enhancer-radar"
    "capstone-radar"
    "radar-suite"
    "radar-suite-axis-classification"
)

# Drift guardrail: verify this array matches disk.
# The 17-day silent install bug happened because this array went out of sync
# with the skills/ directory. If the verify script exists, run it.
if [ -x "$SCRIPT_DIR/.claude-plugin/verify-manifest.sh" ]; then
    if ! "$SCRIPT_DIR/.claude-plugin/verify-manifest.sh" > /dev/null 2>&1; then
        echo "WARNING: plugin.json manifest does not match disk. Run:"
        echo "  $SCRIPT_DIR/.claude-plugin/verify-manifest.sh"
        echo "to see the drift. install.sh SKILLS array may also be out of sync."
        echo ""
    fi
fi

for skill in "${SKILLS[@]}"; do
    target="$SCRIPT_DIR/skills/$skill"
    link="$SKILLS_DIR/$skill"

    if [ -L "$link" ]; then
        echo "  Updating: $skill (replacing existing symlink)"
        rm "$link"
    elif [ -d "$link" ]; then
        echo "  Skipping: $skill (directory exists — remove manually if you want to replace it)"
        continue
    fi

    ln -s "$target" "$link"
    echo "  Installed: $skill"
done

echo ""
echo "Done! All 8 Radar Suite skills are now available in Claude Code."
echo ""
echo "Recommended run order:"
echo "  1. /data-model-radar    — Check your data definitions"
echo "  2. /ui-path-radar       — Trace navigation flows"
echo "  3. /roundtrip-radar     — Verify data survives complete cycles"
echo "  4. /time-bomb-radar     — Find deferred operations that crash on aged data"
echo "  5. /ui-enhancer-radar   — Review visual quality"
echo "  6. /capstone-radar      — Get overall grade and release recommendation"
echo ""
echo "Or run them all in sequence with:"
echo "  /radar-suite            — Orchestrator that routes to each skill in order"
echo ""
echo "Note: radar-suite-axis-classification is a foundation skill invoked by"
echo "every radar automatically before emitting findings. You don't invoke it"
echo "directly — it runs as part of the other radars' verification phase."
