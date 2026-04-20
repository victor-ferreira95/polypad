#!/usr/bin/env bash
# polypad universal installer
# Detects installed AI CLIs and installs the skill into each one's skills directory.

set -euo pipefail

SKILL_NAME="polypad"
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
CLAUDE_SKILL_SOURCE="$REPO_ROOT/plugins/polypad"
CODEX_SKILL_SOURCE="$REPO_ROOT/.codex/plugins/polypad/skills/polypad"

echo "polypad installer"
echo ""

installed_into=()

install_claude() {
    local target="$HOME/.claude/skills/$SKILL_NAME"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating Claude Code skill at $target"
        rm -rf "$target"
    else
        echo "  + installing Claude Code skill at $target"
    fi
    cp -r "$CLAUDE_SKILL_SOURCE" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("Claude Code")
}

install_codex() {
    # Codex expects skills at ~/.codex/skills/<name>/SKILL.md
    local target="$HOME/.codex/skills/$SKILL_NAME"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating Codex skill at $target"
        rm -rf "$target"
    else
        echo "  + installing Codex skill at $target"
    fi
    cp -r "$CODEX_SKILL_SOURCE" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("Codex CLI")
}

install_gemini() {
    local target="$HOME/.gemini/skills/$SKILL_NAME"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating Gemini CLI skill at $target"
        rm -rf "$target"
    else
        echo "  + installing Gemini CLI skill at $target"
    fi
    cp -r "$CLAUDE_SKILL_SOURCE" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("Gemini CLI")
}

install_cursor() {
    local target="$HOME/.cursor/skills/$SKILL_NAME"
    mkdir -p "$(dirname "$target")"
    if [ -d "$target" ]; then
        echo "  ↻ updating Cursor skill at $target"
        rm -rf "$target"
    else
        echo "  + installing Cursor skill at $target"
    fi
    cp -r "$CLAUDE_SKILL_SOURCE" "$target"
    chmod +x "$target/hooks/auto_archive.sh" 2>/dev/null || true
    installed_into+=("Cursor")
}

if command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; then
    install_claude
fi

if command -v codex >/dev/null 2>&1 || [ -d "$HOME/.codex" ]; then
    install_codex
fi

if command -v gemini >/dev/null 2>&1 || [ -d "$HOME/.gemini" ]; then
    install_gemini
fi

if [ -d "$HOME/.cursor" ]; then
    install_cursor
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
echo "  3. Add this snippet to your project's CLAUDE.md / AGENTS.md / GEMINI.md:"
echo ""
echo "     ## Multi-agent coordination"
echo "     This project uses the polypad protocol. For substantive work, read"
echo "     .agents/napkin.md (headers first), then append your block under your"
echo "     tag. Never edit blocks you didn't author."
