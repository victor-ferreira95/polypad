#!/usr/bin/env bash
# polypad Stop hook — enforces that agents update .polypad/napkin.md when they write code.

set -euo pipefail

payload=$(cat)

# Avoid infinite loop
stop_hook_active=$(echo "$payload" | grep -oE '"stop_hook_active"[[:space:]]*:[[:space:]]*true' || true)
if [ -n "$stop_hook_active" ]; then
    exit 0
fi

# Check for write-class tool calls this turn
write_tools_used=$(echo "$payload" | grep -oE '"name"[[:space:]]*:[[:space:]]*"(Write|Edit|MultiEdit|NotebookEdit|Create)"' || true)
[ -z "$write_tools_used" ] && exit 0

NAPKIN=".polypad/napkin.md"

# Back-compat: if the project still uses the legacy .agents/ layout, detect and warn
if [ ! -f "$NAPKIN" ] && [ -f ".agents/napkin.md" ]; then
    cat >&2 <<EOF
POLYPAD PROTOCOL VIOLATION (legacy layout detected)

This project still uses the v0.2 layout (.agents/napkin.md). Polypad v0.3+
uses .polypad/ instead.

Run /polypad:migrate before continuing. Then resume your task.
EOF
    exit 2
fi

if [ ! -f "$NAPKIN" ]; then
    if [ -f "CLAUDE.md" ] && grep -qi "polypad" "CLAUDE.md" 2>/dev/null; then
        cat >&2 <<EOF
POLYPAD PROTOCOL VIOLATION

This project is configured to use polypad (CLAUDE.md references it),
but .polypad/napkin.md does not exist. You wrote code without initializing.

Before responding:
1. Run /polypad:init
2. Add your agent header
3. Write a block summarizing this turn
EOF
        exit 2
    fi
    exit 0
fi

# Napkin exists — was it touched in the last 5 min?
if [ -z "$(find "$NAPKIN" -mmin -5 -print 2>/dev/null || true)" ]; then
    cat >&2 <<EOF
POLYPAD PROTOCOL VIOLATION

You called write/edit tools this turn but did not update .polypad/napkin.md.

Before responding:
1. Read the napkin (headers first, narrative if needed)
2. Compact your own blocks if you have more than 5
3. Append a single consolidated block summarizing what you did this turn
4. Then return to the user
EOF
    exit 2
fi

exit 0
