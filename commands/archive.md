---
description: Archive the current napkin and start a fresh one, preserving agent headers
---

Archive the current polypad napkin and start fresh, carrying forward only each agent's compressed header summary.

Steps:
1. If `.agents/napkin.md` does not exist, tell the user to run `/polypad:init` first.
2. Ensure `.agents/archive/` exists.
3. Compute archive filename: `.agents/archive/napkin-YYYY-MM-DD.md`. If exists, append `-2`, `-3`, etc.
4. Copy `.agents/napkin.md` to the archive path.
5. Build new napkin content:
   - Comment: `<!-- started YYYY-MM-DD, previous archived to <path> -->`
   - `# napkin`
   - All header lines between `# napkin` and the first `---` (verbatim).
   - `---`
   - Empty line.
6. Overwrite `.agents/napkin.md`.
7. Report: "Archived napkin to `.agents/archive/napkin-YYYY-MM-DD.md`. Fresh narrative, all agent summaries carried forward."

Do not write a narrative block for this command.
