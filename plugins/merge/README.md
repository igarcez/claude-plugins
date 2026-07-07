# merge

A Claude Code plugin that merges a branch into the current branch and resolves any conflicts intelligently. Point it at a branch — or let it detect the remote default branch — and it fetches, merges, and works through each conflicted file by reading both sides, reconstructing the intent of each change, and combining them. Ambiguous or risky conflicts are escalated to you instead of guessed at.

## Install

Add the [claude-plugins](https://github.com/igarcez/claude-plugins) marketplace, then install:

```
/plugin marketplace add igarcez/claude-plugins
/plugin install merge@igarcez
```

## Usage

| Command | What it does |
|---------|--------------|
| `/merge` | Merge the remote default branch (detected via `git remote show origin`, falling back to `main`/`master`/`develop`) into the current branch. |
| `/merge <branch>` | Merge `origin/<branch>` into the current branch. |

## How conflicts are handled

1. Conflicted files are listed with `git diff --name-only --diff-filter=U`.
2. Each file is read in full; both sides of every conflict are analyzed, using `git log` context when the intent isn't obvious from the diff alone.
3. Conflicts are resolved by combining both changes while preserving the intent of each side — not by blindly picking one side.
4. If a conflict is genuinely ambiguous (both sides changed the same logic in incompatible ways), you are asked before anything is resolved.
5. The merge is completed with the default merge commit message, and a clean `git status` is verified before reporting.
