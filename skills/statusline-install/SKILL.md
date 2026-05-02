---
name: statusline-install
description: >
  Install or uninstall the bundled multi-line PowerShell statusline for
  Claude Code on Windows. Use when the user says "install the statusline",
  "set up the statusline", "show me the statusline", "uninstall the
  statusline", or runs /claude-code-optimization:statusline-install. Renders
  four rows above the prompt: directory + git branch, session name,
  model + effort + context bar, and rate limits + clock + diff stats.
  Patches ~/.claude/settings.json — preserves all other keys.
user-invocable: true
---

# Statusline Install

This plugin ships a custom multi-line statusline at `${CLAUDE_PLUGIN_ROOT}/statusline-export/`. This skill helps the user install, verify, customize, or remove it.

## Prerequisites (verify before installing)

- **PowerShell 7+** (`pwsh`) — the installer uses `ConvertFrom-Json -AsHashtable`, which is PS 7+ only.
- **Claude Code** installed — the installer creates `~/.claude/` if missing.
- **Terminal with ANSI + UTF-8 support** (Windows Terminal, modern PowerShell hosts).

Check with:

```powershell
pwsh --version
```

If `pwsh` is missing or `$PSVersionTable.PSVersion.Major` is < 7, stop and tell the user to install PowerShell 7+ before continuing.

## Step 1: Confirm the user wants to install

Show what will change before running anything destructive:

> The installer will:
> 1. Create `~/.claude/` if missing.
> 2. Copy `statusline-command.ps1` into `~/.claude/statusline-command.ps1`.
> 3. Patch `~/.claude/settings.json` — replace **only** the `statusLine` block. All other keys are preserved.
>
> If you already have a custom statusline configured in settings.json, this will overwrite the `statusLine` block (settings.json is otherwise untouched).

Get explicit confirmation before running the installer.

## Step 2: Run the installer

```powershell
pwsh -NoProfile -File ${CLAUDE_PLUGIN_ROOT}/statusline-export/install.ps1
```

Custom install location (testing or non-default Claude layout):

```powershell
pwsh -NoProfile -File ${CLAUDE_PLUGIN_ROOT}/statusline-export/install.ps1 -ClaudeDir C:/some/.claude
```

The installer prints the destination paths and the resulting `statusLine` JSON block on success.

## Step 3: Verify

Restart Claude Code, then check that four colored rows render above the prompt input:

```
◐ <cwd>



<session-name> | (main wt:experiment)



Opus 4.7 | effort:high | think:on |  ▓▓▓▓░░░░░░ 42%



5hr:6% | 7d:1% | 23:37 | +120 -34
```

Pre-call (before the first message), the context bar and rate-limit fields stay empty; the clock line still renders so line 4 is never blank.

To exercise the script directly without launching Claude (sanity check):

```powershell
'{"workspace":{"current_dir":"C:/tmp"},"model":{"display_name":"Opus 4.7"},"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":6},"seven_day":{"used_percentage":1}},"cost":{"total_lines_added":120,"total_lines_removed":34}}' | pwsh -NoProfile -File ~/.claude/statusline-command.ps1
```

Expect four colored lines separated by blank lines.

## Layout reference

| Line | Segments (left → right) |
| ---- | ----------------------- |
| 1 | spinner · cwd · `+N dirs` |
| 2 | session name · git branch (or `(branch wt:worktree)` in a linked worktree) — hidden when both are empty |
| 3 | model · `effort:<level>` · `think:on` · context bar `▓▓▓▓░░░░░░ N%` (light-grey background) |
| 4 | `5hr:N%` · `7d:N%` · clock `HH:MM` · `+X -Y` diff stats |

Every segment drops silently when its field isn't present in the JSON Claude Code sends.

## Customize

Edit `~/.claude/statusline-command.ps1` directly, or edit `${CLAUDE_PLUGIN_ROOT}/statusline-export/statusline-command.ps1` and re-run the installer.

- **Colors** — ANSI block under `# ANSI colors`.
- **Layout** — the `Line 1` / `Line 2` / `Line 3` / `Line 4` assembly sections at the bottom.
- **Padding** — the print loop's `Write-Host ""` controls blank lines between rows.
- **Spinner frames** — `$spinFrames = @('◐','◓','◑','◒')`.
- **Refresh rate** — `refreshInterval` in `~/.claude/settings.json` `statusLine` block (`1` = animate spinner at 1 Hz; remove for refresh-on-message-only).

Changes take effect on the next refresh.

## Uninstall

1. Delete `~/.claude/statusline-command.ps1`.
2. Remove the `statusLine` block from `~/.claude/settings.json` (leave the rest of the file alone).

Claude Code falls back to its default statusline.

## Troubleshooting

**Nothing renders** — terminal may not support ANSI escapes. Try Windows Terminal.

**Garbled characters** — terminal may not be UTF-8. Set `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` in your PowerShell profile, or use Windows Terminal.

**`ConvertFrom-Json: A parameter cannot be found that matches parameter name 'AsHashtable'`** — you're on Windows PowerShell 5.1, not PowerShell 7. Install PowerShell 7+ and use `pwsh`, not `powershell`.

**Installer says it patched settings.json but Claude Code doesn't pick it up** — fully restart Claude Code (not just reload). The `statusLine` config is read at startup.
