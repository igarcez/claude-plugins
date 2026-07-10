---
name: plan
description: "Branch of /pr-review: hand the review findings to plan-md:new as a seeded fix plan. Internal: loaded by the pr-review command; not a standalone task."
---

# pr-review — create a fix plan from findings

1. Invoke the `Skill` tool with skill `plan-md:new` and args: `Fix the findings from the PR review of PR #<number> (<PR url>): <semicolon-separated list of "[severity] title — file:line">`. Follow the loaded skill — it interviews the user and writes the plan. Carry every finding's issue and suggestion into that planning conversation as established context.
2. If the `Skill` invocation fails because `plan-md:new` is unavailable, tell the user the plan-md plugin is required (`/plugin install plan-md@igarcez`) and ask with `AskUserQuestion` ("plan-md is not installed — write the local report instead?"): **Local report** → load skill `pr-review:report` and follow it; **Stop** → end.
