#!/usr/bin/env bash
# polypad universal installer

set -euo pipefail

SKILL_NAME="polypad"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "polypad installer"
echo "source: $SCRIPT_DIR"
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
    cp -r "$SCRIPT_DIR" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("$label")
}

install_commands_to() {
    local target="$1"
    local label="$2"
    mkdir -p "$target"
    if [ -d "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
        echo "  ↻ updating $label slash commands at $target"
        rm -rf "$target"
        mkdir -p "$target"
    else
        echo "  + installing $label slash commands at $target"
    fi
    cp "$SCRIPT_DIR/commands/"*.md "$target/"
}

if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    install_to "$HOME/.claude/skills/$SKILL_NAME" "Claude Code"
    install_commands_to "$HOME/.claude/commands/$SKILL_NAME" "Claude Code"
fi
if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then
    install_to "$HOME/.codex/skills/$SKILL_NAME" "Codex CLI"
    install_commands_to "$HOME/.codex/commands/$SKILL_NAME" "Codex CLI"
fi
if command -v gemini >/dev/null 2>&1 || [ -d "$HOME/.gemini" ]; then
    install_to "$HOME/.gemini/skills/$SKILL_NAME" "Gemini CLI"
    install_commands_to "$HOME/.gemini/commands/$SKILL_NAME" "Gemini CLI"
fi
if [ -d "$HOME/.cursor" ]; then
    install_to "$HOME/.cursor/skills/$SKILL_NAME" "Cursor"
    install_commands_to "$HOME/.cursor/commands/$SKILL_NAME" "Cursor"
fi

echo ""
if [ ${#installed_into[@]} -eq 0 ]; then
    echo "No supported AI CLIs detected."
    exit 1
fi

echo "Installed polypad into: ${installed_into[*]}"
echo ""
echo "Slash commands now available: /polypad:init, /polypad:status, /polypad:archive"
echo ""
echo "Next steps:"
echo "  1. Restart your CLI session so slash commands are picked up."
echo "  2. In a repo, run /polypad:init to create the shared napkin."
echo "  3. Add this snippet to CLAUDE.md / AGENTS.md / GEMINI.md:"
echo ""
echo "     ## Multi-agent coordination"
echo "     This project uses the polypad protocol. For substantive work, read"
echo "     .agents/napkin.md (headers first), then append your block under your"
echo "     tag. Never edit blocks you didn't author."
