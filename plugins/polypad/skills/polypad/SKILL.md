---
name: polypad
description: Shared append-only napkin for coordinating any number of AI coding agents (Claude Code, Codex CLI, Gemini CLI, Cursor, and others that follow the open SKILL.md standard) working on the same codebase. Engage this skill on EVERY turn that uses Write, Edit, or any file/code creation tool — the decision is mechanical and non-optional. Each agent reads what the others thought and did, then appends its own block. Write-isolation is strict (agents only edit their own blocks), compaction is automatic per-author, and a Stop hook enforces the protocol at the end of each turn.
---

# Polypad

A universal shared-memory napkin for AI coding agents. One file, any number of agents, strict write-isolation, automatic per-author compaction, token-efficient lazy loading, and **mechanical enforcement** at turn end.

Philosophy: **full read, isolated write, lazy load, enforced checkpoint.**

## Engagement rules

Polypad has two engagement rules. Apply BOTH on every turn.

### Rule (a) — Mechanical: any write engages

Before responding, answer this yes/no question:

> **"Did this turn include a Write, Edit, MultiEdit, NotebookEdit, or any file/code creation tool call?"**

- **YES** → Engage polypad. Read the napkin (headers first), do your work, write a block before finishing the turn. **Not optional.**
- **NO** → Skip rule (a). Move to rule (b).

This rule is enforced mechanically by a Stop hook. If you called write/edit tools and did not update `.polypad/napkin.md`, the hook blocks your response and forces you to write a block before replying.

### Rule (b) — Semantic: non-obvious findings engage

Even if you didn't write any file, engage polypad when this turn produced a **non-obvious finding** that another agent (or you tomorrow) would benefit from knowing.

Two tests to decide:

1. **Rediscovery test:** "If another agent (or me tomorrow) asks the same question in this repo, will they have to redo this work from scratch?"
2. **Telephone test:** "If I had to hand off this conversation to another agent right now, what would they need to know that isn't already visible in the code or git log?"

If rule (b) applies, engage polypad **even on read-only turns**:
- Read the napkin headers.
- Write a short block summarizing the finding.
- Then respond to the user.

Rule (b) is **not** enforced by the hook — it requires semantic judgment that the hook can't make. You are responsible for applying it yourself. Use the two tests as a check before finishing read-only turns.

### What NOT to engage for

Neither rule applies to:
- Factual Q&A with obvious answers ("what does this function do?" when the function is self-explanatory)
- Simple code explanation that another agent would produce the same way in seconds
- Formatting questions, syntax lookups, trivia
- Listing files, showing status, answering "where is X defined" when the answer is a one-line find

When in doubt, ask the rediscovery test: if the next agent would redo the work in under 30 seconds, skip. Otherwise, engage.

## Examples of rule (b) engagement

These are read-only turns (no Write/Edit) that SHOULD engage the napkin because they produce persistent knowledge:

**Environment diagnostics**
- "The `.http` files in apps/api return 503 because the API wasn't running. Start with `pnpm run api:dev` before executing them."
- "Redis must be up locally for the auth flow to work. Not documented anywhere yet."

**Root-cause analysis**
- "The 404 on `/leads/:id` is because the route is registered in `routes/internal.php`, not `routes/api.php`. Anyone looking in `api.php` first will be confused."
- "N+1 query in the dashboard comes from `resolveLeadOwner()` — eager-loading `owner` on the base query fixes it."

**Architectural decisions**
- "User and team agreed to go with Fortify instead of Sanctum for auth. Reason: existing LeadGuard integration is cleaner to extend via Fortify actions."
- "Decided webhooks stay synchronous for now; no queue yet because traffic doesn't justify it."

**Code navigation insights**
- "Authentication actually lives in `app/Guards/LeadGuard.php`, not `config/auth.php`. The config just points to it."
- "The pricing engine is in `domain/Pricing/`, but the actual discount rules are data-driven in `config/discounts.php`."

These are read-only turns that should NOT engage:

**Trivial Q&A**
- "What does `array_map` do?" → well-documented, skip.
- "Show me the current branch name" → one command, skip.

