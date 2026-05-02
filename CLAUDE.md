# CLAUDE.md

Guidance for working on this repository in Claude Code.

## Project Overview

This repository **is** a Claude Code plugin: `claude-code-optimization`. It bundles two user-invocable skills for cutting token waste and customizing the Claude Code prompt.

- `context-audit` — audits CLAUDE.md, skills, MCP servers, settings, and file permissions; returns a health score.
- `statusline-install` — installs a custom multi-line PowerShell statusline (Windows-only).

See `README.md` for end-user documentation.

## Plugin Layout

```
.claude-plugin/
  plugin.json                  — Plugin manifest (name, version, author, etc.)
skills/
  context-audit/SKILL.md        — Audit skill (auto-loaded by trigger phrases or slash command)
  statusline-install/SKILL.md   — Statusline installer skill
statusline-export/              — Statusline runtime assets referenced by the install skill
  INSTALL.md                    — Standalone (non-plugin) install guide
  install.ps1                   — Installer script (patches ~/.claude/settings.json)
  statusline-command.ps1        — Runtime: reads JSON from stdin, writes ANSI lines
README.md                       — Plugin overview and install instructions
```

Inside skill bodies, reference plugin assets with `${CLAUDE_PLUGIN_ROOT}` — e.g., `${CLAUDE_PLUGIN_ROOT}/statusline-export/install.ps1`. Never hardcode absolute or user-home paths.

## Skill Format

```yaml
---
name: <slug>                    # must match the directory name under skills/
description: >
  <triggering phrases and what the skill does — drives intent matching>
user-invocable: true             # exposes the skill as /<plugin-name>:<slug>
---
```

- `name` must match the folder name. Slash command is `/claude-code-optimization:<name>`.
- `description` drives trigger matching — keep it specific, include real phrases users say.
- Skill body is plain Markdown; Claude follows it as instructions.
- Use imperative form ("Run `pwsh ...`", not "you may want to run").

## Editing Guidelines

- The five CLAUDE.md filters (Default, Contradiction, Redundancy, Bandaid, Vague) are the core shared concept of the `context-audit` skill — keep them consistent if referenced elsewhere.
- The scoring table in `skills/context-audit/SKILL.md` Step 3 is the authoritative reference for point values.
- When changing the statusline output format, update the layout reference table in **both** `skills/statusline-install/SKILL.md` and `statusline-export/INSTALL.md` — and the preview in `README.md`.
- When changing the slash command name (`name` in skill frontmatter), grep for the literal string everywhere — README, statusline-install skill, and any cross-references.
- If you change `plugin.json` `name`, the slash command prefix changes too. Update every `/claude-code-optimization:` reference.

## Verification

There's no test suite or build step. After edits:

1. `git diff` — review the change.
2. For skill changes: re-load the plugin in a Claude Code session and trigger the skill to confirm it activates and runs end-to-end.
3. For statusline edits: pipe sample JSON into `statusline-command.ps1` and check the rendered output (sample command in `skills/statusline-install/SKILL.md` Step 3).
4. For `plugin.json` edits: confirm valid JSON (`pwsh -c "Get-Content .claude-plugin/plugin.json | ConvertFrom-Json"`).
