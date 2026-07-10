---
name: report
description: "Branch of /pr-review: write the structured local review report and ensure reviews/ is gitignored. Internal: loaded by the pr-review command; not a standalone task."
---

# pr-review — write the local report

## 1. Write the report file

Get today's date with `date +%Y-%m-%d`. Write `reviews/pr-<number>.review.md` (git-only fallback: `reviews/<source-branch with / replaced by ->.review.md`), overwriting any previous report for the same PR, in exactly this structure — one `##` section per finding, ordered critical → major → minor:

```markdown
# PR Review: #<number> — <PR title>

- **PR:** <PR url>
- **Branch:** <headRefName>
- **Reviewed:** <YYYY-MM-DD>
- **Verdict:** <x> critical, <y> major, <z> minor
- **Coverage:** <"full diff" | "partial — stopped after <total> findings at ~<percent>% of the diff">


## [<severity>] <finding title>
- **File:** `<path>`
- **Line:** <line on the new side of the diff>
- **Issue:** <what is wrong>
- **Suggestion:** <concrete fix>
```

In git-only fallback mode replace the `**PR:**` line with `- **Diff:** <base>...<source>` and the `**Branch:**` value with the source branch.

## 2. Ensure reviews/ is gitignored

Skip this section entirely when the working directory is not inside a git work tree (`git rev-parse --is-inside-work-tree` fails).

1. `git check-ignore -q reviews` exits 0 → already ignored, done.
2. Otherwise, if `.gitignore` exists in the working directory → append a line `reviews/` (do not add a duplicate if a `reviews/` line is already present).
3. Otherwise (no `.gitignore`) → ask with `AskUserQuestion` ("No .gitignore in this repo — create one with a `reviews/` entry?"): **Create** → write `.gitignore` containing the single line `reviews/`; **Skip** → warn that the report will show up as an untracked file.

## 3. Report

Tell the user the report path and the finding counts by severity.
