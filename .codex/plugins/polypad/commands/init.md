---
description: Initialize polypad in the current repository (creates .agents/napkin.md and configures .gitignore based on versioning mode)
---

Initialize the polypad shared napkin in the current repository.

Steps:

1. Check if `.agents/napkin.md` already exists. If it does, report that and stop.

2. Ask the user which versioning mode they want:

   ```
   Polypad supports two versioning modes:

     1) Shared via git (recommended for teams)
        - .agents/napkin.md is committed to the repo
        - Teammates see each other's context across machines
        - Only .agents/.identity.* stays local

     2) Local only (for solo developers)
        - .agents/ is entirely gitignored
        - Each developer has their own napkin
        - Nothing is committed

   Which mode? [1/2, default: 1]
   ```

3. Wait for the user's response. If they press enter with no value, assume `1`.

4. Create `.agents/` directory if missing.

5. Create `.agents/archive/` directory.

6. Copy the skill's `templates/napkin.md` to `.agents/napkin.md`.

7. Update `.gitignore` based on mode:

   - **Mode 1 (shared):** ensure `.agents/.identity.*` is present in `.gitignore`. Do NOT add `.agents/` itself.
   - **Mode 2 (local):** ensure `.agents/` is present in `.gitignore`. This also covers `.identity.*` and napkin.md.

   If `.gitignore` doesn't exist, create it with the appropriate line.

8. Report to the user:

   - For mode 1: "Polypad initialized in shared mode. Commit `.agents/napkin.md` so your teammates can see the context. `.agents/.identity.*` stays local."
   - For mode 2: "Polypad initialized in local mode. `.agents/` is gitignored — nothing is committed."

9. Suggest adding the polypad engagement snippet to `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` as appropriate.
