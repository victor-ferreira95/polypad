# Changelog

## [0.3.2] - 2026-04-19

### Added

- **Engagement rule (b) for non-obvious findings.** Read-only turns that produce diagnoses, root-cause analysis, architectural decisions, or code-navigation insights now engage the napkin — not just turns that write code. The previous single rule ("Write/Edit = engage") was too mechanical and missed valuable context. Rule (b) is semantic, applied by the agent using two concrete tests (rediscovery test and telephone test). See SKILL.md for examples of what engages vs what doesn't.

### Changed

- SKILL.md section "Decision rule" renamed to "Engagement rules" (plural) and split into (a) mechanical and (b) semantic.
- New SKILL.md section "Examples of rule (b) engagement" with concrete cases to calibrate agent judgment.

### Not changed

- Stop hook (`stop_check.sh`) behavior. Rule (b) is semantic and can't be detected by the hook — it remains the agent's responsibility. Rule (a) continues to be hook-enforced exactly as before.

## [0.3.1] - 2026-04-19

### Fixed

- `/polypad:init` is now idempotent and handles multi-CLI registration correctly. Previously, if a CLI initialized the project first (e.g., Codex), subsequent CLIs (e.g., Claude) could not register themselves because init aborted when the napkin already existed. Now the command detects per-CLI state and only creates what's missing, regardless of which CLI initialized the project first.

### Changed

- Removed the upfront "which CLIs will use this repo" question from `/polypad:init`. Each CLI now self-registers by running `/polypad:init` on its first use in the repo. This decouples the decision and makes onboarding new CLIs trivial.
- Init output is now a per-CLI status report showing what was created vs already present.

## [0.3.0] - 2026-04-19

### Breaking changes

- **Renamed `.agents/` to `.polypad/`** in all user-facing paths to avoid namespace conflicts with other agent frameworks and to make the plugin's files clearly identifiable. Users on v0.2 must run `/polypad:migrate` once after upgrading.

### Added

- `/polypad:migrate` command for one-shot migration from v0.2 layout.
- Multi-CLI selection in `/polypad:init` — user picks which CLIs will coordinate via polypad, and the engagement snippet is written to the chosen CLI files (CLAUDE.md, AGENTS.md, GEMINI.md, .cursorrules).
- Engagement snippets now use `<!-- polypad:start -->` / `<!-- polypad:end -->` markers for idempotent re-runs.
- Snippet content updated to reflect v0.2 enforcement semantics (Stop hook, decision rule, bootstrap).

### Changed

- All hooks (`stop_check.sh`, `auto_archive.sh`) updated to read from `.polypad/` instead of `.agents/`.
- Stop hook detects legacy `.agents/` layout and asks the user to run `/polypad:migrate`.

## [0.2.0] - 2026-04-19

### Added
- **Stop hook (`hooks/stop_check.sh`)** that enforces protocol compliance at the end of every agent turn. If the agent called Write/Edit/file-creation tools but did not touch `.agents/napkin.md`, the hook blocks the response and forces a block to be written.
- Bootstrap rule: explicit instruction that empty napkin is a call to action for the first agent, not a reason to skip engagement.
- Cumulative thinking rule: one consolidated block per turn, not N tiny blocks per edit.
- Plugin manifest now registers the Stop hook for both Claude Code and Codex.

### Changed
- **Decision rule rewritten as mechanical yes/no check** (did Write/Edit run?) instead of subjective "substantive work" heuristic. Eliminates the ambiguity that led to agents silently skipping the protocol in v0.1.
- SKILL.md restructured: hard rules expanded from 6 to 8, with explicit entries for decision mechanics and cumulative thinking.

### Fixed
- Agent silent non-compliance when focused on implementation tasks (observed in v0.1 real-world use).

## [0.1.0] - 2026-04-19

Initial release.

- Universal shared napkin protocol for AI coding agents
- Per-author write-isolation
- Per-author compaction (threshold: 5 blocks)
- Auto-archive after 3 days
- Token-efficient lazy loading (headers first)
- Install targets: Claude Code, Codex CLI, Gemini CLI, Cursor
- Slash commands: `/polypad:init`, `/polypad:status`, `/polypad:archive`
