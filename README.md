# plan-md

A Claude Code plugin for interview-driven implementation plans written for **AI coding agents** — not humans. `/plan-md` interrogates you until every design decision is closed, then writes a plan an agent can execute cold: exact paths, exact identifiers, exact code, exact commands.

## Install

Add this repo as a marketplace, then install the plugin:

```
/plugin marketplace add igarcez/plan-md
/plugin install plan-md@plan-md
```

(The full git URL `https://github.com/igarcez/plan-md` or a local path also works with `/plugin marketplace add`.)

## Usage

| Command | What it does |
|---------|--------------|
| `/plan-md` | Interview → write a new plan to `plans/<id>-<name>.plan.md` |
| `/plan-md setup` | Create `plans/` + `plans/done/` and settle whether plans are committed or gitignored |
| `/plan-md list` | List active and completed plans with ids and goals |
| `/plan-md review <id>` | Address `claude:` feedback comments left in a plan |
| `/plan-md execute <id>` | Execute a plan step by step, tracking plan gaps |

Plans are referenced by a random 3-character id (e.g. `a3f`) or full name. Completed plans move to `plans/done/`.

`setup` is optional: every other subcommand verifies the folder structure first and runs the setup steps on the spot when `plans/` or `plans/done/` is missing — including asking once whether the `plans/` directory should be committed to the repo or added to `.gitignore`.

## Repo layout

```
.claude-plugin/
  plugin.json        plugin manifest
  marketplace.json   this repo doubles as its own marketplace
commands/
  plan-md.md         the /plan-md command
skills/
  php/SKILL.md         stack rules, loaded as skill plan-md:php
  typescript/SKILL.md  stack rules, loaded as skill plan-md:typescript
```

## Adding a language

1. Create `skills/<lang>/SKILL.md` (frontmatter `name: <lang>`, body = the stack's plan-writing rules; state the activation condition on the first lines).
2. Add a detection bullet for the stack in `commands/plan-md.md` §3 ("Detect project stack & load language rules").
