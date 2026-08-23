# Changelog

## 0.2.3

- macOS (Apple Silicon & Intel) and Linux (x86_64 & ARM64) release binaries.
- The native Windows build is discontinued. Windows is no longer a supported platform and no Windows binary is published.
- Linux write-jail sandbox built on Landlock, refusing to run rather than running unconfined when the kernel cannot enforce it.
- Native ChatGPT device-code login via `/auth login chatgpt`.
- Nous Portal provider (`NOUS_API_KEY`).
- `/recap` command summarizing the session without touching history.
- Compaction reports why it folded nothing instead of failing silently, and streams the summarizer live.
- Terminal UI redraw capped at 144 Hz, and Up restores a queued prompt to the composer.

## 0.2.2

- macOS (Apple Silicon & Intel), Linux (x86_64 & ARM64), and Windows (x86_64) release binaries.
- macOS write-jail sandbox built on Seatbelt.
- `/limits` command showing provider quota usage.
- OpenCode Zen free models listed under `/model`.
- Read-only MCP tools allowed in plan mode.
- `apply_patch` uses a distinct bandage emoji in the terminal UI.
- Sandbox, voice, self-update, and terminal UI fixes.

## 0.2.1

- macOS (Apple Silicon & Intel), Linux (x86_64 & ARM64), and Windows (x86_64) release binaries.
- Self-update support via `cairn update`.
- Search, installer, and terminal UI improvements.

## 0.2.0

- Windows and Linux (x86_64) release binaries.
- Performance, stability, and terminal UI improvements.

## 0.1.0

- First public binaries: Windows and Linux (x86_64). macOS is not built yet.
