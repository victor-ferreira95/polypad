---
name: polypad
description: Shared append-only napkin for coordinating any number of AI coding agents (Claude Code, Codex CLI, Gemini CLI, Cursor, and others that follow the open SKILL.md standard) working on the same codebase. Use this skill whenever the user is running a multi-agent workflow, mentions polypad, asks to share context across AI assistants, or is about to do substantive coding/planning/writing work in a repository that contains an `.agents/napkin.md` file. The skill is a lightweight scratchpad, not a task manager — each agent reads what the others thought and did, then appends its own notes. Write-isolation is strict (agents only edit their own blocks) and compaction is automatic per-author.
---

# Polypad

A universal shared-memory napkin for AI coding agents. One file, any number of agents, strict write-isolation, automatic per-author compaction, and aggressive token economy.

Philosophy: **full read, isolated write, lazy load.** Every agent can see everything any other agent thought or did. Each agent only writes under its own tag. The user is the orchestrator — polypad is just memory.

## Step 1: Decide whether to engage at all (token economy rule)

Polypad exists to share context for **substantive work**. Do not engage it for trivial exchanges.

**Engage polypad when the user's turn involves:**
- Writing, refactoring, or reviewing code
- Architectural or design decisions
- Implementing a feature, fixing a bug, or validating another agent's output
- Anything another agent might benefit from knowing later

**Skip polypad when:**
- Answering a factual question ("how does X work?")
- Casual chat or meta-questions about the conversation
- Tiny one-liner edits the user directly dictates
- Read-only exploration ("show me file Y")

If you skip, do not read the napkin and do not write a block. Proceed normally. This keeps token cost zero on light turns.

## Step 2: Identify yourself

Before reading or writing, determine your author tag. Check `.agents/.identity` in the repo (a one-line file with your tag). If it doesn't exist:

1. Detect from environment: `CLAUDE_CODE=1` → `claude`, `CODEX_CLI=1` → `codex`, `GEMINI_CLI=1` → `gemini`, etc.
2. If unclear, ask the user: "Which tag should I use in the polypad? (suggested: claude)"
3. Save the chosen tag to `.agents/.identity`. This file is gitignored — each agent instance has its own identity locally.

Tags are lowercase slugs: `claude`, `codex`, `gemini`, `cursor`, `claude-opus`, `claude-sonnet`, etc.

## Step 3: Lazy read — headers first, expand on demand

Do **not** load the full napkin by default. Load progressively:

**Pass 1 (always, cheap):** read only the headers section — everything from the top of `.agents/napkin.md` down to the first `---` separator line. This gives you each agent's compressed self-summary. Typically 20-50 lines total.

Implementation: `sed -n '1,/^---$/p' .agents/napkin.md` or read with a line limit and stop at the separator.

**Pass 2 (conditional):** after reading headers, decide if the narrative section is relevant to what the user just asked. Expand to the narrative section **only if**:
- You need specifics about a recent decision mentioned in a header
- The user's request references something "we were working on"
- Another agent's recent work directly affects what you're about to do

If none apply, work from headers alone. This saves 60-80% of token cost on typical turns.

**Pass 3 (rare):** read archived napkins in `.agents/archive/` only when the user explicitly asks for historical context.

## Step 4: Napkin anatomy

```markdown
# napkin

## [claude · notes] updated 2026-04-19 16:30
- planned login refactor with Fortify (14:30)
- validated codex throttle, asked for pt-BR copy (15:40)

## [codex · notes] updated 2026-04-19 16:00
- implemented Fortify extending lead guard, commit a3f91c2 (15:12)
- added throttle 5/min, commit 7b2e4f1 (16:00)

## [gemini · notes] updated not yet

---

## [claude] 2026-04-19 16:30
Reviewed codex's throttle. Works, but the lockout message is in
English — needs pt-BR. Gemini can handle the copy.

---

## [gemini] 2026-04-19 16:45
Read what claude and codex wrote. Translated auth messages to
pt-BR matching the app's informal "você" tone.
Files: resources/lang/pt_BR/auth.php
```

**Headers section** (above the first `---`): one `## [<tag> · notes]` per agent that has ever written. Each is that agent's compressed self-history. Only the owning agent edits its own header.

**Narrative section** (below the first `---`): append-only blocks. Any agent can add a block. No agent ever edits a block authored by someone else.

A blank template is in `templates/napkin.md`.

## Step 5: Before writing, compact your own blocks

Compaction is **per-author, never cross-author**.

