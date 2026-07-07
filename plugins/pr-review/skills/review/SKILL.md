---
name: review
description: "Branch of /pr-review: validate the PR reference, fetch and review the diff, then route to the chosen handling mode (plan / report / push). Internal: loaded by the pr-review command; not a standalone task."
---

# pr-review — review a pull request

## 1. Preflight: provider and tooling

Detect the hosting provider: run `git remote get-url origin`. URL contains `github.com` → GitHub; contains `gitlab` → GitLab; contains `bitbucket` → Bitbucket; anything else → unknown.

- **GitHub:** run `gh auth status`. If the binary is missing or unauthenticated, tell the user what is wrong and how to fix it (install `gh`, or run `gh auth login` — suggest typing `! gh auth login` to run it in-session), then offer the **git-only fallback** below.
- **GitLab / Bitbucket / unknown:** name the provider and the tooling this command would need (GitLab → `glab`, not yet supported; Bitbucket → Bitbucket REST API, not yet supported), then offer the **git-only fallback** below.

**Git-only fallback.** Ask with `AskUserQuestion`: "PR access via gh is unavailable — run a git-only local review instead?" with options **Git-only review** / **Stop**. If Stop, end. If Git-only review:

1. Ask the user (one `AskUserQuestion`, two questions) for the **source branch** and the **base branch** of the change.
2. Run `git fetch origin <base> <source>`, then take the diff from `git diff origin/<base>...origin/<source>`.
3. Continue from section 4 (Review) using this diff. In fallback mode there is no PR number: the report filename is `reviews/<source>.review.md` with every `/` in the branch name replaced by `-`, and the report's `**PR:**` line is replaced by `- **Diff:** <base>...<source>`. Only the *Fix plan* and *Local report* handling modes are offered — state explicitly that push is unavailable without gh.

## 2. Resolve the PR reference

- **Valid reference given** (bare number, `#number`, or GitHub PR URL): use it. From a URL, extract `<owner>/<repo>` and `<number>`; pass `-R <owner>/<repo>` to every `gh` call in this session.
- **No argument, or the argument is not a valid PR reference:** if invalid, first say the argument was not recognized as a PR URL or number. Then run:

  ```bash
  gh pr list --state open --limit 4 --json number,title
  ```

  - Zero open PRs → reply: *"No open PRs found. Usage: `/pr-review <pr url | number>`"* — and stop.
  - Otherwise ask with `AskUserQuestion` ("Which PR should be reviewed?"), one option per PR, label `#<number> <title truncated to fit>`. The user can supply a different URL/number via Other.

## 3. Fetch the PR

```bash
gh pr view <number> --json number,title,url,headRefName,baseRefName,state,body
gh pr diff <number>
```

(Add `-R <owner>/<repo>` to both when the reference was a URL.) If the PR does not exist, report the exact gh error and stop. When a hunk needs surrounding context to judge, fetch the full file at the PR head:

```bash
gh api repos/<owner>/<repo>/contents/<path>?ref=<headRefName> --jq .content | base64 -d
```

## 4. Review the diff

Review only what the diff introduces or touches, across exactly three dimensions:

- **Correctness bugs** — logic errors, broken edge cases, wrong behavior.
- **Security issues** — injection, auth gaps, secrets, unsafe input handling.
- **Performance** — inefficiencies introduced by the diff (N+1 queries, needless loops, blocking calls).

Style and convention nits are out of scope — do not report them. For each finding record: severity (`critical` / `major` / `minor` per the command's definitions), a one-line title, the file path, the line number **on the new side of the diff**, the issue, and a concrete suggestion.

**Finding cap.** Work through the diff file by file. Every time 5 findings accumulate since the last checkpoint, pause and ask with `AskUserQuestion` ("Found <total> findings so far, roughly <percent>% of the diff reviewed — continue?"): **+5 more** / **+10 more** / **Stop here** (Other allows a custom count). On *Stop here*, end the review with the findings collected so far and note in the summary that the review is partial. On a continue option, review until that allowance is exhausted, then ask again. The review also ends naturally when the diff is exhausted, whatever the remaining allowance.

## 5. Route the findings

- **Zero findings:** reply *"PR #<number> is clean — no findings. Nothing to plan, report, or push."* Write no file, ask no question, stop.
- **Findings exist:** print a numbered summary (severity, title, `file:line` each), then ask with `AskUserQuestion` ("How should the findings be handled?", single choice):
  - **Fix plan (plan-md)** → load skill `pr-review:plan` and follow it.
  - **Local report** → load skill `pr-review:report` and follow it.
  - **Report + push to PR** → load skill `pr-review:report` and follow it; afterwards tell the user: *"Review `reviews/pr-<number>.review.md` — edit or delete any finding section to change what gets pushed — then run `/pr-review push <number>`."* (Omit this option in git-only fallback mode.)
