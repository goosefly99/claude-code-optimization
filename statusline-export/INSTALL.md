# Claude Code Statusline — Installation

A custom multi-line statusline for [Claude Code](https://docs.claude.com/en/docs/claude-code) on Windows. Renders three rows above the prompt: directory + git branch + session, model + effort + context bar, and rate limits + clock + diff stats.

```
◐ C:/Users/olive/claude_projects | (main wt:experiment) | my-feature

Opus 4.7 | effort:high | think:on | ▓▓▓▓░░░░░░ 42%

5hr:6% | 7d:1% | 23:37 | +120 -34
```

Every segment drops silently when its field isn't present in the JSON Claude Code sends.

## Bundle contents

The export bundle lives at `C:\Users\olive\claude_projects\statusline-export\` and contains two files:

| File | Purpose |
| ---- | ------- |
| `statusline-command.ps1` | Runtime script Claude Code invokes on every refresh. Reads JSON from stdin, writes ANSI-colored output to stdout. |
| `install.ps1`            | Installer. Copies the runtime script into `~/.claude/` and patches `settings.json`. |

## Prerequisites

- **PowerShell 7+** (`pwsh`). The installer uses `ConvertFrom-Json -AsHashtable`, which is PS 7+ only.
- **Claude Code** installed. The installer creates `~/.claude/` if missing.
- A terminal that renders ANSI escapes and UTF-8 (Windows Terminal, modern PowerShell hosts).

## Install

From inside the bundle folder:

```powershell
pwsh -NoProfile -File ./install.ps1
```

The installer:

1. Creates `%USERPROFILE%\.claude\` if missing.
2. Copies `statusline-command.ps1` to `%USERPROFILE%\.claude\statusline-command.ps1`.
3. Reads existing `%USERPROFILE%\.claude\settings.json` (or starts empty), replaces only the `statusLine` block, and writes it back. **All other keys are preserved.**

The patched `statusLine` block:

```json
{
  "statusLine": {
    "type": "command",
    "command": "pwsh -NoProfile -File C:/Users/<you>/.claude/statusline-command.ps1",
    "refreshInterval": 1
  }
}
```

`refreshInterval: 1` lets the decorative spinner advance at 1 Hz. Drop it if you don't want second-by-second redraws.

### Custom install location

```powershell
pwsh -NoProfile -File ./install.ps1 -ClaudeDir C:/some/.claude
```

Useful for testing on a copy or a non-default Claude layout.

## Verify

After install, restart Claude Code. You should see three colored rows above the prompt input.

To exercise the script directly without launching Claude:

```powershell
'{"workspace":{"current_dir":"C:/tmp"},"model":{"display_name":"Opus 4.7"},"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":6},"seven_day":{"used_percentage":1}},"cost":{"total_lines_added":120,"total_lines_removed":34}}' | pwsh -NoProfile -File ~/.claude/statusline-command.ps1
```

Expect three colored lines separated by blank lines.

## Layout reference

| Line | Segments (left → right) |
| ---- | ----------------------- |
| 1 | spinner · cwd · git branch (or `(branch wt:worktree)` when in a linked worktree) · session name · `+N dirs` |
| 2 | model · `effort:<level>` · `think:on` · context bar `▓▓▓▓░░░░░░ N%` |
| 3 | `5hr:N%` · `7d:N%` · clock `HH:MM` · `+X -Y` diff stats |

Pre-call (before the first message in a session), the context bar and rate-limit fields stay empty; the line still renders the clock so it's never blank.

## Customize

Edit `statusline-command.ps1` (either in the bundle and re-run `install.ps1`, or directly at `~/.claude/statusline-command.ps1`):

- **Colors** — ANSI block under `# ANSI colors`.
- **Layout** — the `Line 1` / `Line 2` / `Line 3` assembly sections at the bottom.
- **Padding** — the print loop's `Write-Host ""` controls blank lines between rows.
- **Spinner frames** — `$spinFrames = @('◐','◓','◑','◒')`.

Changes take effect on the next refresh.

## Uninstall

Delete `~/.claude/statusline-command.ps1` and remove the `statusLine` block from `~/.claude/settings.json`. Claude Code falls back to its default statusline.
