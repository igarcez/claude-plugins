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

- **The command name comes from the filename** — the frontmatter fields are `description`,
  `argument-hint`, and `allowed-tools`.
- `argument-hint` documents the subcommand grammar surfaced to the user.
- `allowed-tools` is a comma list; include `Skill` when the command loads skills.

## Dispatcher pattern

Commands are either **thin dispatchers** (`intel`, `plan-md`, `pr-review`) — the body holds only shared conventions + argument routing; each subcommand's full instructions live in a skill loaded on demand, so only the relevant branch occupies context — or **single-file commands** (`merge`) that hold all instructions inline.

For dispatchers:

- Read the argument via the literal `"$ARGUMENTS"` placeholder in the body.
- Dispatch on the first token; each branch does `load skill \`<plugin>:<sub>\` and follow it`.
- Empty argument routes to a default branch (`intel` → `setup`, `plan-md` → `new`).
- Unknown subcommand: reply with the available-subcommands list **only** — keep the
  wording *"Unknown subcommand. Available: ..."*.
- Load any shared-reference skill before branching (e.g. `intel:shape`).

## Reference

- `plugins/intel/commands/intel.md`, `plugins/plan-md/commands/plan-md.md`,
  `plugins/pr-review/commands/pr-review.md` — canonical dispatchers.
- `plugins/merge/commands/merge.md` — canonical single-file command.
