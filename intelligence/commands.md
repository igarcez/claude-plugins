# Commands

Slash commands live at `plugins/<plugin>/commands/<command>.md`. The command name is the filename
(`intel.md` → `/intel`); it is invoked as `/<command> <args>`.

## Frontmatter

```yaml
---
description: <one-line, shown in the command list>
argument-hint: "[setup | add <topic> | maintain]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent, Skill
---
```

- **No `name` field** — the filename is the command name.
- `argument-hint` documents the subcommand grammar surfaced to the user.
- `allowed-tools` is a comma list; include `Skill` when the command loads skills.

## Dispatcher pattern

Both current commands are **thin dispatchers**: the body holds only shared conventions + argument
routing; each subcommand's full instructions live in a skill loaded on demand, so only the relevant
branch occupies context.

- Read the argument via the literal `"$ARGUMENTS"` placeholder in the body.
- Dispatch on the first token; each branch does `load skill \`<plugin>:<sub>\` and follow it`.
- Empty argument routes to a default branch (`intel` → `setup`, `plan-md` → `new`).
- Unknown subcommand: reply with the available-subcommands list and load **no** skill — keep the
  wording *"Unknown subcommand. Available: ..."*.
- Load any shared-reference skill before branching (e.g. `intel:shape`).

## Reference

- `plugins/intel/commands/intel.md`, `plugins/plan-md/commands/plan-md.md` — canonical dispatchers.
