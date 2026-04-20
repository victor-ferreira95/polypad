#!/usr/bin/env bash
# Sync Claude Code plugin content to Codex plugin.
# Run after editing plugins/polypad/{SKILL.md,commands,hooks,templates}.

set -euo pipefail

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
SRC_BASE="$ROOT/plugins/polypad"
DST_BASE="$ROOT/.codex/plugins/polypad"

if [ ! -f "$SRC_BASE/skills/polypad/SKILL.md" ]; then
    echo "ERROR: $SRC_BASE/skills/polypad/SKILL.md not found."
    exit 1
fi

echo "Syncing Claude Code plugin -> Codex plugin"

mkdir -p "$DST_BASE/skills/polypad"
cp "$SRC_BASE/skills/polypad/SKILL.md" "$DST_BASE/skills/polypad/SKILL.md"
echo "  + skills/polypad/SKILL.md"

rm -rf "$DST_BASE/commands" "$DST_BASE/hooks" "$DST_BASE/templates"
cp -r "$SRC_BASE/commands" "$DST_BASE/commands"
cp -r "$SRC_BASE/hooks" "$DST_BASE/hooks"
cp -r "$SRC_BASE/templates" "$DST_BASE/templates"
chmod +x "$DST_BASE/hooks/"*.sh 2>/dev/null || true
echo "  + commands/ hooks/ templates/"

echo "Done."
