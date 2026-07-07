# claude-plugins

Ian Garcez's Claude Code plugin marketplace.

## Install

```
/plugin marketplace add igarcez/claude-plugins
/plugin install <plugin>@igarcez
```

## Plugins

| Plugin | Description |
|--------|-------------|
| [plan-md](plugins/plan-md/) | Interview-driven implementation plans written for AI coding agents — `/plan-md` interrogates you until every design decision is closed, then writes a plan an agent can execute cold. |
| [intel](plugins/intel/) | Project intelligence layer manager — `/intel` bootstraps, extends, and audits a `CLAUDE.md` index + `intelligence/*.md` topic files so agents load only the context a task needs. |
| [merge](plugins/merge/) | Conflict-resolving merges — `/merge [branch]` fetches and merges a branch (default: the remote default branch) into the current one, resolving conflicts by intent and asking only when a conflict is genuinely ambiguous. |
| [pr-review](plugins/pr-review/) | AI pull-request reviews (beta) — `/pr-review <pr>` reviews a GitHub PR for correctness, security, and performance findings, then plans the fixes via plan-md, keeps a local report, or pushes them as inline review comments with `/pr-review push <pr>`. |

The two pair well: `/plan-md execute` captures recurring plan gaps into the intelligence layer via `/intel`.

## Repo layout

```
.claude-plugin/marketplace.json    marketplace manifest
plugins/<name>/                    one directory per plugin
  .claude-plugin/plugin.json
  commands/                        slash commands
  skills/                          skills (if any)
  README.md
```

Each plugin's README documents its usage. To add a plugin: create `plugins/<name>/` with a `plugin.json`, then register it in `.claude-plugin/marketplace.json`.
