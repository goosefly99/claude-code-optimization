# claude-code-optimization

A Claude Code plugin that helps you cut token waste and dress up your prompt. Two skills:

| Skill | What it does |
| ----- | ------------ |
| `/claude-code-optimization:context-audit` | Audits your Claude Code setup (CLAUDE.md, skills, MCP servers, settings, file permissions) and returns a health score with specific fixes. Starts from real `/context` numbers, so the report reflects what's actually loading. |
| `/claude-code-optimization:statusline-install` | Installs a custom multi-line PowerShell statusline (Windows). Renders four rows above the prompt: directory, session name + git branch, model + effort + context bar, and rate limits + clock + diff stats. Patches `~/.claude/settings.json` non-destructively. |

## Install

Use Claude Code's plugin tooling (`/plugin`) to add this directory as a plugin source. Exact invocation depends on your Claude Code version — see the [plugin docs](https://docs.claude.com/en/docs/claude-code) for the current install commands. Once installed and enabled, Claude Code auto-discovers the two skills under `skills/`.

## Quick start

After installing, run either skill from any session:

```
/claude-code-optimization:context-audit
/claude-code-optimization:statusline-install
```

You can also just describe what you want — Claude will trigger the right skill from the descriptions:

- "Audit my context" / "Why is Claude so slow?" / "Token optimization" → `context-audit`
- "Install the statusline" / "Set up the statusline" → `statusline-install`

## Components

```
claude-code-optimization/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── context-audit/
│   │   └── SKILL.md
│   └── statusline-install/
│       └── SKILL.md
├── statusline-export/             # PowerShell statusline assets
│   ├── INSTALL.md                  # Standalone (non-plugin) install guide
│   ├── install.ps1                 # Installer the skill invokes
│   └── statusline-command.ps1      # The statusline runtime script
├── CLAUDE.md
└── README.md
```

## Statusline preview

```
◐ C:/Users/olive/claude_projects



my-feature | (main wt:experiment)



Opus 4.7 | effort:high | think:on |  ▓▓▓▓░░░░░░ 42%



5hr:6% | 7d:1% | 23:37 | +120 -34
```

Every segment drops silently when its field isn't present in the JSON Claude Code sends.

## Prerequisites

- **Claude Code** (any platform) — for the `context-audit` skill.
- **PowerShell 7+** (`pwsh`) on Windows — for `statusline-install` only. The installer uses `ConvertFrom-Json -AsHashtable`, which is PS 7+.
- **Terminal with ANSI + UTF-8 support** — Windows Terminal recommended for the statusline.

## Standalone statusline install (no plugin)

If you just want the statusline without the plugin, the assets in `statusline-export/` are self-contained. See `statusline-export/INSTALL.md`.

## Uninstall

- Plugin: disable/remove via `/plugin` in Claude Code.
- Statusline: delete `~/.claude/statusline-command.ps1` and remove the `statusLine` block from `~/.claude/settings.json`.
