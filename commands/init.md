---
description: Initialize polypad in the current repository (creates .agents/napkin.md)
---

Initialize the polypad shared napkin in the current repository.

Steps:
1. Check if `.agents/napkin.md` already exists. If it does, report that and stop.
2. Create `.agents/` directory if missing.
3. Create `.agents/archive/` directory.
4. Copy the skill's `templates/napkin.md` to `.agents/napkin.md`.
5. Add `.agents/.identity` to `.gitignore` if not already present.
6. Report: "Polypad initialized. Napkin at .agents/napkin.md, archive at .agents/archive/."
7. Suggest the user add the polypad engagement snippet to CLAUDE.md, AGENTS.md, or GEMINI.md as appropriate.
