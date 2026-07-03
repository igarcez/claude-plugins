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
(e.g. `add tests/integration`) adds a sub-file under the hub `intelligence/<topic>.md`;
`add <topic>/<sub>/<deeper>` nests further, under the hub `intelligence/<topic>/<sub>.md`. See "When
a file grows too broad" in `intel:shape` for the hub/sub-file shape.

## 1. Refuse if not bootstrapped

If `intelligence/` does not exist, tell the user to run `/intel setup` first and stop.

## 2. Handle collisions and hubs

- Plain `add <topic>` where `intelligence/<topic>.md` exists **as a leaf** → tell the user the file
  exists and stop; suggest `/intel maintain` to update it instead.
- Plain `add <topic>` where `intelligence/<topic>.md` exists **as a hub** (its body is a `## Index`)
  → tell the user it is a sub-index and ask for a sub-topic instead (`add <topic>/<sub>`).
- For a path target, walk the segments left to right; at each intermediate segment the file
  `intelligence/<path-so-far>.md` must be a hub:
  - It exists as a **leaf** → offer (via `AskUserQuestion`) to convert it to a hub first (move its
    body to a sub-file inside the new sibling folder, rewrite the file as a hub — see "When a file
    grows too broad" in `intel:shape`) before continuing deeper.
  - It does not exist → create the hub as part of this add.
- The final segment's file already exists → tell the user the file exists and stop.

## 3. Interview for content

Use `AskUserQuestion` to gather what the rule covers. Cover at minimum:

- **Trigger** — what task or change should make a future reader open this file? (Becomes the
  `If <trigger>` clause in `CLAUDE.md`.)
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

## 6. Update `CLAUDE.md` index

Append a new bullet under `## Index` in `CLAUDE.md`:

```
- If <trigger> → read [intelligence/<topic>.md](intelligence/<topic>.md)
```

Keep the index ordered as it was — append unless the user requests a specific position. Do not touch
the preamble.

For a sub-topic add (any path target, at any depth), do **not** add a `CLAUDE.md` bullet — the
top-level bullet for `<topic>` already covers the whole area. Instead append the sub-trigger bullet
to the **immediate parent hub's** `## Index`:

```
- If <sub-trigger> → read [intelligence/<...>/<sub>.md](<relative path from the hub>)
```

When the add converted a leaf into a hub (at any level), verify the bullet pointing at that file —
in `CLAUDE.md` for a top-level conversion, in the parent hub otherwise — still describes the whole
area; broaden its `If <trigger>` wording if it was specific to the old single file.

## 7. Report

Tell the user the file path, the index line added, and remind them they can run `/intel maintain`
later to re-verify.
