---
name: setup
description: "Branch of /intel: bootstrap the intelligence layer (subcommand setup, or empty argument). Internal: loaded by the intel command; not a standalone task."
---

# intel setup

Bootstrap the intelligence layer in the current repo from whatever documentation already exists.
Requires the shared shapes from the `intel:shape` skill — load it first if it is not already in context.

## 1. Detect bootstrap state

Determine which of three states the repo is in, and route accordingly:

**State A — Not bootstrapped.** `intelligence/` does not exist, or exists but contains zero
`*.md` files. → Continue with the full flow below (steps 2–8).

**State B — Fully bootstrapped.** `intelligence/` exists with ≥1 `*.md` files, **and** `CLAUDE.md`
is already in index shape (see "Index-shape check" below). → Tell the user:
*"`intelligence/` already exists with N files and `CLAUDE.md` is in index shape. Use
`/intel add <topic>` to add a new context or `/intel maintain` to audit existing ones."* — and
stop.

**State C — Partially bootstrapped.** `intelligence/` exists with ≥1 `*.md` files, **but**
`CLAUDE.md` is still a knowledge-dump (fails the index-shape check). → Run the migration
flow below (step 1a) instead of the full setup. Do **not** stop; do **not** wipe existing
intelligence files.

### Index-shape check

`CLAUDE.md` is considered in **index shape** when **all** of these hold:

- The top-level heading is `# CLAUDE.md`.
- A `## How to use this index` section exists with substantially the canonical wording
  (see "Shape of `CLAUDE.md`" in `intel:shape`).
- A `## Index` section exists whose body is a bullet list of
  `- If <trigger> → read [intelligence/<topic>.md](intelligence/<topic>.md)` lines, and
  nothing else.
- No other top-level (`##`) sections contain prose rules, command tables, conventions,
  or architecture descriptions. (Inline code fences inside the preamble are fine; standalone
  topical sections like `## Data Fetching` or `## Testing` are not.)

If any condition fails, treat `CLAUDE.md` as a knowledge-dump and route to State C.

## 1a. Migration flow (State C only)

Goal: move any rules/commands/conventions currently living in `CLAUDE.md` into the appropriate
`intelligence/*.md` file (existing or new), then rewrite `CLAUDE.md` to index shape. Existing
intelligence files are the authority — extend them with anything `CLAUDE.md` has that they
lack; do not overwrite them with the `CLAUDE.md` wording.

1. **Inventory `CLAUDE.md`.** Read it end-to-end. List every distinct topical section
   (`## Project Structure`, `## Testing`, etc.) and every standalone rule/command/table.
   Note exact line ranges.
2. **Inventory `intelligence/*.md`.** For each existing file, summarise scope in one line
   (topic + what it covers). Use the existing file's heading and any `## Commands` /
   `## Rules` sections.
3. **Map each `CLAUDE.md` item to a target intel file.** For every item produce one of:
   - **covered** — existing intel file already says this (verify by reading the file, not by
     filename match alone); drop from `CLAUDE.md` with no edit needed elsewhere.
   - **extend** — existing intel file is the right home but missing this rule/command; plan
     an edit that appends to it.
   - **new** — no existing intel file fits; plan a new `intelligence/<topic>.md`.
   Present this mapping to the user via `AskUserQuestion` (offer to reassign any item) before
   touching files. If many items map to the same new topic, batch them.
4. **Verify before writing.** For every `extend` / `new` plan, run the verification step
   (step 3 of the full setup) — confirm cited paths/commands/constants still exist. Drop
   stale rules; flag ambiguous ones to the user.
5. **Apply edits.** For `extend`, use `Edit` to add the new rule under the appropriate
   section of the existing file (respect the file's section headings; create a new section
   only if no existing one fits). For `new`, `Write` a fresh `intelligence/<topic>.md`
   following the "Shape of an intelligence file" rules in `intel:shape`.
6. **Rewrite `CLAUDE.md` to index shape** (step 6 of the full setup), with one index bullet
   per intel file referenced by trigger (both newly-created and existing files that already
   cover items, so the final index covers everything).
7. **Report** (step 8 of the full setup), additionally calling out: which items were
   `covered` / `extended` / `new`, which files were edited, which were created, and what
   was dropped as stale.

After step 7 of the migration flow, stop. Do not run steps 2–8 of the full setup.

## 2. Gather existing documentation

Read every source of project guidance currently in the repo:

- `CLAUDE.md` (root) — capture every rule, command, convention it currently documents.
- `AGENTS.md` (root) — same.
- `.cursor/rules/**`, `.cursorrules`, `.windsurfrules`, `.aider*` — any agent-config files.
- `docs/`, `doc/`, `documentation/` — anything that looks like contributor guidance.
- `README.md`, `CONTRIBUTING.md` — extract only rules / commands relevant to coding work
  (skip marketing copy, install-for-end-user sections).
- Any `*/README.md` in top-level subfolders that documents a workflow (tests, migrations, build, deploy).

Take notes per topic as you read — group related rules under a single topic name. Typical topics:
`code-style`, `tests`, `migrations`, `api-docs`, `changelog`, `http-tests`, `benchmarks`, `commits`,
`releases`, `build`, `deploy`, `security`, `i18n`. Use what fits this project — don't force topics that
don't apply.

