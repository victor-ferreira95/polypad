# Changelog

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
