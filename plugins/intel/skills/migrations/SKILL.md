---
name: migrations
description: "Shared reference for /intel — the applied-migration ledger plus the registry of intelligence-layer migrations, each with a detect rule and a fix procedure. Internal: loaded by the intel command's setup / maintain / upgrade branches; not a standalone task."
---

# intel — migration registry

Every layout change the intelligence layer has ever had is recorded here as one numbered migration.
A migration runs **at most once per layer per machine**: the ids already applied are recorded in a
ledger on the user's machine, and only ids missing from it are ever considered. `intel:upgrade`
applies the pending ones and appends to the ledger; `intel:setup` and `intel:maintain` only compute
the pending set and load `intel:upgrade` when it is non-empty.

## The applied-migration ledger

One plain-text file per layer, on the user's machine — never inside `${CLAUDE_PLUGIN_ROOT}`, which is
a versioned cache replaced on every plugin update:

```
${CLAUDE_INTEL_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/intel}/applied/<key>.txt
```

`<key>` identifies the layer: take the repo root (`git rev-parse --show-toplevel`, falling back to the
cwd when not a git repo), then replace every `/` with `-` — `/home/ian/Projects/foo` becomes
`-home-ian-Projects-foo`. `mkdir -p` the directory before writing.

Format — one applied id per line: id, UTC timestamp, and how it was recorded:

```
M001 2026-08-15T13:40:12Z applied
M002 2026-08-15T13:40:13Z baseline
```

- `applied` — the Fix ran and its Verify passed.
- `baseline` — the layer was already in the target shape (born from a current `/intel setup`, or a
  Detect that did not fire), so the id is recorded without doing any work.

Append only. Never rewrite or reorder existing lines, and never delete the file as part of a command —
deleting it is a user action, and it only costs the next run a Detect pass.

## How to compute the pending set

1. Read the ledger; treat a missing or unreadable file as an empty ledger.
2. For every migration id in this registry, in id order:
   - **In the ledger** → done. Skip it, and do not run its Detect. This is what stops a later
     migration from undoing an earlier one on a repeat run.
   - **Not in the ledger** → run its **Detect** (a pure filesystem / file-content check: read files,
     write nothing). Detect fires → the id is **pending**. Detect does not fire → the layer is already
     in that shape, so append the id as `baseline` and move on.
3. The pending set is the ordered list of ids whose Detect fired.

The ledger is the source of truth for *what has run*; Detect is the guard for *whether it still needs
to run*. Both are required: the ledger alone would re-apply everything on a machine that has never
seen this layer (fresh clone, moved repo, second workstation), and Detect alone would let two
migrations that touch the same shape flip it back and forth on every invocation.

## How to add a future migration

Append a new `## M<nnn> — <title>` section with exactly four fields: **Detect**, **Fix**, **Verify**,
**Report**. Rules:

- Never renumber, reword the id of, or delete an existing entry — a layer created by an old version
  may still need it, and its id is already written into ledgers.
- Migrations apply in id order, and a later one may assume every earlier one has run.
- A later migration **may** contradict an earlier one (reversing a layout decision). That is safe only
  because an id in the ledger is never re-run — never resolve a contradiction by editing the earlier
  migration's Fix.
- Keep every Detect cheap and side-effect free.

## M001 — root index moves from `CLAUDE.md` to `intelligence/index.md`

**Detect** — fires when both hold:

- `intelligence/index.md` does not exist, **and**
- root `CLAUDE.md` exists and contains a line matching `^## Index`, **or** `intelligence/` contains
  at least one `*.md` file at any depth.

**Fix:**

1. Read root `CLAUDE.md` end to end (skip if it does not exist).
2. Classify content. **Intel-owned** (moves out): the lead sentence introducing the index (e.g.
   `Index of project instructions. Read referenced file when topic matches.`), the whole
   `## How to use this index` section, the whole `## Index` section, and any `If <trigger>` bullet
   anywhere else in the file whose link target is a path under `intelligence/`. **User content**
   (stays): the `# CLAUDE.md` heading and every other section, verbatim.
3. Collect index bullets: every intel-owned `If <trigger> → read [...](...)` bullet, in original
   order, with duplicates for the same target collapsed to the first occurrence.
4. For every top-level entry not covered by a collected bullet — `intelligence/*.md` other than
   `index.md`, plus every `intelligence/*/index.md` hub — generate a bullet whose `If <trigger>` is
   derived from that file's `# Heading` and opening lines. Flag every generated bullet in the report
   so the user can refine the wording.