**Obvious answers**
- "What's in this file?" → user can read it themselves, skip unless you synthesize something non-obvious.

**Pure formatting or style**
- "Is this code following PSR-12?" → style check, skip.

The rule of thumb: **if explaining the finding takes longer than rediscovering it, skip. If rediscovering it would take minutes or longer, engage.**

## Empty napkin is not an excuse

An empty napkin (no narrative blocks, only headers or blank file) means **you are the first agent**. This is the most common state for a new repo.

Do not interpret emptiness as "no context to engage with". Interpret it as "**I am the one creating the context.**"

On an empty napkin, when your turn involves writes:

1. If `.polypad/napkin.md` doesn't exist → create it (copy `templates/napkin.md`).
2. If your agent tag has no header in the napkin → add `## [<your-tag> · notes] updated not yet` at the top of the headers section.
3. Do the user's task.
4. Write your first narrative block before the turn ends.

The bootstrap responsibility is on the first agent. Do not leave an empty napkin after a substantive turn.

## Cumulative thinking (anti salami-slicing)

A single turn can contain many small edits. **Do not evaluate each edit individually** for "is this worth a block?". Evaluate the entire turn as one unit:

> "Did I change the codebase in any way during this turn that another agent would benefit from knowing?"

If yes → **one consolidated block** at the end of the turn, summarizing the turn's net outcome. Not N tiny blocks.

Block content should describe the outcome ("implemented X with approach Y, commit Z"), not narrate each tool call ("ran Write on file A, then Edit on file B").

## Step 2: Identify yourself

Each CLI uses its own identity file, preventing race conditions when multiple agents run simultaneously in the same repo.

1. Detect your CLI from environment variables and pick your identity file:

   | Environment variable | Identity file | Default tag |
   |---|---|---|
   | `CLAUDE_CODE=1` | `.polypad/.identity.claude` | `claude` |
   | `CODEX_CLI=1` | `.polypad/.identity.codex` | `codex` |
   | `GEMINI_CLI=1` | `.polypad/.identity.gemini` | `gemini` |
   | (none of the above) | `.polypad/.identity.<cli>` where `<cli>` is your CLI name in lowercase | prompt the user |

2. Read your identity file:
   - If it exists, use its single-line content as your author tag for this session.
   - If it doesn't exist, create it with your default tag (e.g., `echo "claude" > .polypad/.identity.claude`). If no default applies, ask the user: "Which tag should I use in the polypad? (suggested based on your CLI)"

3. Use the resulting tag for every block you write and for your header in the napkin. Tags are lowercase slugs: `claude`, `codex`, `gemini`, `cursor`, `claude-opus`, `claude-sonnet`, etc.

**Why per-CLI files:** if two CLIs initialize in parallel (first run on a shared repo), a single shared `.polypad/.identity` file would race — one agent could overwrite the other's tag. Per-CLI files make concurrent access safe by construction: each agent only ever writes its own file.

The identity files are gitignored via the `.polypad/.identity.*` pattern — each user's local setup decides their tags, nothing is committed.

## Step 2: Lazy read — headers first

Do **not** load the full napkin by default. Load progressively:

**Pass 1 (always, cheap):** read only the headers section — everything from the top of `.polypad/napkin.md` down to the first `---` separator line. ~300 tokens typically.

Implementation: `sed -n '1,/^---$/p' .polypad/napkin.md` or bounded read.

**Pass 2 (conditional):** expand to the narrative section only if:
- A header mentions something directly relevant to your current task
- The user references earlier work ("continue with what we did")
- Another agent's recent block affects what you're about to change

If none apply, work from headers alone.

**Pass 3 (rare):** read `.polypad/archive/*.md` only when the user explicitly asks for historical context.

## Step 3: Napkin anatomy

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

**Headers section** (above first `---`): one `## [<tag> · notes]` per agent. Only the owning agent edits its own header.

**Narrative section** (below first `---`): append-only blocks. Any agent appends. No agent ever edits a block authored by someone else.

## Versioning modes

Polypad can run in two modes, chosen when `/polypad:init` runs:

