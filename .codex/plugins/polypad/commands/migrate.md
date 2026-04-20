---
description: Migrate a project from polypad v0.2 (.agents/) to v0.3+ (.polypad/)
---

Migrate an existing polypad installation from the v0.2 layout (`.agents/napkin.md`) to the v0.3 layout (`.polypad/napkin.md`).

Steps:

1. Check if `.agents/napkin.md` exists. If not, tell the user there is nothing to migrate and stop.

2. Check if `.polypad/` already exists. If it does, tell the user: "`.polypad/` already exists — migration may cause data loss. Resolve manually by reviewing both directories and then removing the old `.agents/`." Stop.

3. Rename the directory:

   ```bash
   mv .agents .polypad
   ```

4. Update `.gitignore` references:
   - If `.gitignore` contains `.agents/.identity.*`, replace with `.polypad/.identity.*`
   - If `.gitignore` contains `.agents/` (entire dir ignored), replace with `.polypad/`

5. Update engagement snippets in CLAUDE.md, AGENTS.md, GEMINI.md:
   - Find any blocks between `<!-- polypad:start -->` and `<!-- polypad:end -->` markers
   - Replace mentions of `.agents/` with `.polypad/` inside those blocks

6. Report to the user:

   ```
   Migrated polypad from .agents/ to .polypad/
   Updated: .gitignore, CLAUDE.md (if present), AGENTS.md (if present), GEMINI.md (if present)

   Please review the changes with `git diff` before committing.
   ```

7. Remind the user to commit the changes so teammates don't stay on the old layout.
