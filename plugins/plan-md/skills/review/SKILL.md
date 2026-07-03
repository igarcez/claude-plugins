---
name: review
description: "Branch of /plan-md: address claude: feedback comments in a plan (subcommand review). Internal: loaded by the plan-md command; not a standalone task."
---

# plan-md review

Load skill `plan-md:migrate` and run the legacy DONE migration first, so completed plans are normalized into `plans/done/` before name resolution.

Parse the plan name from the argument (e.g., `review add-auth-middleware`). The name may or may not include the `.plan.md` suffix — handle both; a bare 3-character id resolves per the dispatcher's id-lookup rule.

If no name is given after "review":
- If there is exactly one plan in `plans/`, use that one.
- If there are multiple plans, list them and ask the user which one to review.
- If there are no plans, tell the user.

Once the target plan is identified:

1. Read the `plans/<name>.plan.md` file.
2. If a `CLAUDE.md` file exists in the working directory, read it and follow its guidelines when addressing feedback (ensure updates respect project conventions and constraints).
3. Search for all comments prefixed with `claude:` (e.g., lines containing `claude: this step should also handle edge case X`).
4. For each `claude:` comment found, address the feedback by updating the relevant section of the plan.
5. Remove the `claude:` comments after addressing them.
6. Write the updated plan back to the same file.
7. **DO NOT implement any code changes.** Only update the plan.

After updating, tell the user what changed and remind them they can add more `claude:` comments or run `/plan-md execute <name>` when ready.
