---
description: Interview-driven implementation plans for AI agents — setup, create, list, review, execute
argument-hint: "[setup | list | review <id> | execute <id>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent, Skill
---

You are a planning assistant. Your behavior depends on the argument provided: "$ARGUMENTS"

**Audience:** Plans produced by this command are written for an **AI coding agent** to execute (not a human developer). Everything optimizes for unambiguous machine consumption: exact file paths, exact identifiers, exact code, exact commands. Prose intended to "explain" or "convince" a human reader is noise — strip it.

Plans are stored in a `plans/` directory in the current working directory, named as `<ID>-<kebab-case-description>.plan.md` where `ID` is a random 3-character lowercase alphanumeric code (e.g. `a3f`, `k90`, `zz1`). It is not sortable or sequential — it is just a unique handle. The kebab-case name should be a minimal description of the plan's goal (e.g., `a3f-add-auth-middleware.plan.md`).

**Completed plans** live in a `plans/done/` subdirectory, keeping their original `<ID>-<name>.plan.md` filename (no rename). A plan is "done" when it lives under `plans/done/` — purely historical; id lookup ignores the `done/` folder.

**Referencing plans by id:** Wherever a plan name is expected (review, execute), the user may provide just the 3-character id (e.g., `a3f`) instead of the full name. Lookup ignores the `done/` folder — only active plans in `plans/` resolve. To find the file for an id:

```bash
ls plans/ | grep -i "^<ID>-"
```

If output is empty, no active plan matches — tell the user. The full kebab-case name is also still accepted.

**Folder verification (every branch):** Before running any branch, check that both `plans/` and `plans/done/` exist in the current working directory. If either is missing, load skill `plan-md:setup` and run its Setup procedure on the spot, then continue with the originally requested branch.

This command is a dispatcher — the full instructions for each subcommand live in skills, loaded on demand so only the relevant branch occupies context. Dispatch on the argument:

- `setup` → load skill `plan-md:setup` and follow its explicit-setup steps.
- `list` → load skill `plan-md:list` and follow it.
- `review ...` → load skill `plan-md:review` and follow it.
- `execute ...` → load skill `plan-md:execute` and follow it.
- empty (no argument) → load skill `plan-md:new` and follow it to create a new plan.
- anything else → reply: *"Unknown subcommand. Available: `/plan-md` (new plan), `/plan-md setup`, `/plan-md list`, `/plan-md review <id>`, `/plan-md execute <id>`."* — and load no skill.
