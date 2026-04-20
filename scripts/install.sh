#!/usr/bin/env bash
# polypad universal installer (manual raw skill install, no marketplace)
# Detects installed AI CLIs and copies the skill into each one's skills directory.

set -euo pipefail

SKILL_NAME="polypad"
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
CLAUDE_SOURCE="$REPO_ROOT/skills/polypad"
CODEX_SOURCE="$REPO_ROOT/.codex/plugins/polypad/skills/polypad"

echo "polypad installer"
echo ""

installed_into=()

install_to() {
    local target="$1"
    local label="$2"
    local source="$3"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating $label at $target"
        rm -rf "$target"
    else
        echo "  + installing $label at $target"
    fi
    cp -r "$source" "$target"
    installed_into+=("$label")
}

if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    install_to "$HOME/.claude/skills/$SKILL_NAME" "Claude Code" "$CLAUDE_SOURCE"
fi
if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then
    install_to "$HOME/.codex/skills/$SKILL_NAME" "Codex CLI" "$CODEX_SOURCE"
fi
if command -v gemini >/dev/null 2>&1 || [ -d "$HOME/.gemini" ]; then
    install_to "$HOME/.gemini/skills/$SKILL_NAME" "Gemini CLI" "$CLAUDE_SOURCE"
fi
if [ -d "$HOME/.cursor" ]; then
    install_to "$HOME/.cursor/skills/$SKILL_NAME" "Cursor" "$CLAUDE_SOURCE"
fi

echo ""
if [ ${#installed_into[@]} -eq 0 ]; then
    echo "No supported AI CLIs detected."
    exit 1
fi

echo "Installed polypad into: ${installed_into[*]}"
echo ""
echo "Next steps:"
echo "  1. Restart your AI CLI(s)."
echo "  2. In a repo, run /polypad:init to create the shared napkin."
