---
name: review
description: "Branch of /pr-review: validate the PR reference, fetch and review the diff, then route to the chosen handling mode (plan / report / push). Internal: loaded by the pr-review command; not a standalone task."
---

# pr-review — review a pull request

## 0. Self mode (only when loaded by `/self-review`)

When this skill is loaded in **self mode**, review the current branch's own work instead of a supplied PR reference. Do sections 1 (preflight) and 4 (review) as written, but replace sections 2–3 with the target resolution below, and in section 5 skip the handling question — always load skill `pr-review:plan`.

**Resolve the target (self mode):**

1. Confirm GitHub + `gh` per section 1. If gh is missing/unauthenticated, or the provider is not GitHub, go straight to the **local-diff self review** below (the current branch is the source — never prompt for a source branch).
2. Get the current branch: `git rev-parse --abbrev-ref HEAD`. If it prints `HEAD` (detached), reply *"Detached HEAD — check out a branch to self-review."* and stop.
3. Look for an open PR for the current branch:

   ```bash
   gh pr view --json number,title,url,headRefName,baseRefName,state
   ```

   - Exits 0 with `"state": "OPEN"` → **PR-mode self review**: use its `number`, then continue exactly as section 3 (`gh pr diff <number>`) and section 4. Report filename and header follow the normal PR rules (`reviews/pr-<number>.review.md`, `**PR:**` line).
   - Non-zero exit (no PR for the branch), or state is not `OPEN` → **local-diff self review** (below).

**Local-diff self review:**

1. Detect the repo default branch, first:

   ```bash
   gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
   ```

   If that fails or prints nothing, fall back to:

   ```bash
   git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's#^origin/##'
   ```

2. If both yield no branch name, ask with `AskUserQuestion` ("Could not detect the base branch — which branch is this change based on?") for the base branch.
3. Let `<base>` be the detected/chosen branch and `<source>` the current branch. Run `git fetch origin <base>`, then diff `git diff origin/<base>...HEAD`. If `origin/<base>` does not exist, diff `git diff <base>...HEAD` instead.
4. If the diff is empty, reply *"No changes on `<source>` vs `<base>` — nothing to review."* and stop.
5. Proceed to section 4 with this diff. The report filename is `reviews/<source with / replaced by ->.review.md` and the header's `**PR:**` line is replaced by `- **Diff:** <base>...<source>` (same as the git-only fallback).

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
- **Findings exist (self mode — section 0):** print the numbered summary (severity, title, `file:line` each), then skip the question below and load skill `pr-review:plan` directly.
- **Findings exist (normal PR review):** print a numbered summary (severity, title, `file:line` each), then ask with `AskUserQuestion` ("How should the findings be handled?", single choice):
  - **Fix plan (plan-md)** → load skill `pr-review:plan` and follow it.
  - **Local report** → load skill `pr-review:report` and follow it.
  - **Report + push to PR** → load skill `pr-review:report` and follow it; afterwards tell the user: *"Review `reviews/pr-<number>.review.md` — edit or delete any finding section to change what gets pushed — then run `/pr-review push <number>`."* (Omit this option in git-only fallback mode.)
