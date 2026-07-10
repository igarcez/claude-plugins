---
allowed-tools: Read, Edit, Bash, Glob, Grep, AskUserQuestion
description: Merge a branch into the current branch, resolving any conflicts. Defaults to the remote default branch.
argument-hint: "[branch]"
---

Merge a branch into the current branch, resolving any conflicts. Argument: "$ARGUMENTS"

## Steps

1. **Determine target branch:**
   - If an argument was provided (non-empty), use it as the target branch
   - Otherwise, detect the default branch by running:
     ```bash
     git remote show origin | grep 'HEAD branch' | awk '{print $NF}'
     ```
   - If that fails, check which of `main`, `master`, or `develop` exists locally and pick the first match

2. **Fetch latest from remote:**
   ```bash
   git fetch origin <target_branch>
   ```

3. **Attempt the merge:**
   ```bash
   git merge origin/<target_branch>
   ```

4. **If merge succeeds with no conflicts:** Report success and stop.

5. **If merge conflicts occur:**
   - Run `git diff --name-only --diff-filter=U` to list conflicted files
   - For each conflicted file:
     - Read the file and understand both sides of the conflict
     - Analyze the intent of each change using git log context if needed
     - Resolve the conflict by combining both changes correctly, preserving the intent of both sides
     - If a conflict is ambiguous or risky (e.g., both sides changed the same logic in incompatible ways), ask the user before resolving
   - After resolving all files, stage them with `git add` and complete the merge with `git commit` (use the default merge commit message)

6. **Post-merge verification:**
   - Run `git status` to confirm clean working tree
   - Report which branch was merged and how many conflicts (if any) were resolved
