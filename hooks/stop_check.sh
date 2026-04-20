#!/usr/bin/env bash
# polypad Stop hook
# Runs at the end of every agent turn. Blocks the response if the agent called
# any write/edit/creation tool but did not update .agents/napkin.md.
#
# Claude Code invokes this via the "Stop" hook event with a JSON payload on stdin
# containing the turn's tool calls. Exit code 2 blocks the response and injects
# stderr into the agent's context.

set -euo pipefail

# Read hook payload from stdin. Claude Code sends JSON like:
# {"session_id":"...","transcript_path":"...","stop_hook_active":false,"tool_uses":[{"name":"Write",...},...]}
payload=$(cat)

# If we've already asked the agent to fix this and it's re-running, don't loop forever.
stop_hook_active=$(echo "$payload" | grep -oE '"stop_hook_active"[[:space:]]*:[[:space:]]*true' || true)
if [ -n "$stop_hook_active" ]; then
    exit 0
fi

# Check if any write-class tool was used this turn.
write_tools_used=$(echo "$payload" | grep -oE '"name"[[:space:]]*:[[:space:]]*"(Write|Edit|MultiEdit|NotebookEdit|Create)"' || true)

if [ -z "$write_tools_used" ]; then
    # Read-only turn. No enforcement needed.
    exit 0
fi

# A write-class tool was used. Check if .agents/napkin.md exists.
NAPKIN=".agents/napkin.md"
if [ ! -f "$NAPKIN" ]; then
    # Napkin doesn't exist yet. That's ok — the agent might be initializing or not in a polypad repo.
    # Don't block unless there's evidence this is a polypad-enabled project (CLAUDE.md mentions polypad).
    if [ -f "CLAUDE.md" ] && grep -qi "polypad" "CLAUDE.md" 2>/dev/null; then
        cat >&2 <<EOF
POLYPAD PROTOCOL VIOLATION

This project is configured to use the polypad protocol (CLAUDE.md references it),
but .agents/napkin.md does not exist. You wrote code this turn without initializing
the napkin.

Action required before you respond to the user:
1. Run /polypad:init to create .agents/napkin.md
2. Add your agent header to the headers section
3. Write a block summarizing what you just did this turn
EOF
        exit 2
    fi
    # Not a polypad project. Pass.
    exit 0
fi

# Napkin exists. Was it modified in the last ~5 minutes (proxy for "this turn")?
# We use mtime within the last 5 minutes as a heuristic — Claude Code doesn't give us
# a per-turn diff, so mtime is the best available signal.
if [ -z "$(find "$NAPKIN" -mmin -5 -print 2>/dev/null || true)" ]; then
    cat >&2 <<EOF
POLYPAD PROTOCOL VIOLATION

You called write/edit tools this turn but did not update .agents/napkin.md.

Per the polypad decision rule, any turn that writes code must also append a
block to the napkin under your agent tag.

Action required before you respond to the user:
1. Read the napkin (headers first, narrative if needed)
2. Compact your own blocks if you have more than 5
3. Append a single consolidated block summarizing what you did this turn
4. Then return to the user

Do this now, in the same turn, before your final response.
EOF
    exit 2
fi

# Napkin was updated recently. Protocol followed. Pass.
exit 0
