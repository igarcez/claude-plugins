---
name: list
description: "Branch of /plan-md: list active and completed plans (subcommand list). Internal: loaded by the plan-md command; not a standalone task."
---

# plan-md list

1. Load skill `plan-md:migrate` and run the legacy DONE migration first, so any old-style completed plans are already in `plans/done/`.
2. List all active `*.plan.md` files in `plans/` AND all completed `*.plan.md` files in `plans/done/`.
3. For each plan, show its **id**, name, and the `## Goal` section content. Format: `[ID] <name> — <goal>`. Completed plans (those under `plans/done/`) display as `[ID] [DONE] <name> — <goal>`.
4. If no plans exist in either location, tell the user.
5. Remind the user they can reference plans by id, e.g., `/plan-md review a3f` or `/plan-md execute k90`.
