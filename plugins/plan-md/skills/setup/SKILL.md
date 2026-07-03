---
name: setup
description: "Branch of /plan-md: create the plans/ folder structure and settle git tracking (subcommand setup, also run by folder verification). Internal: loaded by the plan-md command; not a standalone task."
---

# plan-md setup

## Setup procedure (run by the `setup` branch and by folder verification)

1. **Create the structure:** run `mkdir -p plans/done`. Note first whether `plans/` existed beforehand — the git decision below depends on it.
2. **Git tracking decision.** Only applies when the current working directory is inside a git work tree (`git rev-parse --is-inside-work-tree` exits 0). If not a git repo, skip this step entirely.
   - **Already decided — skip the question** when either is true:
     - `git check-ignore -q plans` exits 0 → plans are already gitignored.
     - `git ls-files plans | head -1` prints a path → plans are already tracked.
   - **Ask-once rule:** when this procedure runs via folder verification (not an explicit `/plan-md setup`), ask the question only if `plans/` itself was missing in step 1. If `plans/` already existed and only `done/` was missing, create the folder silently and skip the question. An explicit `/plan-md setup` always evaluates the decision (but still skips the question when it is already decided per the checks above).
   - **Otherwise ask** with `AskUserQuestion`: "Should plan files be committed to this repository?"
     - **Commit plans** — planning history is shared with the team and plans are reviewable in PRs. Action: create empty `plans/.gitkeep` and `plans/done/.gitkeep` so the structure survives a fresh clone.
     - **Gitignore plans** — plans stay local scratch files, never committed. Action: append a line `plans/` to the `.gitignore` in the current working directory (create the file if it doesn't exist; do not add a duplicate if a `plans/` line is already present).
3. **Report:** state what was created vs. already in place, and the git decision taken (or that it was already decided / not applicable).

## Explicit `/plan-md setup` invocation

1. Run the **Setup procedure** above (always evaluate the git tracking decision, skipping the question only when it is already decided).
2. Load skill `plan-md:migrate` and run the legacy DONE migration so any old-style completed plans are normalized.
3. Report the results of both.
