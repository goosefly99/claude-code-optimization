# claude-code-optimization — Codex guidance

This plugin ships two skills: a context/token-waste auditor (`context-audit`) and a statusline
installer (`statusline-install`). The context-audit skill translates fully to Codex; the statusline
skill is Claude Code on Windows only and has no Codex equivalent.

---

## Context discipline principles

These principles apply whenever you are auditing or improving a Codex (or Claude Code) setup for
context efficiency. They are drawn from the `context-audit` skill and are portable across runtimes.

### Prefer CLI over MCP when both cover a use case

Each active MCP server loads its full tool-definition schema into the model's context window on every
turn — typically 15,000–20,000 tokens per server, whether or not any of its tools are called. When
a task can be accomplished with a CLI tool instead (for example, `gh` for GitHub operations,
`playwright` CLI for browser automation, `gcloud` or `gsutil` for Google Cloud), the CLI is
preferred: it costs zero tokens while idle and the same or fewer tokens during a call. Register an
MCP server only when it provides capabilities the CLI cannot cover.

### Add deny rules for build-artifact directories before scanning

Build output and dependency trees generate enormous file counts that serve no purpose in an agent's
context. Before scanning a project tree or reading file lists, check whether deny rules are in place
for the relevant artifact directories:

| Project indicator | Directories to deny |
|---|---|
| `package.json` | `node_modules`, `dist`, `build`, `.next`, `coverage` |
| `Cargo.toml` | `target` |
| `go.mod` | `vendor` |
| `pyproject.toml` / `requirements.txt` | `__pycache__`, `.venv`, `*.egg-info` |

If no deny rules exist and these directories are present, recommend adding them to the agent
configuration's deny list before proceeding with any scan-heavy task.

### Apply progressive disclosure to instruction files larger than 200 lines

A single large instruction file loaded unconditionally on every turn is wasteful when most of its
rules only apply to specific task types. When a CLAUDE.md (or equivalent instruction file) exceeds
200 lines, audit whether any sections are task-specific — API conventions, deployment procedures,
testing guidelines, tool-specific patterns. Rules that only matter during certain tasks should be
moved to dedicated reference files and replaced with a single pointer line in the main file. The
main file should contain only universal context: identity, workflow defaults, invariants that apply
to every session. Do not split a lean file for its own sake; split only when the file is measurably
bloated.

### Autocompact and output buffer defaults

Two settings reduce context bloat without human intervention and should be present in every setup:

- `autocompact_percentage_override`: 75 (fires compaction before the window fills, preserving
  headroom for the model's own output).
- `BASH_MAX_OUTPUT_LENGTH`: 150000 (raises the default 30–50K shell output cap so tool results are
  not silently truncated, which causes agents to misread command results).

If either setting is missing, recommend adding it before beginning long or multi-step tasks.

---

## Statusline

The `statusline-install` skill sets up a custom multi-line PowerShell statusline for Claude Code on
Windows. It requires PowerShell 7+, a ANSI/UTF-8 terminal, and patches `~/.claude/settings.json`.
This skill is Claude Code on Windows only — there is no Codex equivalent.
