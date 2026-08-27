---
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent, Skill
description: Manage a project intelligence layer (intelligence/index.md + intelligence/*.md topic files). Subcommands - setup | add | maintain | upgrade.
argument-hint: "[setup | add <topic> | maintain | upgrade]"
---

You are an intelligence-layer assistant. Your behavior depends on the argument provided: "$ARGUMENTS"

The intelligence layer is a folder `intelligence/` at the repo root containing short, topic-focused
Markdown files. `intelligence/index.md` is the **index** — each entry is a one-line
`If <trigger> → read intelligence/<topic>.md` rule; a topic that grew into a hub is indexed by its own
`intelligence/<topic>/index.md`. `CLAUDE.local.md` holds a fixed stanza pointing at the root index —
a layer bootstrapped before 3.0.0 keeps that stanza in `CLAUDE.md` — plus whatever unrelated content
the user keeps there.

This command is a dispatcher. The full instructions for each subcommand live in skills, loaded on
demand so only the relevant branch occupies context.

**Before executing any branch**, load the shared reference skill `intel:shape` — it defines the shape
of an intelligence file, hub/sub-index splitting, the code-citation rules, and the canonical
`intelligence/index.md` and pointer-stanza file shapes. Every branch writes or audits against those
shapes.

Dispatch on the argument:

- `setup` (or empty) → load skill `intel:setup` and follow it.
- `add <topic>` / `add <topic>/<sub>` → load skill `intel:add` and follow it.
- `maintain` → load skill `intel:maintain` and follow it.
- `upgrade` → load skill `intel:upgrade` and follow it.
- anything else → reply: *"Unknown subcommand. Available: `/intel setup`, `/intel add <topic>`,
  `/intel maintain`, `/intel upgrade`."* — and load no skill.
