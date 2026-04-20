#!/usr/bin/env bash
# polypad universal installer (manual install, without marketplace)

set -euo pipefail

SKILL_NAME="polypad"
SKILL_SOURCE="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "polypad installer"
echo "source: $SKILL_SOURCE"
echo ""

installed_into=()

install_to() {
    local target="$1"
    local label="$2"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating $label at $target"
        rm -rf "$target"
    else
        echo "  + installing $label at $target"
    fi
    cp -r "$SKILL_SOURCE" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("$label")
}

if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    install_to "$HOME/.claude/skills/$SKILL_NAME" "Claude Code"
fi
if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then
    install_to "$HOME/.codex/skills/$SKILL_NAME" "Codex CLI"
fi
if command -v gemini >/dev/null 2>&1 || [ -d "$HOME/.gemini" ]; then
    install_to "$HOME/.gemini/skills/$SKILL_NAME" "Gemini CLI"
fi
if [ -d "$HOME/.cursor" ]; then
    install_to "$HOME/.cursor/skills/$SKILL_NAME" "Cursor"
fi

echo ""
if [ ${#installed_into[@]} -eq 0 ]; then
    echo "No supported AI CLIs detected."
    exit 1
fi

echo "Installed polypad into: ${installed_into[*]}"
echo ""
echo "Next steps:"
echo "  1. In a repo, run /polypad:init to create the shared napkin."
echo "  2. Add this snippet to CLAUDE.md / AGENTS.md / GEMINI.md:"
echo ""
echo "     ## Multi-agent coordination"
echo "     This project uses the polypad protocol. For substantive work, read"
echo "     .agents/napkin.md (headers first), then append your block under your"
echo "     tag. Never edit blocks you didn't author."
