---
name: review
description: "Branch of /plan-md: address claude: feedback comments in a plan (subcommand review). Internal: loaded by the plan-md command; not a standalone task."
---

# plan-md review

Load skill `plan-md:migrate` and run the legacy DONE migration first, so completed plans are normalized into `plans/done/` before name resolution.

Parse the plan name from the argument. The argument may be empty (when user types `/plan-md review` with no id), a 3-character id, or a full name. Handle all three:
- Empty argument: Auto-select logic kicks in (see below).
- 3-character id or full name: Resolve per the dispatcher's id-lookup rule.

If the argument is empty (user typed `/plan-md review` with no plan id):
- If there is exactly one plan in `plans/`, use that one.
- If there are multiple plans in `plans/`, list them (full filename format) and ask the user which one to review via `AskUserQuestion`.
- If there are no plans in `plans/`, tell the user "No plans found in plans/." and stop.

Once the target plan is identified:

1. Read the `plans/<name>.plan.md` file.
2. If a `CLAUDE.md` file exists in the working directory, read it and follow its guidelines when addressing feedback (ensure updates respect project conventions and constraints).
3. Search for all comments prefixed with `claude:` (e.g., lines containing `claude: this step should also handle edge case X`).
4. For each `claude:` comment found, address the feedback by updating the relevant section of the plan.
5. Remove the `claude:` comments after addressing them.
6. Write the updated plan back to the same file.
7. **DO NOT implement any code changes.** Only update the plan.

After updating, tell the user what changed and remind them they can add more `claude:` comments or run `/plan-md execute <name>` when ready.
