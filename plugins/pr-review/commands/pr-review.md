---
description: Review a GitHub pull request — plan the fixes, keep a local report, or push inline review comments
argument-hint: "[<pr url | number> | push <pr>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
---

You review pull requests. Your behavior depends on the argument provided: "$ARGUMENTS"

**Shared conventions (apply in every branch):**

- A **PR reference** is either a bare number (`42` or `#42` — strip the `#`) or a GitHub PR URL matching `https://github.com/<owner>/<repo>/pull/<number>` (path segments after the number are ignored). A URL pins the repository: pass `-R <owner>/<repo>` to every `gh` call. A bare number targets the repository of the current working directory.
- **Reports** live at `reviews/pr-<number>.review.md` in the current working directory — one file per PR, overwritten on re-review. The `reviews/` folder must be gitignored (the report skill enforces this).
- **Severities:** `critical` = must fix (broken behavior, exploitable security issue); `major` = should fix (likely bug or real risk); `minor` = worth noting.

This command is a dispatcher — the full instructions for each branch live in skills, loaded on demand so only the relevant branch occupies context. Dispatch on the argument:

- `push <pr>` → load skill `pr-review:push` and follow it, treating the second token as the PR reference.
- any other non-empty argument → load skill `pr-review:review` and follow it, treating the whole argument as the PR reference.
- empty (no argument) → load skill `pr-review:review` and follow it with no PR reference (it prompts with the open-PR list).
