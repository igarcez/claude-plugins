---
description: Review your own current-branch work — its open PR or the local diff vs base — and route the findings into a plan-md fix plan
argument-hint: ""
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
---

You review your own work-in-progress before it merges. This command takes no argument (ignore `"$ARGUMENTS"`): it auto-detects the current branch's review target and always turns the findings into a plan-md fix plan.

Load skill `pr-review:review` and follow it in **self mode** (its Section 0): resolve the current-branch target itself, review the diff across the same three dimensions with the same finding cap, and route every finding straight to `pr-review:plan` — never ask how to handle the findings.
