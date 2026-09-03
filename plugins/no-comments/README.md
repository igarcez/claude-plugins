# no-comments

Comment-free code, enforced at write time.

Claude writes code that explains itself — descriptive names, small well-named functions — instead of
code plus commentary. When a piece of code looks like it needs a comment, it gets rewritten until the
comment is redundant.

## Install

```
/plugin marketplace add igarcez/claude-plugins
/plugin install no-comments@igarcez
```

## What it does

### PreToolUse hook — `no-comments-guard.sh`

Fires before every `Write` and `Edit` whose target is a TypeScript, JavaScript, PHP, or Go source
file (`.ts .tsx .js .jsx .mjs .cjs .php .go`), or a `plans/*.plan.md` file. It:

1. Exits immediately when `CLAUDE_NO_COMMENTS=0`, when `jq` is missing, or when the target
   extension is not one of the above.
2. Reads the incoming content — `tool_input.content` for `Write`, `tool_input.new_string` for
   `Edit`. Files already on disk are never scanned; only what is being written.
3. For `plans/*.plan.md`, scans only fenced code blocks tagged `ts`, `tsx`, `typescript`, `js`,
   `jsx`, `javascript`, `php`, or `go` — prose and other fences are ignored.
4. Strips escaped characters and quoted spans (`"..."`, `'...'`, backtick spans) before looking for
   comment markers, so a `//` inside a URL string does not trigger.
5. Denies the call when a `//`, `/*`, `*/` (or `#` in PHP) survives, unless the line is a
   machine-read pragma (`eslint-*`, `prettier-ignore`, `biome-ignore`, `@ts-ignore`,
   `@ts-expect-error`, `@ts-nocheck`, `@phpstan-*`, `@psalm-*`, `phpcs:*`, `@codeCoverageIgnore`,
   `//go:*`, `//nolint:*`, `// Code generated ...`), a shebang, or a license header
   (`SPDX-License-Identifier`, `Copyright`).
6. Returns the offending lines and points at the `no-comments:style` skill, so the agent rewrites
   the code rather than deleting the comment.

Doc blocks — JSDoc, PHPDoc, docstrings — count as comments and are denied.

### Skill — `no-comments:style`

The rewrite playbook: a comment-to-refactor table, naming rules, and the split heuristics. Loaded by
the agent when the hook denies a write, or up front before writing code.

## Configuration

| Env var | Effect |
|---------|--------|
| `CLAUDE_NO_COMMENTS=0` | Disables the hook for the session. Everything else is on by default. |
