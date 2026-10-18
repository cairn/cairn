# Changelog

## 0.3.2

- macOS (Apple Silicon & Intel) and Linux (x86_64 & ARM64) release binaries.
- Steering a turn no longer triggers an automatic recap, recaps can be cancelled with Esc like any other generation, and interrupting a turn no longer ends with a recap either.
- Ctrl+T cycles the thinking level.
- Images on free models are checked, not assumed: Cairn tests whether a free model actually accepts images when a session starts or the model changes, and remembers the answer. Models that reject images are treated as text-only, and an image already in the history no longer fails every later turn.
- Tokens-per-minute rate limits are recognised as rate limits instead of being misread as context overflows.
- Task lists belong to the session: two Cairn instances in the same project no longer share a list or its reminders, a finished list stays retired when a session is reopened, and the task panel announces its retirement instead of vanishing.
- Background update checks only ever use the official release source.
- Polish: the prompt history position shows in the composer's top border while browsing, the queued-prompt limit appears as a brief status notice, wrapped list rows hang under their text, ordered list markers of any length render correctly, code boxes without a language label get a clean unbroken top border, and Windows terminals get a background fallback.

Verify downloads against `sha256sum.txt`.

## 0.3.1

- macOS (Apple Silicon & Intel) and Linux (x86_64 & ARM64) release binaries.
- Every turn closes with a `Worked for` line giving its duration, end time, and date, followed by a short recap of what the turn did. Recaps stream in and can be cancelled with Esc like any other generation.
- Custom providers: add your own OpenAI-compatible or Anthropic-compatible endpoint from `/provider`, with configurable context size and response-token limits, alongside the built-in providers.
- New settings in `/config`: commit attribution (the bot co-author, the model that wrote the commit, or both), approval mode, default reasoning effort, and mouse capture.
- Running subagents appear below the composer, above the status bar, instead of scrolling through the transcript.
- Code blocks in replies are boxed with a copy affordance, so Ctrl+C inside a box copies the raw source exactly as written.
- Compaction shows as a centred divider naming how many earlier messages were folded away, including compactions that happen while idle.
- Tool call rows use the full width of the terminal and adapt as it resizes, and pickers size to their contents instead of reserving blank rows.
- Tool durations round to the nearest second, so quick calls no longer read as 0s.
- Safer approvals: commands that can execute project code, now including `cargo check` and `cargo clippy` (both run build scripts and procedural macros), ask for approval unless the project is trusted.
- Repeated reads of an unchanged file are answered from context instead of re-reading the file, saving tokens on long sessions.

Verify downloads against `sha256sum.txt`.

## 0.2.5

- macOS (Apple Silicon & Intel) and Linux (x86_64 & ARM64) release binaries.
- Editor integration: Cairn speaks the Agent Client Protocol over stdio, so editors and GUI clients can drive it natively. Sessions reopen after a restart or crash, tool approvals and questions appear right in your editor, and concurrent approvals arrive as one prompt.
- New `/fingerprint` command guesses which lab built a stealth or codenamed model from a short probe battery and shows the evidence behind its verdict; `--raw` prints every probe's reply. It runs in the background so typing stays responsive.
- Lower idle memory: `/new` and `/clear` release freed memory immediately instead of leaving the process at its peak.
- Word-wise cursor movement in the composer with Alt/Option+arrow keys.
- URLs inside code fences are clickable.
- ChatGPT turns keep their thinking across context compaction and reuse cached prompts more often, so follow-ups come back faster.
- Pull request descriptions come prefilled with title, summary, and test plan, ready to submit.
- Credentials are stored only in your system keychain; there is no plaintext fallback file.
- A stray `.git` folder at the temp directory or filesystem root is ignored instead of confusing repository detection.

Verify downloads against `sha256sum.txt`.

## 0.2.3

- macOS (Apple Silicon & Intel) and Linux (x86_64 & ARM64) release binaries.
- The native Windows build is discontinued. Windows is no longer a supported platform and no Windows binary is published.
- Linux write-jail sandbox built on Landlock (implemented and tested; not yet wired into command execution, so commands are not confined by it yet).
- Native ChatGPT device-code login via `/auth login chatgpt`.
- Nous Portal provider (`NOUS_API_KEY`).
- `/recap` command summarizing the session without touching history.
- Compaction reports why it folded nothing instead of failing silently, and streams the summarizer live.
- Terminal UI redraw capped at 144 Hz, and Up restores a queued prompt to the composer.

## 0.2.2

- macOS (Apple Silicon & Intel), Linux (x86_64 & ARM64), and Windows (x86_64) release binaries.
- macOS write-jail sandbox built on Seatbelt (implemented and tested; not yet wired into command execution, so commands are not confined by it yet).
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
