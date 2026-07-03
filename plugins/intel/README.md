# intel

A Claude Code plugin that manages a project **intelligence layer**: `CLAUDE.md` as a pure index of `If <trigger> → read intelligence/<topic>.md` rules, with the actual conventions, commands, and gotchas living in short, topic-focused files under `intelligence/`. Agents load only the context a task needs instead of one giant knowledge dump.

## Install

Add the [claude-plugins](https://github.com/igarcez/claude-plugins) marketplace, then install:

```
/plugin marketplace add igarcez/claude-plugins
/plugin install intel@igarcez
```

## Usage

| Command | What it does |
|---------|--------------|
| `/intel setup` | Bootstrap the layer: harvest existing docs (`CLAUDE.md`, `AGENTS.md`, cursor rules, READMEs, verbose code comments), verify every rule against current code, write `intelligence/*.md`, rewrite `CLAUDE.md` as an index. Also migrates a knowledge-dump `CLAUDE.md` in an already-started layer. |
| `/intel add <topic>` | Interview → verify → write a new `intelligence/<topic>.md` + index bullet. `add <topic>/<sub>` adds a sub-file under a hub. |
| `/intel maintain` | Full audit: index ↔ files consistency, preamble drift, per-file accuracy (commands/paths/citations re-verified), split/merge of over-broad or decayed files, coverage gaps from recent git history. |

The command is a thin dispatcher: each subcommand's full instructions load on demand as a skill (`intel:setup`, `intel:add`, `intel:maintain`, plus the shared `intel:shape` reference), so only the relevant branch occupies context.

## Auto-loading hook (ships with the plugin)

Installing the plugin registers a `UserPromptSubmit` hook (`hooks/intel-haiku.sh`) — no settings edits needed. On every prompt in a project whose root has a `CLAUDE.md`, it:

1. Injects the `CLAUDE.md` index as context.
2. Asks a headless Haiku subagent (`claude -p --model haiku`, subscription auth — no API key) which `intelligence/*.md` files match the prompt, feeding referenced plan files (`plans/<id>-*.plan.md`, 3-char plan-md ids or legacy numeric) as evidence. Hub files' indexes are included in the selector input, so nested sub-files (any depth) are selected and injected directly — not just the hub.
3. Injects the selected intel files in full.

Fail-safe by design: silently degrades to index-only (or to nothing) when `jq`, the `claude` CLI, or `CLAUDE.md` is absent, and a sentinel env var stops the child `claude -p` from re-firing the hook. Disable/uninstall the plugin and the hook is gone.

## Key conventions it enforces

- **Index-only `CLAUDE.md`** — a fixed preamble plus one `If <trigger>` bullet per topic file; no prose rules in the index itself.
- **Tight topic files** — 30–120 lines, imperative rules, `## Commands` tables, split into hub + sub-files when a topic grows too broad.
- **Greppable citations** — code references anchor on symbols or exact quoted strings, never bare line numbers.
- **Verified content only** — every command, path, and constant is checked against the current code before it is written or kept.

Pairs well with `plan-md@igarcez`: plan execution captures recurring "plan gaps" into the intelligence layer via `/intel`.
