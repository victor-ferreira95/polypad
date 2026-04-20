---
description: Report polypad napkin size, age, and per-agent block counts; recommend archival if large or stale
---

Report the current state of the polypad napkin.

Steps:
1. If `.agents/napkin.md` does not exist, tell the user to run `/polypad:init` first.
2. Compute and report:

**Size:**
- Total lines (`wc -l`).
- Approximate tokens: lines × 10.
- If tokens > 5000, recommend `/polypad:archive`.

**Age:**
- Find the oldest narrative block timestamp (below the first `---`).
- Compute age in days.
- If > 3 days, note that auto-archive will trigger on the next engaged turn.

**Per-agent block counts:**
- Count narrative blocks per tag.
- Flag any agent with > 5 blocks.

Format output as compact report:
```
napkin: 847 lines, ~8.5k tokens — consider /polypad:archive
oldest block: 2026-04-16 (3 days old) — auto-archive will trigger
blocks per agent: claude=4, codex=7 (will compact), gemini=1
```

Do not write a block to the napkin for this command — it's read-only.