**Shared (default):** `.polypad/napkin.md` is committed to git, `.polypad/.identity.*` is gitignored. Teammates working from different machines see each other's blocks via git pulls. This is the canonical mode for multi-agent async collaboration.

**Local:** `.polypad/` is entirely gitignored. Each developer has their own napkin, nothing is committed. Useful when a single developer coordinates multiple AI CLIs on the same machine but does not want the napkin in git history.

When engaging with a napkin, do NOT assume one mode over the other — just read and write normally. The mode is a user choice about git, not about protocol behavior.

If you are engaging in a turn that involves writes and the napkin is inside a git-tracked path, remind the user once per session (only if it comes up naturally in the response): "Note: your napkin is shared via git — remember to commit it periodically so your teammates see the context."

## Step 4: Before writing, compact your own blocks

Per-author, never cross-author.

1. Count narrative blocks with your tag.
2. If count > 5, compact:
   - Keep your 2 most recent narrative blocks untouched.
   - Condense older blocks into bullets in your header (timestamp + one-line).
   - Remove those older blocks from narrative.
   - Update `updated` timestamp.
3. Only then write your new block.

If another agent has 20 uncompacted blocks, leave them alone. Their mess, their responsibility.

## Step 5: Write your block

Append at the end, preceded by `---` on its own line.

```markdown

---

## [<you>] YYYY-MM-DD HH:MM

<3-10 lines: what you did, key decisions, file paths, commit hashes, handoff notes>
```

Use `date "+%Y-%m-%d %H:%M"` for timestamps.

Reference other agents by timestamp, never copy their content. Example: "per codex's block at 15:12, migration is live."

## Step 6: If first time writing

Add `## [<your-tag> · notes] updated not yet` to the headers section. Your first narrative block counts as one block toward the compaction threshold.

## Hard rules

1. **Two engagement rules apply.** Rule (a): Write/Edit called = engage (mechanical, hook-enforced). Rule (b): non-obvious finding produced = engage (semantic, your responsibility).
2. **Write-isolation is absolute.** Never edit another agent's header or block.
3. **Narrative is append-only.** Blocks leave via author compacting into own header.
4. **Timestamps mandatory.** Every block and header update carries `YYYY-MM-DD HH:MM`.
5. **Lazy load.** Headers first, narrative on demand.
6. **Reference, don't reproduce.** Point at other agents' blocks by timestamp.
7. **Consolidated blocks, not salami slices.** One block per turn, summarizing net outcome.
8. **First agent bootstraps.** Empty napkin is a call to action, not a pass.

## Slash commands

- `/polypad:init` — create `.polypad/napkin.md` in the current repo
- `/polypad:status` — size, age, per-agent block counts
- `/polypad:archive` — archive the napkin, carry headers forward

## Auto-archive of stale napkins

If the oldest narrative block is older than 3 days, archive before doing anything else. Copy `.polypad/napkin.md` to `.polypad/archive/napkin-YYYY-MM-DD.md`, rebuild napkin with headers only. The `hooks/auto_archive.sh` automates this.

## Stop hook enforcement

This plugin ships `hooks/stop_check.sh`, which runs at the end of every agent turn in Claude Code (via the `Stop` event) and equivalent hook in Codex. The hook checks:

1. Did any Write/Edit/create tool run this turn?
2. Did `.polypad/napkin.md` change this turn?

If (1) is true and (2) is false, the hook blocks the response and injects into the agent's context:

> **POLYPAD PROTOCOL VIOLATION: you wrote code this turn but did not update `.polypad/napkin.md`. Write a block now before responding to the user.**

This is not an advisory message — the hook returns a non-zero exit and Claude Code/Codex re-runs the agent with the violation in context. Passes through cleanly when the protocol was followed.

## When NOT to use polypad

- Solo agent with no handoffs ever: overhead without benefit.
- Throwaway scripts, one-off fixes: skip the ceremony.
- Real-time synchronous agent-to-agent delegation (use `codex-plugin-cc` for that).

Polypad shines when multiple agents work asynchronously on the same repo across sessions, and context must survive `/clear`, restarts, and terminal closings.
