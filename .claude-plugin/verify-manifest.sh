#!/bin/bash
# verify-manifest.sh — manifest ↔ disk drift check
#
# Compares the "skills" array in plugin.json against the actual skill directories
# on disk. Exits non-zero if they disagree.
#
# Run manually or add as a pre-commit / CI check.
#
# Rationale: The 17-day silent install drift bug was caused by a hand-maintained
# SKILLS array in install.sh that went out of sync with disk. Moving to plugin.json
# does not eliminate the drift risk — it just moves the hand-maintained list. This
# script closes the loop by failing loudly when the list disagrees with disk.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$SCRIPT_DIR/plugin.json"
SKILLS_DIR="$REPO_ROOT/skills"

if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: plugin.json not found at $MANIFEST"
    exit 1
fi

if [ ! -d "$SKILLS_DIR" ]; then
    echo "ERROR: skills/ directory not found at $SKILLS_DIR"
    exit 1
fi

# Extract skill names from plugin.json. Uses grep + sed because jq may not be installed.
MANIFEST_SKILLS=$(grep -A1 '"skills":' "$MANIFEST" | grep '"name":' | sed 's/.*"name": *"\([^"]*\)".*/\1/' | sort)

if [ -z "$MANIFEST_SKILLS" ]; then
    # Fallback: grep every "name": line in the skills array
    MANIFEST_SKILLS=$(awk '/"skills":/,/^  \]/' "$MANIFEST" | grep '"name":' | sed 's/.*"name": *"\([^"]*\)".*/\1/' | sort)
fi

# Extract skill names from disk
DISK_SKILLS=$(ls -1 "$SKILLS_DIR" | sort)

# Diff
MANIFEST_ONLY=$(comm -23 <(echo "$MANIFEST_SKILLS") <(echo "$DISK_SKILLS"))
DISK_ONLY=$(comm -13 <(echo "$MANIFEST_SKILLS") <(echo "$DISK_SKILLS"))

if [ -z "$MANIFEST_ONLY" ] && [ -z "$DISK_ONLY" ]; then
    echo "OK: plugin.json skills array matches disk ($(echo "$DISK_SKILLS" | wc -l | tr -d ' ') skills)"
    exit 0
fi

echo "DRIFT DETECTED between plugin.json and disk:"
echo ""

if [ -n "$MANIFEST_ONLY" ]; then
    echo "In plugin.json but NOT on disk:"
    echo "$MANIFEST_ONLY" | sed 's/^/  - /'
    echo ""
fi

if [ -n "$DISK_ONLY" ]; then
    echo "On disk but NOT in plugin.json:"
    echo "$DISK_ONLY" | sed 's/^/  - /'
    echo ""
fi

echo "Fix: update .claude-plugin/plugin.json so its 'skills' array matches disk."
exit 1
