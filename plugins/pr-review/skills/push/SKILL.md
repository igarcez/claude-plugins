---
name: push
description: "Branch of /pr-review: parse an edited local report and submit its findings as one GitHub review with inline comments. Internal: loaded by the pr-review command; not a standalone task."
---

# pr-review — push a report to the PR

## 1. Locate and parse the report

Resolve the PR reference argument to a number (strip `#`; from a URL take the trailing number). Read `reviews/pr-<number>.review.md`.

- File missing → reply: *"No report found for PR #<number>. Run `/pr-review <number>` first."* — and stop.
- Parse the header's `**PR:**` line into `<owner>`, `<repo>`, `<number>` — this is the authoritative target repository (not the cwd remote). If the report has a `**Diff:**` line instead of `**PR:**`, it came from a git-only fallback review and cannot be pushed — say so and stop.
- Parse every `## [<severity>] <title>` section into a finding: severity, title, file (from `**File:**`), line (from `**Line:**`), issue (from `**Issue:**`), suggestion (from `**Suggestion:**`).
- Zero finding sections → reply: *"Report has no findings — nothing to push."* — and stop.

## 2. Preflight gh

Run `gh auth status`. On failure, tell the user what is wrong and how to fix it (install `gh`, or run `gh auth login` — suggest typing `! gh auth login`), then stop.

## 3. Determine anchorable findings

Run `gh pr diff <number> -R <owner>/<repo>` and build the set of (path, new-side line number) pairs present in the diff hunks. A finding is **anchorable** when its file and line are in that set; otherwise it is **off-diff**.

## 4. Submit one review

Show the user what will be pushed: the count of inline comments and the off-diff findings folded into the body. Then write the payload to a scratch file and submit a single review with event `COMMENT` (never approve or request changes):

```json
{
  "event": "COMMENT",
  "body": "AI review via /pr-review — <x> critical, <y> major, <z> minor.\n\n### Other findings\n\n- **[<severity>]** `<file>:<line>` — <issue> Suggestion: <suggestion>",
  "comments": [
    {
      "path": "<file>",
      "line": <line>,
      "side": "RIGHT",
      "body": "**[<severity>] <title>**\n\n<issue>\n\n**Suggestion:** <suggestion>"
    }
  ]
}
```

- One `comments[]` entry per anchorable finding; one `### Other findings` bullet per off-diff finding. Omit the `### Other findings` block when every finding is anchorable. When no finding is anchorable, submit the review with the body only and an empty `comments` array.

```bash
gh api repos/<owner>/<repo>/pulls/<number>/reviews -X POST --input <scratch-file>.json
```

## 5. Report

Tell the user: the submitted review's `html_url`, how many findings went inline, and how many were folded into the review body.
