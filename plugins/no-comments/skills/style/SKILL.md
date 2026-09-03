---
name: style
description: "Rewrite code so comments become redundant — descriptive names, small named functions, intent-revealing identifiers. Load when the no-comments guard hook denies a write, or before writing TypeScript, JavaScript, PHP, or Go in a repo that installs the no-comments plugin."
---

# Comment-free code

Code carries its own explanation. A comment is a signal that the code did not say what it meant —
fix the code, do not annotate it.

## The rule

Write no comments. When a piece of code seems to need one, rewrite that piece so the comment would
add nothing, then drop the comment.

Allowed, and only these: machine-read pragmas (`eslint-*`, `prettier-ignore`, `biome-ignore`,
`@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `@phpstan-*`, `@psalm-*`, `phpcs:*`,
`//go:*`, `// Code generated ... DO NOT EDIT.`, `//nolint:*`), shebangs, and license headers
(`SPDX-License-Identifier`, `Copyright`). Doc blocks — JSDoc, PHPDoc, docstrings — are comments and
are not allowed.

## Comment to refactor

| Comment says | Rewrite |
|--------------|---------|
| What a magic value means | Bind it to a named constant: `const SESSION_TIMEOUT_MINUTES = 30` |
| What a block does | Extract the block into a function named after that sentence |
| What a condition tests | Bind the condition to a named boolean: `const isExpiredSession = ...` |
| Why a branch exists | Name the branch's guard function: `rejectWhenQuotaExhausted(request)` |
| What a parameter is | Rename the parameter; widen the type into a named type or value object |
| Section headers inside a long function | The function does too much — split it at each header |
| Step-by-step numbering | One named function per step, called in order in a short orchestrator |
| A workaround for external behaviour | Name the wrapper after the workaround: `retryOnUpstream429(...)` |
| Commented-out code | Delete it; git holds the history |
| A TODO | Do it now, or leave it out of the code and raise it with the user |

## Naming

- Functions are verb phrases naming the outcome: `expireStaleSessions`, `parseInvoiceTotal`.
- Booleans read as assertions: `hasPendingInvoice`, `isWithinGracePeriod`.
- Collections are plural, elements singular; no abbreviations (`request`, never `req`).
- Prefer a longer accurate name over a short one that needs a comment.

## Splitting

- A function that needs a blank line to separate phases is two functions.
- A function whose name needs "and" is two functions.
- The orchestrator reads as a list of named calls; each call's name replaces the comment it would
  have carried.

## When the guard denies a write

The hook `no-comments-guard.sh` denies the tool call and lists the offending lines. Do not resend
the same content with the comments deleted and nothing else changed — the comment marked a place
where the code was unclear. Apply the rewrite from the table above, then resend.

Escape hatch: the user can export `CLAUDE_NO_COMMENTS=0` to disable the hook for a session. Only
suggest it for a genuine false positive (a comment marker inside a construct the string-stripper
does not understand); never to bypass the rule.
