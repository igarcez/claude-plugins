# intel

A Claude Code plugin that manages a project **intelligence layer**: `intelligence/index.md` as a pure index of `If <trigger> → read intelligence/<topic>.md` rules, with the actual conventions, commands, and gotchas living in short, topic-focused files under `intelligence/`. `CLAUDE.md` shrinks to a fixed stanza pointing at that index, so agents load only the context a task needs instead of one giant knowledge dump.

## Install

Add the [claude-plugins](https://github.com/igarcez/claude-plugins) marketplace, then install:

```
/plugin marketplace add igarcez/claude-plugins
/plugin install intel@igarcez
```

## Usage

| Command | What it does |
|---------|--------------|
| `/intel setup` | Bootstrap the layer: harvest existing docs (`CLAUDE.md`, `AGENTS.md`, cursor rules, READMEs, verbose code comments), verify every rule against current code, write `intelligence/*.md` + `intelligence/index.md`, reduce `CLAUDE.md` to the pointer stanza. Also migrates a knowledge-dump `CLAUDE.md` in an already-started layer. |
| `/intel add <topic>` | Interview → verify → write a new `intelligence/<topic>.md` + index bullet. `add <topic>/<sub>` writes `intelligence/<topic>/<sub>.md` under the hub `intelligence/<topic>/index.md`, converting a flat topic into a hub when needed. |
| `/intel maintain` | Full audit: index ↔ files consistency, preamble drift, per-file accuracy (commands/paths/citations re-verified), split/merge of over-broad or decayed files, coverage gaps from recent git history. |
| `/intel upgrade` | Detect and apply pending layer migrations (registry in `intel:migrations`): moving a pre-2.0 index out of `CLAUDE.md` into `intelligence/index.md`, and pre-2.0 hubs from `intelligence/<topic>.md` into `intelligence/<topic>/index.md`. Applies immediately, reports what changed. |

Applied migrations are recorded per layer in a ledger on your machine —
`${XDG_STATE_HOME:-~/.local/state}/intel/applied/<repo-path>.txt`, overridable with
`CLAUDE_INTEL_STATE_DIR`. An id in the ledger is never re-run, so migrations that reverse an earlier
layout decision can be added safely. Deleting the ledger is harmless: each migration still has a
detect rule that skips it when the layer is already in the target shape.

The command is a thin dispatcher: each subcommand's full instructions load on demand as a skill (`intel:setup`, `intel:add`, `intel:maintain`, `intel:upgrade`, plus the shared `intel:shape` and `intel:migrations` references), so only the relevant branch occupies context.

## Hooks (ship with the plugin)

Installing the plugin registers both hooks below — no settings edits needed.

### Auto-loading intel (`UserPromptSubmit`, `hooks/intel-haiku.sh`)

On every prompt in a project whose root has an `intelligence/index.md`, it:

1. Injects the `intelligence/index.md` index as context.
2. Asks a headless Haiku subagent (`claude -p --model haiku`, subscription auth — no API key) which `intelligence/*.md` files match the prompt, feeding referenced plan files (`plans/<id>-*.plan.md`, 3-char plan-md ids or legacy numeric) as evidence. Every hub's `index.md` is included in the selector input, so nested sub-files (any depth) are selected and injected directly — not just the hub.
3. Injects the selected intel files in full.

A layer still on the pre-2.0 layout (index inside `CLAUDE.md`, no `intelligence/index.md`) gets a one-line "run `/intel upgrade`" warning instead of auto-loading. Projects with no layer at all get nothing.

Fail-safe by design: silently degrades to index-only (or to nothing) when `jq`, the `claude` CLI, or the index is absent, and a sentinel env var stops the child `claude -p` from re-firing the hook. Disable/uninstall the plugin and the hook is gone.

### End-of-turn capture check (`Stop`, `hooks/intel-capture.sh`)

At the end of every turn in a project that has an `intelligence/index.md`, it injects a one-line self-check: is anything this turn established worth `/intel add`, or did the turn prove an existing `intelligence/*.md` rule wrong? Claude answers with one line or stays silent — so conventions surfaced while working get captured instead of forgotten.

The main model is the judge (it already holds the turn's context), so there is no extra model call and no added latency. It fires at most once per user turn, skips subagent turns, and `CLAUDE_INTEL_CAPTURE=0` disables it while leaving the auto-loading hook running.

## Key conventions it enforces

- **Index-only `intelligence/index.md`** — a fixed preamble plus one `If <trigger>` bullet per topic; no prose rules in the index itself. `CLAUDE.md` keeps only the pointer stanza, and any user content it already had is preserved.
- **Tight topic files** — 30–120 lines, imperative rules, `## Commands` tables, split into `intelligence/<topic>/index.md` + sub-files when a topic grows too broad.
- **Greppable citations** — code references anchor on symbols or exact quoted strings, never bare line numbers.
- **Verified content only** — every command, path, and constant is checked against the current code before it is written or kept.

Pairs well with `plan-md@igarcez`: plan execution captures recurring "plan gaps" into the intelligence layer via `/intel`.
