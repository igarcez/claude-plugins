---
name: shape
description: "Shared reference for /intel — shape of an intelligence file, hub/sub-index splitting, code-citation rules, canonical CLAUDE.md shape. Internal: loaded by the intel command before any branch; not a standalone task."
---

# intel — shared shapes

Reference material used by every `/intel` branch (`setup`, `add`, `maintain`).

## Shape of an intelligence file

- Filename: kebab-case topic, `.md` extension (`intelligence/tests.md`, `intelligence/migrations.md`).
- Heading: `# <Topic>` (sentence case, no prefix).
- Body sections (only include those that apply):
  - `## Commands` — a Markdown table of `Command | Purpose` for repeatable invocations.
  - `## <Rules / Conventions / How it works>` — required behaviour, lockstep file edits, gotchas.
  - `## Reference` — links to deeper docs, ADRs, or auto-memory entries.
- Keep each file tight (typically 30–120 lines). If a file grows past ~150 lines **and** covers
  several independent sub-areas, split it into a sub-index — see "When a file grows too broad".
- Write rules as imperatives (`Use X`, `Do not Y`), not descriptions.

## When a file grows too broad: split into a sub-index

The goal is always the **narrowest context for a request** — a reader opening a file for one task
should not have to skim past large sections that don't apply. When a topic file covers several
independent sub-areas, convert it into a *sub-index* (a "hub") and move the detail into sub-files.

Layout:

- The hub keeps its original path: `intelligence/<topic>.md`.
- Sub-files go in a sibling folder named after the topic: `intelligence/<topic>/<subtopic>.md`.
- This applies **recursively, at any depth**: a sub-file that grows too broad becomes a hub itself —
  `intelligence/<topic>/<sub>.md` turns into an index over `intelligence/<topic>/<sub>/<subsub>.md`.

The hub becomes an index — the same idea as `CLAUDE.md`, scoped to the topic:

```markdown
# <Topic>

<one-line scope of the whole area>. This file is an **index** — read the sub-file whose
trigger matches; do not read them all.

## Shared        (optional — only when some rules apply to every sub-topic)

- <rule every reader of this area needs, kept to a few lines>

## Index

- If <sub-trigger A> → read [intelligence/<topic>/<sub-a>.md](<topic>/<sub-a>.md)
- If <sub-trigger B> → read [intelligence/<topic>/<sub-b>.md](<topic>/<sub-b>.md)
```

Each sub-file follows the normal **Shape of an intelligence file** rules above (heading
`# <Subtopic>`, plus `## Commands` / rules / `## Reference` as needed).

When to split (all three should hold — size alone is not enough):

- **Size:** the file is past ~150 lines, or visibly sprawling.
- **Separability:** it covers ≥3 sub-areas whose triggers rarely co-occur — a reader for one task
  needs one section and never the others.
- **Net win:** splitting reduces what a typical reader loads. If the content is cohesive (most
  readers need most of it), keep it flat even if long — a split just adds a hop.

There is no depth limit — split whenever the three criteria hold, at whatever level the over-broad
file lives; each extra hop must pay for itself in narrower context for the typical reader. The
reverse applies at every level too: if a hub decays to a single sub-file, collapse it back into a
flat file at its own path.

The `CLAUDE.md` bullet does not change when a topic becomes a hub: it still points at
`intelligence/<topic>.md` with a broad trigger for the whole area. The second hop (hub → sub-file)
delivers the narrow context, while `CLAUDE.md` stays one line per area.

## Citing code locations

When an intel file references code, anchor on what **greps**, not on line numbers — line numbers drift on
every insertion above them (one new function near the top of a file shifts every citation below it).

- Anchor on a **greppable symbol**: a function/method/class/constant name, or an exact quoted error/log
  string. The symbol is the durable anchor; it moves with the code.
- Treat `:line` / `:start-end` as an optional **navigation hint**, never the anchor. Add it only when it
  materially speeds finding the spot; prefer one anchor line over a wide range. For large, high-churn
  files, prefer symbol-only.
- **Never hand-count lines** — extract/refresh by grepping the symbol, e.g.
  `grep -nE 'function myMethod|throw new .*"exact message"' path/to/file`.
- **Lockstep:** when you edit a file an intel file cites, re-grep its symbols and update any moved `:line`
  in the same change.

## Shape of `CLAUDE.md`

```markdown
# CLAUDE.md

Index of project instructions. Read referenced file when topic matches.

## How to use this index

1. **Scan first, match liberally.** Every task: match against the `If <trigger>` bullets below and read
   each matching `intelligence/*.md` in full before acting — when unsure whether a trigger applies, read
   it anyway. If a file is itself an index (a hub of `If <sub-trigger>` bullets), match its sub-triggers
   the same way and read only the matching sub-file(s).
2. **Multiple triggers are normal.** A change can touch tests + migrations + API surface at once;
   read every matching file and apply all of them.
3. **Apply the rules during work, not after.** The intelligence files describe required practices
   (commands to run, files to update in lockstep, conventions to follow), not optional reading.
4. **Keep the intelligence up to date.** If you change behaviour that an intelligence file documents
   (e.g. a command name changes, a folder moves, a convention is dropped or added), update the matching
   `intelligence/*.md` file in the same change so the next reader doesn't get stale guidance. If a new
   recurring practice emerges that isn't covered yet, add a new `intelligence/<topic>.md` and link it
   from the index below.
5. **Fix mistakes on sight.** If, while working with an intelligence file, you find anything wrong —
   wrong path, wrong command, outdated rule, contradicts the current code, typo that changes meaning —
   fix it in the file as part of the current change. Don't leave a broken instruction in place for the
   next reader to trip over.
6. **Propagate to subagents.** When dispatching a subagent, include in its prompt: "Scan the
   CLAUDE.md index and read every matching intelligence/*.md file before starting." A subagent
   sees CLAUDE.md but won't reliably follow the index on its own — the explicit instruction
   travels with the task.
7. **Check the system-wide layer for local-app configs.** When the task touches configuration of
   local apps / dotfiles under `~/.config/`, also read `~/.config/intelligence/CLAUDE.md` and scan
   its own index — it carries cross-config hooks and machine-wide intel that span configs beyond
   this repo.

## Index

- If <trigger A> → read [intelligence/<topic-a>.md](intelligence/<topic-a>.md)
- If <trigger B> → read [intelligence/<topic-b>.md](intelligence/<topic-b>.md)
...
```

The preamble (`# CLAUDE.md` through end of `## How to use this index`) is **fixed**. Only the `## Index`
bullets change between projects. When rewriting `CLAUDE.md`, preserve the preamble verbatim.
