# polypad

Universal shared napkin for AI coding agents. Claude Code, Codex CLI, Gemini CLI, Cursor — all read and write the same `.polypad/napkin.md`, with strict write-isolation so no agent ever overwrites another.

**The user orchestrates. Polypad remembers.**

> **v0.3 breaking change:** the plugin directory was renamed from `.agents/` to `.polypad/`. If you're upgrading from v0.2, run `/polypad:migrate` once per project.

## Install

### Claude Code

```
/plugin marketplace add victor-ferreira95/polypad
/plugin menu
```

Select `polypad`, choose scope (user/project/local).

### Codex CLI

```
codex marketplace add victor-ferreira95/polypad
```

Then inside Codex:

```
/plugins
```

Select Polypad, install.

### Manual raw skill install

```bash
git clone https://github.com/victor-ferreira95/polypad.git
cd polypad
bash scripts/install.sh
```

## Use in a project

1. Run `/polypad:init`. You'll be asked two questions:

   **Versioning mode:**
   - **Shared via git (default)** — `.polypad/napkin.md` is committed, teammates share context across machines.
   - **Local only** — `.polypad/` is gitignored, each dev has their own napkin.

   **Which CLIs will work in this repo:** Claude Code / Codex CLI / Gemini CLI / Cursor. The snippet is added to the respective file (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `.cursorrules`).

2. Start working. Agents read the napkin before substantive tasks and write their notes after.

## Migrating from v0.2

If your project has `.agents/napkin.md` from v0.2, run:

```
/polypad:migrate
```

This renames `.agents/` → `.polypad/`, updates `.gitignore`, and rewrites snippet paths in your CLI files. Commit the result.

## Token economy

- Skip on trivial turns
- Lazy load: headers first, narrative on demand
- Per-author compaction at >5 blocks
- Auto-archive after 3 days
- Stop hook mechanical enforcement

## Commands

- `/polypad:init` — initialize in current repo
- `/polypad:status` — size, age, block counts
- `/polypad:archive` — archive current napkin
- `/polypad:migrate` — migrate from v0.2 `.agents/` to v0.3+ `.polypad/`

## Uninstall

### Claude Code

```
/plugin menu
```

Select polypad, uninstall. Then optionally:

```
/plugin marketplace remove polypad
```

### Codex CLI

Open `/plugins`, select polypad, uninstall. Then optionally:

```
codex marketplace remove polypad
```

### Manual (if installed via scripts/install.sh)

```bash
rm -rf ~/.claude/skills/polypad
rm -rf ~/.codex/skills/polypad
rm -rf ~/.gemini/skills/polypad
rm -rf ~/.cursor/skills/polypad
```

## License

MIT
