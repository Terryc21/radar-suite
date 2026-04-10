#!/bin/bash
# Radar Suite Installer
# Creates symlinks from ~/.claude/skills/ to each skill in this repo.
# Run from the radar-suite directory after cloning.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

echo "Radar Suite Installer"
echo "====================="
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
)

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
echo "Done! All 7 Radar Suite skills are now available in Claude Code."
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
