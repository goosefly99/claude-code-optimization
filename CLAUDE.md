# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a Claude Code skill and companion guide for auditing and optimizing Claude Code context usage (token waste, CLAUDE.md bloat, MCP server overhead, settings, file permissions).

## Structure

```
claude_setup_audit_skill/
  SKILL.md                              — The /context-audit skill definition
  The Claude Code Context Cleanup Guide.md  — Companion guide document
```

## Skill Format

`SKILL.md` uses a YAML frontmatter block followed by Markdown:

```yaml
---
name: <slug>
description: >
  <when to trigger — determines how Claude Code matches user intents>
user-invocable: true
---
```

- `name` must match the folder name and the slash command (e.g., `context-audit` → `/context-audit`)
- `description` drives trigger matching — keep it specific and include example phrases
- Skill body is plain Markdown; Claude follows it as instructions

## Editing Guidelines

- When updating skill logic, ensure the five CLAUDE.md filters (Default, Contradiction, Redundancy, Bandaid, Vague) stay consistent between `SKILL.md` and the Guide document — they are the core shared concept.
- The scoring table in `SKILL.md` Step 3 is the authoritative reference; the Guide is explanatory prose and does not need to replicate exact point values.
- The Guide references an install URL and a cal.com link — do not change these unless the user explicitly provides updated URLs.