5. Create `intelligence/` if missing; write `intelligence/index.md` per "Shape of
   `intelligence/index.md`" in `intel:shape`, with the collected + generated bullets under `## Index`,
   each target rewritten relative to `intelligence/` (`[intelligence/tests.md](tests.md)`, and
   `[intelligence/api/index.md](api/index.md)` for a hub).
6. Rewrite `CLAUDE.md`: `# CLAUDE.md`, then the canonical `## Project intelligence` stanza from
   "Shape of `CLAUDE.md`" in `intel:shape`, then every preserved user section verbatim in its
   original order. When `CLAUDE.md` did not exist, write the heading + stanza only.

**Verify:**

- `intelligence/index.md` exists, carries the canonical preamble, and has ≥1 `## Index` bullet.
- `CLAUDE.md` contains no `## Index` and no `## How to use this index` section, and does contain the
  stanza's `intelligence/index.md` link.
- Every `## Index` bullet target resolves to an existing file. Report unresolved targets; do not
  delete them.

**Report:** bullets migrated, bullets generated (flagged for review), user sections preserved,
files written, unresolved bullet targets.

## M002 — hub index moves from `intelligence/<topic>.md` to `intelligence/<topic>/index.md`

**Detect** — fires when any `intelligence/<path>.md` (at any depth, excluding the root
`intelligence/index.md`) both contains a line matching `^## Index` **and** has a sibling directory
`intelligence/<path>/`. That is the pre-2.0 hub shape: index file beside its folder.

**Fix** — process matches **deepest path first**, so a parent's bullets are rewritten only after its
children have their final names. For each match `intelligence/<path>.md`:

1. Move the file to `intelligence/<path>/index.md` — `git mv` when the file is tracked
   (`git ls-files --error-unmatch <path>` exits 0), plain move otherwise.
2. Re-base **every relative link in the whole file**, not only the `## Index` bullets — the file now
   sits one level deeper, so `## Shared`, `## Reference`, and inline links move with it (see "Moving a
   file re-bases every relative link in it" in `intel:shape`):
   - A target starting with `<last-segment>/` loses that prefix. In `intelligence/tests.md` a bullet
     `[intelligence/tests/integration.md](tests/integration.md)` becomes
     `[intelligence/tests/integration.md](integration.md)` in `intelligence/tests/index.md`. A target
     pointing at a nested hub already moved by this migration becomes `(<sub>/index.md)`.
   - **Every other relative target gains `../`** — a link to a sibling topic
     (`(code-guidelines.md)`) would otherwise resolve inside the new folder and dangle; it becomes
     `(../code-guidelines.md)`.
   - Absolute URLs, repo-root paths, and bare `#anchor` links are left alone. Labels are
     repo-relative and do not change.
3. Retarget the bullet pointing at this topic in its parent index — `intelligence/index.md` for a
   top-level topic, otherwise the parent hub's `index.md`: label `intelligence/<path>.md` →
   `intelligence/<path>/index.md`, target `<segment>.md` → `<segment>/index.md`. Leave the
   `If <trigger>` wording alone.

**Verify:**

- No `intelligence/**/*.md` file outside the root both contains `^## Index` and has a sibling
  directory of the same name.
- **Every relative link in every moved file resolves** — the whole body, not just `## Index` bullets.
- Every bullet target in every `index.md` resolves to an existing file.
- No file was left behind at the old hub path.

**Report:** hubs moved (old path → new path), links re-based per file (index bullets and body links
counted separately), anything unresolved.

## M003 — repair relative links left dangling by an earlier M002 run

M002 originally re-based only `## Index` bullets, so a hub moved by an early 2.0.x run can still carry
body links (`## Shared`, `## Reference`, inline) that resolve inside the new folder instead of beside
it. M002 is already in those ledgers and is never re-run, so the repair is its own migration.

**Detect** — fires when any `intelligence/**/index.md` below the root contains a relative Markdown
target that does **not** resolve from its own folder but **does** resolve with `../` prepended.

**Fix** — for each such link, prepend `../` to the target. Leave the label, absolute URLs, repo-root
paths, and `#anchor` links untouched. A dangling target that does not resolve with `../` either is
**not** this migration's business: report it, change nothing.

**Verify:**

- Every relative link in every `intelligence/**/index.md` resolves from its own folder, or is listed
  in the report as unresolved for another reason.
- No label text changed.

**Report:** files touched, each link re-based (before → after), links left dangling for another reason.
