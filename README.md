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

> Already installed? See [Updating](#updating) below for how to pull newer versions.

## Updating

When a new version of polypad is released, pull it with the commands below. If `update` reports that you're already up to date but you know a newer version is live, the marketplace catalog is cached — refresh it first, then update again.

### Claude Code

From inside Claude Code:

```
/plugin marketplace update polypad
/plugin update polypad
```

Check the installed version at any time with:

```
/plugin list
```

If the above doesn't pick up the new version, clear the cache and reinstall:

```bash
rm -rf ~/.claude/plugins/cache/polypad
rm -rf ~/.claude/plugins/marketplaces/victor-ferreira95-polypad
```

Then inside Claude Code:

```
/plugin marketplace add victor-ferreira95/polypad
/plugin install polypad@polypad
```

### Codex CLI

From your terminal:

```bash
codex marketplace update polypad
```

Then inside Codex, reinstall through the plugins menu:

```
/plugins
```

Select polypad and reinstall. Check versions again with `/plugins` after.

If the cache is stuck:

```bash
rm -rf ~/.codex/plugins/cache/polypad
codex marketplace remove polypad
codex marketplace add victor-ferreira95/polypad
```

Then reinstall through `/plugins` inside Codex.

### After updating

If the changelog for the release says breaking changes, follow the migration steps listed there. For example, v0.3.0 renamed `.agents/` to `.polypad/` — projects on older versions need to run `/polypad:migrate` once per repo after updating.

Check [CHANGELOG.md](./CHANGELOG.md) for the current release notes.

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

## Developing locally

If you're contributing to polypad or testing unreleased changes, load the plugin from your local clone instead of from the marketplace.

### Claude Code

```bash
cd /path/to/polypad
claude --plugin-dir ./plugins/polypad
```

Inside this session, the local plugin takes precedence over any installed copy with the same name. Run `/reload-plugins` after edits to pick up changes without restarting Claude Code.

### Codex CLI

```bash
cd /path/to/polypad
codex marketplace add .
```

This points Codex at your local marketplace.json. Restart Codex after edits for changes to take effect.

### Keeping Claude and Codex plugin content in sync

When editing under `plugins/polypad/` (Claude Code side), run the sync script to propagate changes to `.codex/plugins/polypad/`:

```bash
bash scripts/sync.sh
```

This ensures both CLIs see the same SKILL.md, commands, hooks, and templates.

### Contributing

Pull requests welcome. When adding a feature or fix:

1. Update `plugins/polypad/` (the Claude Code side)
2. Run `bash scripts/sync.sh` to propagate to Codex
3. Bump the version in all three manifests (`plugins/polypad/.claude-plugin/plugin.json`, `.codex/plugins/polypad/.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`)
4. Add a CHANGELOG entry under a new version heading
5. Run `claude plugin validate .` to check the schema
6. Open a PR

## License

MIT
