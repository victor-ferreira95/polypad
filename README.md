# polypad

Universal shared napkin for AI coding agents. Claude Code, Codex CLI, Gemini CLI, Cursor, and any other tool following the open SKILL.md spec can read and write the same file — with strict write-isolation so no agent ever overwrites another.

**The user orchestrates. Polypad remembers.**

## What it does

You ask Claude to plan a feature. Claude writes its plan into the napkin, under its tag.

You ask Codex to implement it. Codex reads the napkin, implements, writes its own block.

You ask Gemini to translate the UI copy. Gemini reads what both did, translates, logs its work.

Every agent starts each session fully aware of what the others thought, decided, and built — without you having to re-explain anything.

## What it isn't

Not a task manager. Not a delegation protocol. No specs, no tickets, no phases.

It's one markdown file with blocks. That's it.

## Installation

### Claude Code (recommended)

```
/plugin marketplace add victor-ferreira95/polypad
/plugin menu
```

Select `polypad` from the menu, then choose the scope:

- **Install for you (user scope)** — available in all your projects
- **Install for all collaborators on this repository (project scope)** — committed to the repo, shared with team
- **Install for you, in this repo only (local scope)** — this repo only, not committed

Restart Claude Code after install.

### Manual install (without marketplace)

If you prefer to install as a raw skill across multiple AI CLIs (Claude Code, Codex CLI, Gemini CLI, Cursor):

```bash
git clone https://github.com/victor-ferreira95/polypad.git
cd polypad
bash scripts/install.sh
```

The script detects which AI CLIs you have and installs the skill into each.

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

Typical cost: ~2-3k tokens per engaged turn. Trivial turns: zero.

Use `/polypad:status` to check size and get archival recommendations.

## Commands

- `/polypad:init` — initialize in current repo
- `/polypad:status` — show size, age, block counts per agent
- `/polypad:archive` — archive current napkin, carry headers forward

## Uninstall

```
/plugin menu
```

Navigate to `polypad`, then select Uninstall. Or remove the marketplace entirely:

```
/plugin marketplace remove polypad
```

If you installed manually via `scripts/install.sh`:

```bash
rm -rf ~/.claude/skills/polypad
rm -rf ~/.codex/skills/polypad
rm -rf ~/.gemini/skills/polypad
rm -rf ~/.cursor/skills/polypad
```

## Design principles

1. **Full read, isolated write.** Everyone sees everything. No one touches anyone else's blocks.
2. **Lazy load.** Headers first. Narrative on demand.
3. **User orchestrates.** Polypad has no opinion on who should do what.
4. **No ceremony.** No tickets, specs, phases, or delegation protocols.
5. **Cheap by default.** Trivial turns skip the napkin entirely.

## License

MIT
