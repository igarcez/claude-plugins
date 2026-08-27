---
name: setup
description: "Branch of /intel: bootstrap the intelligence layer (subcommand setup, or empty argument). Internal: loaded by the intel command; not a standalone task."
---

# intel setup

Bootstrap the intelligence layer in the current repo from whatever documentation already exists.
Requires the shared shapes from the `intel:shape` skill — load it first if it is not already in context.

## 1. Detect bootstrap state

First load the registry `intel:migrations` and compute the pending set ("How to compute the pending
set" — ledger first, Detect only for ids missing from it). If any migration is pending, load
`intel:upgrade`, let it apply them, then re-run the state detection below against the upgraded layer.

Determine which of three states the repo is in, and route accordingly:

**State A — Not bootstrapped.** `intelligence/` does not exist, or exists but contains zero
`*.md` files. → Continue with the full flow below (steps 2–8).

**State B — Fully bootstrapped.** `intelligence/index.md` exists alongside ≥1 topic file or hub,
**and** the layer passes the index-shape check below. → Tell the user:
*"`intelligence/` already exists with N topic files and `intelligence/index.md` is in index shape. Use
`/intel add <topic>` to add a new context or `/intel maintain` to audit existing ones."* — and stop.

**State C — Partially bootstrapped.** `intelligence/` exists with ≥1 `*.md` files, **but** the layer
fails the index-shape check. → Run the migration flow below (step 1a) instead of the full setup. Do
**not** stop; do **not** wipe existing intelligence files.

### Index-shape check

The layer is in **index shape** when **all** of these hold:

- `intelligence/index.md` exists, its top-level heading is `# Project intelligence index`, it has a
  `## How to use this index` section with substantially the canonical wording, and a `## Index`
  section whose body is a bullet list of `- If <trigger> → read [intelligence/<topic>.md](<topic>.md)`
  (or `[intelligence/<topic>/index.md](<topic>/index.md)` for a hub) lines and nothing else (see
  "Shape of `intelligence/index.md`" in `intel:shape`).
- `CLAUDE.local.md` **or** `CLAUDE.md` contains the canonical `## Project intelligence` stanza (the
  block reproduced in step 6). A layer bootstrapped before this version keeps its stanza in
  `CLAUDE.md`, and that still counts as index shape.
- The file carrying the stanza has no `## Index` and no `## How to use this index` section.

`CLAUDE.md` is **never** rewritten by this skill. Prose rules, command tables, conventions, or
architecture descriptions still sitting in `CLAUDE.md` do not fail this check — they are harvested
read-only in step 2 (State A) or step 1a (State C) and left in place.

If any condition fails, route to State C.

## 1a. Migration flow (State C only)

Goal: copy any rules/commands/conventions currently living in `CLAUDE.md` into the appropriate
`intelligence/*.md` file (existing or new), then write `intelligence/index.md` and put the pointer
stanza in `CLAUDE.local.md`. `CLAUDE.md` is read-only throughout — never edit, reduce, back up, or
delete it, so whatever it documented stays there alongside the new intelligence files. Existing
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
     filename match alone); no action.
   - **extend** — existing intel file is the right home but missing this rule/command; plan
     an edit that appends to it.
   - **new** — no existing intel file fits; plan a new `intelligence/<topic>.md`, or
     `intelligence/local/<topic>.md` when the item is machine-local per "What belongs in
     `intelligence/local/`" in `intel:shape`.
   Present this mapping to the user via `AskUserQuestion` (offer to reassign any item) before
   touching files. If many items map to the same new topic, batch them.
4. **Verify before writing.** For every `extend` / `new` plan, run the verification step
   (step 3 of the full setup) — confirm cited paths/commands/constants still exist. Drop
   stale rules; flag ambiguous ones to the user.
5. **Apply edits.** For `extend`, use `Edit` to add the new rule under the appropriate
   section of the existing file (respect the file's section headings; create a new section
   only if no existing one fits). For `new`, `Write` a fresh `intelligence/<topic>.md`
   following the "Shape of an intelligence file" rules in `intel:shape`.
6. **Write `intelligence/index.md` and `CLAUDE.local.md`** (step 6 of the full setup), with one
   index bullet per intel file referenced by trigger (both newly-created and existing files that
   already cover items, so the final index covers everything).
7. **Report** (step 8 of the full setup), additionally calling out: which items were
   `covered` / `extended` / `new`, which files were edited, which were created, and what
   was dropped as stale.

After step 7 of the migration flow, stop. Do not run steps 2–8 of the full setup.

## 2. Gather existing documentation

Read every source of project guidance currently in the repo:

- `CLAUDE.md` (root) — capture every rule, command, convention it currently documents.
- `CLAUDE.local.md` (root) — same; route anything machine-local it documents to
  `intelligence/local/<topic>.md` per "What belongs in `intelligence/local/`" in `intel:shape`.
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
  (`intelligence/<topic>/index.md` hub + `intelligence/<topic>/<sub>.md` files) rather than one
  oversized file — see "When a file grows too broad" in `intel:shape`.
- Route each confirmed topic to a layer using "What belongs in `intelligence/local/`" in
  `intel:shape`: project-shared topics become `intelligence/<topic>.md`; anything true only on this
  machine (personal plugins, `$HOME` paths, personal tooling, local-only services) becomes
  `intelligence/local/<topic>.md`. When the classification is genuinely ambiguous, ask once via
  `AskUserQuestion` listing the ambiguous topics and their proposed layer.

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

## 6. Write `intelligence/index.md` and `CLAUDE.local.md`

Write `intelligence/index.md` using the structure in "Shape of `intelligence/index.md`" in
`intel:shape`. Generate one index bullet per top-level topic — a flat file targets `(<topic>.md)`, a
hub targets `(<topic>/index.md)` — with a precise `If <trigger>` clause derived from its scope.

Then write the pointer stanza into `CLAUDE.local.md`. Leave `CLAUDE.md` exactly as found — never
edit, reduce, back up, or delete it.

Canonical `CLAUDE.local.md` content — reproduce verbatim:

```markdown
# CLAUDE.local.md

## Project intelligence

This project's instructions live in an intelligence layer. **Read
[intelligence/index.md](intelligence/index.md) first, every task**, and follow it: match its
`If <trigger>` bullets and read every matching file in full before acting.

When dispatching a subagent, include in its prompt: "Read intelligence/index.md and every matching
intelligence file before starting."
```

Route on what is already there:

- **`CLAUDE.local.md` does not exist** — `Write` it with exactly the block above.
- **It exists and already contains the `## Project intelligence` stanza** — change nothing.
- **It exists without the stanza** — copy the current file to `CLAUDE.local.md.bak`, then ask the
  user with `AskUserQuestion`, question *"`CLAUDE.local.md` already exists. Where should the
  intelligence pointer stanza go?"*, options in this order:
  1. **Append at the end (recommended)** — keep every existing byte and add a blank line plus the
     `## Project intelligence` stanza (without the `# CLAUDE.local.md` heading) at the bottom.
  2. **Prepend after the heading** — rewrite as the `# CLAUDE.local.md` heading, the stanza, then
     every existing section verbatim in its original order.
  3. **Leave untouched** — write nothing, delete the `.bak`, and report that the user must add the
     stanza themselves.

Then create the machine-local layer — follow "Creating the local layer" in `intel:shape` (create
`intelligence/local/`, write `intelligence/local/index.md` with the fixed preamble, ensure the
`.gitignore` line `intelligence/local/`). Every layer has one, whether or not any machine-local
topic was extracted. Add one bullet to `intelligence/local/index.md` per machine-local file written
in step 5, and **no** bullet for them in `intelligence/index.md`.

Then ensure the repo `.gitignore` carries these exact lines, each on its own line — create
`.gitignore` with them when the file does not exist, append a missing line, change nothing for a
line already present:

```
CLAUDE.local.md
CLAUDE.local.md.bak
```

Finally stamp the ledger: append every id in the `intel:migrations` registry as `baseline` for this
layer (see "The applied-migration ledger"). A layer born in the current shape must never have an old
migration applied to it later.

## 7. Handle `AGENTS.md`

If `AGENTS.md` exists and its content is now fully covered by `intelligence/*.md`, replace its body with
a single line: `See intelligence/index.md for project instructions.` (keeps the file present for
tools that look for it). If it documents agent-specific things not covered, keep those parts; remove
duplicated rules.

## 8. Report

Tell the user: which topics were extracted, which were routed to the machine-local layer
(`intelligence/local/`, gitignored) and why, which rules were dropped as stale (and why), which
intelligence files were created, that `intelligence/index.md` now holds the index, what happened to
`CLAUDE.local.md` (created / stanza appended / stanza prepended / left untouched, and whether a
`CLAUDE.local.md.bak` was written), that `CLAUDE.md` was left unchanged, and which `.gitignore`
lines were added. Also report on
verbose comments: how many were promoted into intel files, how many were migrated (with file + line
range) vs. left as is, and how many were excluded as stale or non-intelligence. Suggest next steps:
`/intel add <topic>` or `/intel maintain`.