## 2a. Scan for verbose comments

Beyond doc files, scan the codebase for **verbose comments** — long explanatory comment blocks that
document conventions, rationale, gotchas, workflows, or architecture rather than annotating the single
line below them. These are a primary source of otherwise-undocumented project intelligence.

- Use `Grep`/`Glob` to find comment-dense files. Look for multi-line blocks and runs of comment lines
  (`/* … */`, `/** … */`, consecutive `//`, `#`, `--`, docstrings `""" … """`) that exceed ~5 lines or
  explain *why*/*how* at a project level.
- Prioritise blocks describing: setup/build/deploy steps, data flow, invariants, "do not change X
  because Y", performance/security caveats, or historical context.
- For each candidate, record: file path, line range, the topic it concerns, and the exact text.
- **Exclude** from candidates: license/copyright headers, auto-generated boilerplate, commented-out
  code, TODO/FIXME one-liners, and comments that only restate the adjacent code. These are not
  intelligence — do not promote or migrate them.

Group comment-derived notes under the same topic names as step 2 (a verbose comment about migrations
feeds the `migrations` topic). Track the source location of each promoted comment — step 5a needs it to
offer migration.

## 3. Verify each extracted context against current code

For every candidate topic, before writing the file, verify the rules still hold:

- **Commands** — does the script/Makefile target/binary still exist? Run `--help` or read the
  Makefile / `package.json scripts` / `composer.json scripts` to confirm signatures.
- **Paths** — do the folders/files referenced still exist? Use `Glob` to confirm.
- **Conventions** — spot-check by reading 1–2 representative files (e.g. if the rule says "tests live
  under `tests/unit/`", `ls tests/unit/`; if the rule mentions a header format, read one file).
- **Versions / constants** — if a rule references a constant or version, find it in the code.
- **Comment-derived content (from step 2a)** — validate before promoting: confirm the claim still
  matches the surrounding code, isn't stale (the comment can outlive the code it described), and isn't
  contradicted by another source. A verbose comment is a *claim*, not ground truth — never copy it into
  an intel file without verifying it against current code.

Drop or fix rules that no longer match current code. Surface anything ambiguous to the user via
`AskUserQuestion` before writing it. For comment-derived content, a failed validation means the comment
is stale — exclude it from the intel file and do **not** offer it for migration in step 5a.

## 4. Confirm topic list with the user

Before writing files, list the proposed topics and a one-line scope for each. Use `AskUserQuestion`
to confirm the list, with options to add/remove topics. Do not write files until confirmed.

## 5. Write the intelligence files

For each confirmed topic:

- Create `intelligence/<topic>.md`.
- Follow the "Shape of an intelligence file" rules in `intel:shape`.
- Include only verified rules. Cite exact paths and exact commands.
- If a topic is already large and separable at setup time, author it as a sub-index from the start
  (hub + `intelligence/<topic>/<sub>.md` files) rather than one oversized file — see "When a file
  grows too broad" in `intel:shape`.

## 5a. Offer to migrate verbose comments

Once all promoted comments are known, ask the user **once for the whole setup** — a single
`AskUserQuestion` — how to handle the verbose comments that were promoted into intelligence files (the
decision is usually all-or-nothing). First show the count and a short list of affected comments
(file + line range), then offer:

- **Migrate all** — for each, delete the verbose comment and replace it with a one-line pointer to the
  intel file, in the source language's comment syntax, e.g. `// See intelligence/<topic>.md`.
- **Leave all as is** — keep every comment untouched (the intel files now duplicate them).

Rules:

- Default to **leave all as is**; only migrate on explicit opt-in.
- Only count a comment as migratable when its information is **fully captured** in the intel file. If
  the intel file records less than the comment says, exclude it from the migrate set and flag the gap
  — don't migrate it even under "Migrate all".
- When migrating, strip only the verbose prose. Preserve any functional directive the block carried
  (e.g. `// eslint-disable-next-line`, `# type: ignore`, `# noqa`) — those are not intelligence.
- List every comment migrated (file + line range) so the change is reviewable.

## 6. Rewrite `CLAUDE.md`

Replace the existing `CLAUDE.md` (back it up first as `CLAUDE.md.bak` if not in git) with the structure
in "Shape of `CLAUDE.md`" in `intel:shape`. Generate one index bullet per intelligence file, with a
precise `If <trigger>` clause derived from the file's scope.

## 7. Handle `AGENTS.md`

If `AGENTS.md` exists and its content is now fully covered by `intelligence/*.md`, replace its body with
a single line: `See CLAUDE.md and intelligence/ for project instructions.` (keeps the file present for
tools that look for it). If it documents agent-specific things not covered, keep those parts; remove
duplicated rules.

## 8. Report

Tell the user: which topics were extracted, which rules were dropped as stale (and why), which
intelligence files were created, and that `CLAUDE.md` has been rewritten as an index. Also report on
verbose comments: how many were promoted into intel files, how many were migrated (with file + line
range) vs. left as is, and how many were excluded as stale or non-intelligence. Suggest next steps:
`/intel add <topic>` or `/intel maintain`.
