---
description: Initialize polypad in the current repository, or register the current CLI if polypad is already set up. Idempotent — safe to re-run.
---

Initialize polypad in the current repository, or register the current CLI if polypad is already initialized. This command is idempotent: running it multiple times only creates what's missing.

## Step 1 — Identify the current CLI

Detect the CLI invoking this command from environment variables:

| Env var | CLI | Tag | Identity file | Snippet file |
|---|---|---|---|---|
| `CLAUDE_CODE=1` | Claude Code | `claude` | `.polypad/.identity.claude` | `CLAUDE.md` |
| `CODEX_CLI=1` | Codex CLI | `codex` | `.polypad/.identity.codex` | `AGENTS.md` |
| `GEMINI_CLI=1` | Gemini CLI | `gemini` | `.polypad/.identity.gemini` | `GEMINI.md` |
| (Cursor env) | Cursor | `cursor` | `.polypad/.identity.cursor` | `.cursorrules` |

If none of these env vars are set, ask the user: "Which CLI is this? (claude/codex/gemini/cursor)" and use the answer.

Store the detected values as `CLI_TAG`, `IDENTITY_FILE`, `SNIPPET_FILE` for the rest of the command.

## Step 2 — Check current state

Determine what already exists:

- `PROJECT_INITIALIZED` = does `.polypad/napkin.md` exist?
- `CLI_REGISTERED` = does `IDENTITY_FILE` exist?
- `SNIPPET_PRESENT` = does `SNIPPET_FILE` contain `<!-- polypad:start -->`?

If `PROJECT_INITIALIZED=false` and legacy `.agents/napkin.md` exists, tell the user: "Found legacy `.agents/` layout from polypad v0.2. Run `/polypad:migrate` first." Stop.

## Step 3 — Phase A: project setup (only if not initialized)

**Skip this phase if `PROJECT_INITIALIZED=true`.** Report to the user that the project is already initialized, and move to Phase B.

If `PROJECT_INITIALIZED=false`:

1. Ask the user which versioning mode:

   ```
   Polypad is not yet initialized in this repo. Choose versioning mode:

     1) Shared via git (recommended for teams)
        - .polypad/napkin.md is committed
        - Teammates see each other's context across machines
        - Only .polypad/.identity.* stays local

     2) Local only (for solo developers)
        - .polypad/ is entirely gitignored
        - Each developer has their own napkin

   Which mode? [1/2, default: 1]
   ```

   Default to 1 if empty. Save as `VERSIONING_MODE`.

2. Create `.polypad/` directory.

3. Create `.polypad/archive/` directory.

4. Copy `templates/napkin.md` from the skill to `.polypad/napkin.md`.

5. Update `.gitignore`:
   - Mode 1 (shared): ensure `.polypad/.identity.*` is present.
   - Mode 2 (local): ensure `.polypad/` is present.

6. Mark `PROJECT_INITIALIZED=true` (in-memory for this run).

## Step 4 — Phase B: register the current CLI (always runs)

This phase is idempotent — creates only what's missing for `CLI_TAG`.

### 4a. Identity file

If `CLI_REGISTERED=false`:
- Write `CLI_TAG` to `IDENTITY_FILE` (e.g., `echo "claude" > .polypad/.identity.claude`).
- Mark action: "created identity file".

If `CLI_REGISTERED=true`:
- Mark action: "identity already registered".

### 4b. Snippet in the CLI's config file

Compute the current snippet content:

```markdown
<!-- polypad:start -->
## Multi-agent coordination (polypad)

This project uses the polypad protocol for multi-agent coordination.

**Decision rule:** if your turn includes Write, Edit, or any file-creation tool, you MUST read and update `.polypad/napkin.md` — this is mechanically enforced by a Stop hook.

**Read:** start by reading the headers section of `.polypad/napkin.md` (everything before the first `---`). This gives each agent's compressed self-summary.

**Write:** before finishing a turn that changed code, append a single consolidated block under your agent tag. Never edit blocks authored by other agents.

**Bootstrap:** if the napkin is empty, you are the first agent — that is a call to action, not a reason to skip.

Tag yourself from `.polypad/.identity.<cli>` (claude / codex / gemini / cursor).

See https://github.com/victor-ferreira95/polypad for the full protocol.
<!-- polypad:end -->
```

If `SNIPPET_FILE` doesn't exist:
- Create it with just the snippet above.
- Mark action: "created SNIPPET_FILE with polypad snippet".

If `SNIPPET_FILE` exists and contains `<!-- polypad:start -->` and `<!-- polypad:end -->`:
- Check if the content between the markers matches the current snippet exactly.
- If matches: mark action: "snippet already present and up to date".
- If differs: replace the content between markers with the current snippet. Mark action: "snippet updated".

If `SNIPPET_FILE` exists but has no polypad markers:
- Append a blank line, then the snippet, at the end of the file.
- Mark action: "snippet appended to existing SNIPPET_FILE".

## Step 5 — Report

Report a concise summary of what happened. Pick the relevant lines:

```
polypad status for this repo:

Project:
  ✓ .polypad/napkin.md  (already existed / created in shared mode / created in local mode)
  ✓ .gitignore  (already configured / updated)

This CLI (<CLI_TAG>):
  ✓ .polypad/.identity.<cli>  (already existed / created)
  ✓ <SNIPPET_FILE>  (already had snippet / created / updated / appended)
```

If **all** items were already present before this run, add:

```
Nothing to do — polypad is fully configured for this CLI.
```

If **project was just initialized** (Phase A ran), add:

```
If teammates use other AI CLIs in this repo, they should run
/polypad:init from those CLIs so each one registers its own
identity and snippet file.
```

## Examples

### First time ever in a repo (Claude goes first)

User runs `/polypad:init` from Claude Code.

- Phase A runs: asks versioning mode, creates `.polypad/napkin.md`, updates `.gitignore`.
- Phase B runs: creates `.polypad/.identity.claude`, creates `CLAUDE.md` with snippet.
- Report: project initialized, Claude registered, reminder for teammates.

### Second CLI joins later (Codex arrives)

Later, Codex runs `/polypad:init` in the same repo.

- Phase A: skipped (napkin exists).
- Phase B: `.polypad/.identity.codex` doesn't exist → creates it. `AGENTS.md` doesn't exist → creates with snippet.
- Report: project already initialized, Codex registered.

### Re-running init in the same CLI

Claude runs `/polypad:init` again.

- Phase A: skipped.
- Phase B: `.polypad/.identity.claude` exists → skipped. `CLAUDE.md` has current snippet → skipped.
- Report: nothing to do, fully configured.
