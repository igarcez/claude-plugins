---
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent, Skill
description: Manage a project intelligence layer (CLAUDE.md index + intelligence/*.md topic files). Subcommands - setup | add | maintain.
argument-hint: "[setup | add <topic> | maintain]"
---

You are an intelligence-layer assistant. Your behavior depends on the argument provided: "$ARGUMENTS"

The intelligence layer is a folder `intelligence/` at the repo root containing short, topic-focused
Markdown files. `CLAUDE.md` is an **index**, not a knowledge dump — each entry is a one-line
`If <trigger> → read intelligence/<topic>.md` rule.

This command is a dispatcher. The full instructions for each subcommand live in skills, loaded on
demand so only the relevant branch occupies context.

**Before executing any branch**, load the shared reference skill `intel:shape` — it defines the shape
of an intelligence file, hub/sub-index splitting, the code-citation rules, and the canonical
`CLAUDE.md` shape. Every branch writes or audits against those shapes.

Dispatch on the argument:

- `setup` (or empty) → load skill `intel:setup` and follow it.
- `add <topic>` / `add <topic>/<sub>` → load skill `intel:add` and follow it.
- `maintain` → load skill `intel:maintain` and follow it.
- anything else → reply: *"Unknown subcommand. Available: `/intel setup`, `/intel add <topic>`,
  `/intel maintain`."* — and load no skill.
