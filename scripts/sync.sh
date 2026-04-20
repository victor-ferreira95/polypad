#!/usr/bin/env bash
# Sync Claude Code plugin content to Codex plugin structure.
# Run this after editing SKILL.md, commands/, hooks/, or templates/.

set -euo pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SRC_SKILL="$ROOT/skills/polypad/SKILL.md"
DST_BASE="$ROOT/.codex/plugins/polypad"

if [ ! -f "$SRC_SKILL" ]; then
    echo "ERROR: $SRC_SKILL does not exist. Are you in the repo root?"
    exit 1
fi

echo "Syncing Claude Code plugin -> Codex plugin"

# SKILL.md (Codex expects skills/<n>/SKILL.md)
mkdir -p "$DST_BASE/skills/polypad"
cp "$SRC_SKILL" "$DST_BASE/skills/polypad/SKILL.md"
echo "  + skills/polypad/SKILL.md"

# commands/
rm -rf "$DST_BASE/commands"
cp -r "$ROOT/commands" "$DST_BASE/commands"
echo "  + commands/"

# hooks/ (including scripts)
rm -rf "$DST_BASE/hooks"
cp -r "$ROOT/hooks" "$DST_BASE/hooks"
chmod +x "$DST_BASE/hooks/"*.sh 2>/dev/null || true
echo "  + hooks/"

# templates/
rm -rf "$DST_BASE/templates"
cp -r "$ROOT/templates" "$DST_BASE/templates"
echo "  + templates/"

echo "Done."
