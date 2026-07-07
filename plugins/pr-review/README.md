# pr-review

AI pull-request reviews for GitHub. **Beta (0.x).**

## Usage

```
/pr-review <pr url | number>   review a PR
/pr-review                     pick from the open-PR list
/pr-review push <pr>           push an edited report as inline PR comments
```

`/pr-review <pr>` fetches the PR via the `gh` CLI and reviews the diff for **correctness bugs**, **security issues**, and **performance** problems (style nits are out of scope). Findings carry a severity: `critical`, `major`, or `minor`. Findings are collected in batches of five — at each batch boundary the command asks whether to continue (+5, +10, custom, or stop), so a huge diff never produces an unbounded review. It then asks how to handle them:

- **Fix plan (plan-md)** — seeds `/plan-md` with the findings and interviews you into an executable fix plan (requires the `plan-md` plugin).
- **Local report** — writes `reviews/pr-<number>.review.md` (the `reviews/` folder is kept gitignored).
- **Report + push to PR** — writes the same report; you edit or delete finding sections, then `/pr-review push <number>` submits the survivors as one GitHub review (event `COMMENT`) with inline comments. Findings on lines outside the diff are folded into the review body.

A clean PR (zero findings) is reported as such — no file, no questions.

## Requirements

- `gh` CLI, authenticated (`gh auth login`), for GitHub PRs.
- Non-GitHub remotes (GitLab, Bitbucket) are not supported yet; the command offers a git-only branch-diff review (local report only) instead.
