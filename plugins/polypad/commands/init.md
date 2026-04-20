---
description: Initialize polypad in the current repository (creates .polypad/napkin.md, configures .gitignore, and writes engagement snippets to chosen CLI files)
---

Initialize the polypad shared napkin in the current repository.

Steps:

1. Check if `.polypad/napkin.md` already exists. If it does, report that and stop.

2. Check if `.agents/napkin.md` exists (v0.2 layout). If yes, tell the user: "Found legacy `.agents/` layout from polypad v0.2. Run `/polypad:migrate` first, then re-run `/polypad:init` if needed." Stop.

3. Ask the user which versioning mode:

   ```
   Polypad supports two versioning modes:

     1) Shared via git (recommended for teams)
        - .polypad/napkin.md is committed
        - Teammates see each other's context across machines
        - Only .polypad/.identity.* stays local

     2) Local only (for solo developers)
        - .polypad/ is entirely gitignored
        - Each developer has their own napkin

   Which mode? [1/2, default: 1]
   ```

   Default to 1 if empty.

4. Ask the user which AI CLIs will work on this repo:

   ```
   Which AI CLIs will coordinate via polypad in this repo?
   Select all that apply (separate with commas, e.g. "1,2"):

     1) Claude Code     → adds snippet to CLAUDE.md
     2) Codex CLI       → adds snippet to AGENTS.md
     3) Gemini CLI      → adds snippet to GEMINI.md
     4) Cursor          → adds snippet to .cursorrules
     5) All of the above

   Selection? [default: detect from environment]
   ```

   If the user presses enter without answering, detect from env: Claude invoked `init` → pick 1; Codex → pick 2; Gemini → pick 3; otherwise default to 1.

5. Create `.polypad/` directory.

6. Create `.polypad/archive/` directory.

7. Copy `templates/napkin.md` from the skill to `.polypad/napkin.md`.

8. Update `.gitignore`:
   - **Mode 1 (shared):** ensure `.polypad/.identity.*` is present. Do NOT add `.polypad/` itself.
   - **Mode 2 (local):** ensure `.polypad/` is present (covers identity and napkin).

9. For each selected CLI, create or update the engagement snippet in the corresponding file. Use the idempotent marker pattern:

   ```
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

   Idempotency rules for each target file:
   - If the file doesn't exist, create it with just the snippet.
   - If the file exists and contains `<!-- polypad:start -->` and `<!-- polypad:end -->` markers, replace the content between markers with the current snippet.
   - If the file exists but has no polypad markers, append the snippet (with a blank line before) at the end of the file.
   - Never duplicate the snippet.

10. Report to the user:

    - Mode (shared or local)
    - Which CLI files were created or updated
    - Example output:
      ```
      Polypad initialized in shared mode.
      Created: .polypad/napkin.md, .polypad/archive/
      Updated: .gitignore, CLAUDE.md (polypad snippet added)

      Next: if teammates use other AI CLIs in this repo, run /polypad:init
      from those CLIs too so they each add their own snippet file.
      ```