1. Count narrative blocks with your tag: `grep -c '^## \[<your-tag>\]' .agents/napkin.md` (counts only blocks, not your header).
2. If the count is **greater than 5**, compact:
   - Keep your 2 most recent narrative blocks untouched.
   - For each older block of yours: condense into one bullet (timestamp + one-line summary) and prepend to your `## [<you> · notes]` header at the top.
   - Remove those older narrative blocks from the file.
   - Update the `updated` timestamp in your header.
3. Only then proceed to write your new block.

If another agent has 20 uncompacted blocks, **leave them alone**. Their mess, their responsibility. Write-isolation is absolute.

## Step 6: Write your block

Append at the end of the file, preceded by `---` on its own line.

```markdown

---

## [<you>] YYYY-MM-DD HH:MM

<what you thought, what you did, what you decided, any handoff notes>
```

Use `date "+%Y-%m-%d %H:%M"` for the timestamp in the user's local time.

**Block content guidelines:**
- Be concise. 3-10 lines is typical. Block is a record, not documentation.
- Reference other agents' blocks by timestamp, never by copying their content. Example: "per codex's block at 15:12, migration is live."
- Include commit hashes, file paths, or ticket IDs when relevant — they're cheap signals for the next agent.
- Don't use standardized "phase" labels. Just write what happened in plain prose.

## Step 7: Create your header if it's your first time

If this is your first time writing to this napkin:
- Add a `## [<your-tag> · notes] updated not yet` line to the headers section (above the first `---`).
- Your first narrative block counts as one block toward the compaction threshold.

## Hard rules

1. **Write-isolation is absolute.** Never edit a line inside another agent's header or block. Ever. For any reason.
2. **Narrative is append-only.** Past blocks are record. They only leave via their author compacting them into their own header.
3. **Timestamps are mandatory.** Every block and every header update carries `YYYY-MM-DD HH:MM`.
4. **Lazy load.** Headers-first, narrative on demand, archive only if asked.
5. **Engage only for substantive turns.** Trivial turns skip polypad entirely.
6. **Reference, don't reproduce.** Point at other agents' work via timestamps.

## Slash commands

- `/polypad:init` — create `.agents/napkin.md` in the current repo.
- `/polypad:status` — report napkin size, age, and per-agent block counts.
- `/polypad:archive` — manually archive the current napkin, preserving agent headers.

**Installation note:** for these to appear as native slash commands, the files in `commands/` MUST be copied to each detected agent's commands directory (in addition to the skill directory). The `scripts/install.sh` handles this automatically for every CLI it finds:

- Claude Code → `~/.claude/commands/polypad/`
- Codex CLI → `~/.codex/commands/polypad/`
- Gemini CLI → `~/.gemini/commands/polypad/`
- Cursor → `~/.cursor/commands/polypad/`

If a new agent CLI is added, the installer must replicate both: `~/.<cli>/skills/polypad/` (skill body) and `~/.<cli>/commands/polypad/` (slash commands). Without the commands copy, `/polypad:init` etc. will not appear in the CLI menu — only the skill itself will be triggerable by natural language.

## Auto-archive of stale napkins

If the oldest narrative block is **older than 3 days**, archive before doing anything else:

1. Copy `.agents/napkin.md` to `.agents/archive/napkin-YYYY-MM-DD.md`.
2. Create a new `.agents/napkin.md` containing:
   - Comment: `<!-- started YYYY-MM-DD, previous archived to .agents/archive/napkin-YYYY-MM-DD.md -->`
   - All agent headers copied over verbatim.
   - `---` separator.
   - Empty narrative section.
3. Inform the user: "Archived previous napkin (N days old). Fresh narrative, all agent summaries carried forward."
4. Proceed with the user's request.

A `hooks/auto_archive.sh` is included for CLIs that support pre-session hooks; otherwise the agent does it on first engagement.

## Status check logic

When the user runs `/polypad:status`, report:

1. **Size:** total lines, approximate tokens (lines × ~10).
2. **Recommendation:** if tokens > 5000, recommend `/polypad:archive`.
3. **Age:** oldest narrative block timestamp; flag if > 3 days.
4. **Per-agent block counts:** flag any agent at > 5 blocks (will compact on next write).

Example output:
```
napkin: 847 lines, ~8.5k tokens — consider /polypad:archive
oldest block: 2026-04-16 (3 days old) — auto-archive will trigger
blocks per agent: claude=4, codex=7 (will compact), gemini=1
```

## When NOT to use polypad

- Solo agent, no handoffs: overhead for no gain.
- Throwaway scripts or one-off fixes: skip the ceremony.
- Real-time synchronous pair-programming between two agents: use direct tool-to-tool delegation instead.

Polypad shines when multiple agents work asynchronously on the same repo across sessions, and you want their context to survive `/clear`, agent restarts, and terminal closings.
