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
| `/intel add <topic>` | Interview → verify → write a new `intelligence/<topic>.md` + index bullet, routing the topic to the project-shared or machine-local layer automatically (asking only when genuinely ambiguous). `add <topic>/<sub>` writes `intelligence/<topic>/<sub>.md` under the hub `intelligence/<topic>/index.md`, converting a flat topic into a hub when needed; `add local/<topic>` forces the machine-local layer. |
| `/intel maintain` | Full audit: index ↔ files consistency, preamble drift, per-file accuracy (commands/paths/citations re-verified), split/merge of over-broad or decayed files, coverage gaps from recent git history. |
| `/intel upgrade` | Detect and apply pending layer migrations (registry in `intel:migrations`): moving a pre-2.0 index out of `CLAUDE.md` into `intelligence/index.md`, and pre-2.0 hubs from `intelligence/<topic>.md` into `intelligence/<topic>/index.md`, re-basing the relative links each move invalidates. Applies immediately, reports what changed. |

Applied migrations are recorded per layer in a ledger on your machine —
`${XDG_STATE_HOME:-~/.local/state}/intel/applied/<repo-path>.txt`, overridable with
`CLAUDE_INTEL_STATE_DIR`. An id in the ledger is never re-run, so migrations that reverse an earlier
layout decision can be added safely. Deleting the ledger is harmless: each migration still has a
detect rule that skips it when the layer is already in the target shape.

The command is a thin dispatcher: each subcommand's full instructions load on demand as a skill (`intel:setup`, `intel:add`, `intel:maintain`, `intel:upgrade`, plus the shared `intel:shape` and `intel:migrations` references), so only the relevant branch occupies context.

## Machine-local intelligence (`intelligence/local/`)

Every layer carries a gitignored `intelligence/local/` hub for rules that are only true on your
machine — your personal plugins and agents, `$HOME` paths, local-only services, workstation tooling.
It has its own `index.md` and follows the same file shape, nesting, and audit rules as the tracked
layer.

- **Always present.** `/intel setup` creates it; migration `M004` adds it (plus the `.gitignore` line
  `intelligence/local/`) to layers bootstrapped before 2.1.0, applied by `/intel upgrade` and by the
  pending-set check that `setup` and `maintain` run.
- **Routed automatically.** `/intel add <topic>` infers the layer from the content and asks only when
  the call is genuinely ambiguous; `/intel add local/<topic>` forces machine-local.
- **Never in the tracked index.** `intelligence/index.md` carries no bullet for it — a committed
  bullet would dangle on every teammate's clone. Discovery is the index preamble's machine-local rule
  plus the auto-loading hook, which injects both indexes on every prompt.
- **Audited too.** `/intel maintain` audits it with the same per-file accuracy checks and reports it
  under its own section, flags tracked rules that look machine-local (and local rules that have become
  project conventions) and offers to move them.
- **Off switch.** `CLAUDE_INTEL_LOCAL=0` stops the hook from loading the local layer without touching
  the tracked one.

## Hooks (ship with the plugin)

Installing the plugin registers both hooks below — no settings edits needed.

### Auto-loading intel (`UserPromptSubmit`, `hooks/intel-haiku.sh`)

On every prompt in a project whose root has an `intelligence/index.md` or an `intelligence/local/index.md`, it:

1. Injects the `intelligence/index.md` index as context, plus `intelligence/local/index.md` when the
   machine-local layer exists. Either index alone is enough for the hook to run.
2. Asks a headless Haiku subagent (`claude -p --model haiku`, subscription auth — no API key) which `intelligence/*.md` files match the prompt, feeding referenced plan files (`plans/<id>-*.plan.md`, word-word plan-md ids like `river-tiger`, plus legacy 3-char and legacy numeric ids) as evidence. Every hub's `index.md` is included in the selector input, so nested sub-files (any depth) are selected and injected directly — not just the hub.
3. Injects the selected intel files in full.

A layer still on the pre-2.0 layout (index inside `CLAUDE.md`, no `intelligence/index.md`) gets a one-line "run `/intel upgrade`" warning instead of auto-loading. Projects with no layer at all get nothing.

Fail-safe by design: silently degrades to index-only (or to nothing) when `jq`, the `claude` CLI, or the index is absent, and a sentinel env var stops the child `claude -p` from re-firing the hook. Disable/uninstall the plugin and the hook is gone.
`CLAUDE_INTEL_LOCAL=0` excludes the machine-local layer from both the injected indexes and the
selector's candidates.

### End-of-turn capture check (`Stop`, `hooks/intel-capture.sh`)

At the end of every turn in a project that has an `intelligence/index.md` or an `intelligence/local/index.md`, it injects a one-line self-check: is anything this turn established worth `/intel add` (project-shared or machine-local), or did the turn prove an existing intelligence rule wrong? Claude answers with one line or stays silent — so conventions surfaced while working get captured instead of forgotten.

The main model is the judge (it already holds the turn's context), so there is no extra model call and no added latency. It fires at most once per user turn, skips subagent turns, and `CLAUDE_INTEL_CAPTURE=0` disables it while leaving the auto-loading hook running.

## Key conventions it enforces

- **Index-only `intelligence/index.md`** — a fixed preamble plus one `If <trigger>` bullet per topic; no prose rules in the index itself. `CLAUDE.md` keeps only the pointer stanza, and any user content it already had is preserved.
- **Tight topic files** — 30–120 lines, imperative rules, `## Commands` tables, split into `intelligence/<topic>/index.md` + sub-files when a topic grows too broad.
- **Greppable citations** — code references anchor on symbols or exact quoted strings, never bare line numbers.
- **Verified content only** — every command, path, and constant is checked against the current code before it is written or kept.

Pairs well with `plan-md@igarcez`: plan execution captures recurring "plan gaps" into the intelligence layer via `/intel`.
