---
name: add
description: "Branch of /intel: add a new intelligence topic or sub-topic (subcommand add). Internal: loaded by the intel command; not a standalone task."
---

# intel add

Add a new `intelligence/<topic>.md` (or hub sub-file) plus its index bullet.
Requires the shared shapes from the `intel:shape` skill — load it first if it is not already in context.

Parse the topic name from the argument (e.g. `add releases` → topic `releases`). The topic must be
kebab-case. If no topic is given, ask the user for one via `AskUserQuestion` (offer 2–4 likely topics
inferred from recent conversation, plus Other).

A sub-topic target is written as a path of kebab-case segments, at **any depth**: `add <topic>/<sub>`
(e.g. `add tests/integration`) writes `intelligence/<topic>/<sub>.md` under the hub
`intelligence/<topic>/index.md`; `add <topic>/<sub>/<deeper>` nests further, writing
`intelligence/<topic>/<sub>/<deeper>.md` under the hub `intelligence/<topic>/<sub>/index.md`. See
"When a file grows too broad" in `intel:shape` for the hub/sub-file shape.

## 1. Refuse if not bootstrapped

If `intelligence/` does not exist, tell the user to run `/intel setup` first and stop.
If `intelligence/` exists but `intelligence/index.md` does not, the layer is on a legacy layout —
tell the user to run `/intel upgrade` first and stop.

## 2. Handle collisions and hubs

- Any target whose final segment is `index` → refuse: `index.md` is reserved for indexes at every
  level (`intelligence/index.md` is the root index, `intelligence/<topic>/index.md` is a hub).
- Plain `add <topic>` where `intelligence/<topic>.md` exists **as a leaf** → tell the user the file
  exists and stop; suggest `/intel maintain` to update it instead.
- Plain `add <topic>` where `intelligence/<topic>/index.md` exists → the topic is already a hub; ask
  the user for a sub-topic instead (`add <topic>/<sub>`).
- For a path target, walk the segments left to right; every intermediate segment must resolve to a
  hub, i.e. `intelligence/<path-so-far>/index.md` must exist:
  - `intelligence/<path-so-far>.md` exists as a **leaf** → offer (via `AskUserQuestion`) to convert it
    to a hub before continuing deeper. Converting: create `intelligence/<path-so-far>/`, move the
    leaf's body to `intelligence/<path-so-far>/<name>.md` (ask for `<name>`, default the last path
    segment), write `intelligence/<path-so-far>/index.md` as the hub with one bullet for that
    sub-file, delete the old flat file, retarget the parent index bullet from `(<segment>.md)` to
    `(<segment>/index.md)`, and re-base every relative link the moved body carried (it now sits one
    level deeper) — see "When a file grows too broad" and "Moving a file re-bases every relative link
    in it" in `intel:shape`.
  - Neither the leaf nor the hub exists → create `intelligence/<path-so-far>/index.md` as part of
    this add, and add its bullet to the parent index.
- The final segment's file already exists → tell the user the file exists and stop.

## 3. Interview for content

Use `AskUserQuestion` to gather what the rule covers. Cover at minimum:

- **Trigger** — what task or change should make a future reader open this file? (Becomes the
  `If <trigger>` clause in `intelligence/index.md`.)
- **Commands** — exact invocations the reader will need, with one-line purposes.
- **Rules / lockstep edits** — files that must change together, conventions to follow, gotchas.
- **References** — links to related intelligence files, ADRs, auto-memory entries.

Drill into each branch until you have concrete, verifiable content. Do not write placeholders.

## 4. Verify against code

Same verification as `/intel setup`'s "Verify each extracted context against current code" step:
every command must exist, every path must resolve, every cited constant/file must be found. Fix or
drop unverifiable claims.

## 5. Write `intelligence/<topic>.md`

Follow the "Shape of an intelligence file" rules in `intel:shape`.

## 6. Update the index

For a top-level add, append a new bullet under `## Index` in `intelligence/index.md`:

```
- If <trigger> → read [intelligence/<topic>.md](<topic>.md)
```

A bullet's **label** is the repo-relative path; its **link target** is relative to the file that holds
the index (see "Link targets in an index" in `intel:shape`). Keep the index ordered as it was — append
unless the user requests a specific position. Do not touch the preamble, and do not touch `CLAUDE.md`.

For a sub-topic add (any path target, at any depth), do **not** add an `intelligence/index.md`
bullet — the top-level bullet for `<topic>` already covers the whole area. Instead append the
sub-trigger bullet to the **immediate parent hub's** `## Index`, with the target relative to that hub:

```
- If <sub-trigger> → read [intelligence/<topic>/<sub>.md](<sub>.md)
```

in `intelligence/<topic>/index.md`, and:

```
- If <sub-trigger> → read [intelligence/<topic>/<sub>/<deeper>.md](<deeper>.md)
```

in `intelligence/<topic>/<sub>/index.md`.

When the add converted a leaf into a hub (at any level), the bullet pointing at that topic — in
`intelligence/index.md` for a top-level conversion, in the parent hub otherwise — must now target
`(<segment>/index.md)`; also verify its `If <trigger>` still describes the whole area and broaden the
wording if it was specific to the old single file.

## 7. Report

Tell the user the file path, the index line added, and remind them they can run `/intel maintain`
later to re-verify.
