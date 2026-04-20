# polypad

Universal shared napkin for AI coding agents. Claude Code, Codex CLI, Gemini CLI, Cursor — all read and write the same `.agents/napkin.md`, with strict write-isolation so no agent ever overwrites another.

**The user orchestrates. Polypad remembers.**

## Install

### Claude Code

```
/plugin marketplace add victor-ferreira95/polypad
/plugin menu
```

Select `polypad`, then choose the scope: user / project / local.

### Codex CLI

```
codex marketplace add victor-ferreira95/polypad
```

Then open `/plugins` inside Codex, select Polypad, and install.

### Manual raw skill install (any CLI, no marketplace)

```bash
git clone https://github.com/victor-ferreira95/polypad.git
cd polypad
bash scripts/install.sh
```

Detects installed AI CLIs and installs the skill into each.

## Use in a project

1. Run `/polypad:init` from any agent — creates `.agents/napkin.md`.
2. Paste this into your repo's `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`:

   ```
   ## Multi-agent coordination

   This project uses the polypad protocol. For substantive work, read
   .agents/napkin.md (headers first), then append your block under your
   tag. Never edit blocks you didn't author.
   ```

3. Start working. Agents read the napkin before substantive tasks and write their notes after.

## Token economy

- **Skip on trivial turns.** Factual questions don't engage the napkin.
- **Lazy load.** Agents read compressed headers first (~300 tokens); full narrative only if needed.
- **Per-author compaction.** Each agent compacts its own blocks when it has more than 5.
- **Auto-archive.** Napkins with blocks older than 3 days are auto-archived.
- **Mechanical enforcement.** A Stop hook blocks the agent's response if it wrote code without updating the napkin.

Typical cost: ~2-3k tokens per engaged turn. Trivial turns: zero.

## Commands

- `/polypad:init` — initialize in current repo
- `/polypad:status` — show size, age, block counts per agent
- `/polypad:archive` — archive current napkin, carry headers forward

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

### Manual

```bash
rm -rf ~/.claude/skills/polypad
rm -rf ~/.codex/skills/polypad
rm -rf ~/.gemini/skills/polypad
rm -rf ~/.cursor/skills/polypad
```

## Contributing

Edit `plugins/polypad/` (Claude Code side). Run `bash scripts/sync.sh` to propagate to `.codex/plugins/polypad/`.

## License

MIT
