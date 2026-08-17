---
name: shape
description: "Shared reference for /intel — shape of an intelligence file, hub/sub-index splitting, code-citation rules, canonical intelligence/index.md and CLAUDE.md shapes. Internal: loaded by the intel command before any branch; not a standalone task."
---

# intel — shared shapes

Reference material used by every `/intel` branch (`setup`, `add`, `maintain`, `upgrade`).

## Shape of an intelligence file

- Filename: kebab-case topic, `.md` extension (`intelligence/tests.md`, `intelligence/migrations.md`).
  `index.md` is **reserved at every level** for an index: `intelligence/index.md` is the layer's root
  index, `intelligence/<topic>/index.md` is that topic's hub. An `index.md` is never a topic file.
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

Layout — **every index in the layer is named `index.md`**:

- A flat topic is a single file: `intelligence/<topic>.md`.
- A hub topic is a folder: `intelligence/<topic>/index.md` holds the index, and the sub-files sit
  beside it as `intelligence/<topic>/<subtopic>.md`. The flat `intelligence/<topic>.md` is deleted by
  the split — a topic is either a file or a folder, never both.
- This applies **recursively, at any depth**: a sub-file that grows too broad becomes a hub itself —
  `intelligence/<topic>/<sub>.md` turns into `intelligence/<topic>/<sub>/index.md` indexing
  `intelligence/<topic>/<sub>/<subsub>.md`.

The hub is an index — the same idea as `intelligence/index.md`, scoped to the topic:

```markdown
# <Topic>

<one-line scope of the whole area>. This file is an **index** — read the sub-file whose
trigger matches; do not read them all.

## Shared        (optional — only when some rules apply to every sub-topic)

- <rule every reader of this area needs, kept to a few lines>

## Index

- If <sub-trigger A> → read [intelligence/<topic>/<sub-a>.md](<sub-a>.md)
- If <sub-trigger B> → read [intelligence/<topic>/<sub-b>.md](<sub-b>.md)
```

Each sub-file follows the normal **Shape of an intelligence file** rules above (heading
`# <Subtopic>`, plus `## Commands` / rules / `## Reference` as needed).

To split a leaf into a hub:

1. Create the folder `intelligence/<topic>/`.
2. Move each section into `intelligence/<topic>/<sub>.md`, rules verbatim.
3. Write `intelligence/<topic>/index.md` — optional `## Shared` core plus the `## Index` of sub-triggers.
4. Delete the old flat `intelligence/<topic>.md`.
5. Retarget the bullet that points at the topic in its parent index (`intelligence/index.md`, or the
   parent hub's `index.md`): `(<topic>.md)` becomes `(<topic>/index.md)`.
6. Re-base every relative link carried into the new folder — see "Moving a file re-bases every
   relative link in it" below.

When to split (all three should hold — size alone is not enough):

- **Size:** the file is past ~150 lines, or visibly sprawling.
- **Separability:** it covers ≥3 sub-areas whose triggers rarely co-occur — a reader for one task
  needs one section and never the others.
- **Net win:** splitting reduces what a typical reader loads. If the content is cohesive (most
  readers need most of it), keep it flat even if long — a split just adds a hop.

There is no depth limit — split whenever the three criteria hold, at whatever level the over-broad
file lives; each extra hop must pay for itself in narrower context for the typical reader. The
reverse applies at every level too: if a hub decays to a single sub-file, collapse it back — fold the
sub-files into a flat `intelligence/<topic>.md`, delete the folder (its `index.md` included),
retarget the parent bullet from `(<topic>/index.md)` back to `(<topic>.md)`, and re-base the folded-in
relative links for their new, shallower home.

The parent index keeps **one line per area** either way: its `If <trigger>` stays broad and only the
target changes when a topic becomes (or stops being) a hub. The second hop (hub → sub-file) delivers
the narrow context.

## Link targets in an index

In any index — the root `intelligence/index.md` or a hub's `index.md` — a bullet's **label** is the
repo-relative path and its **link target** is relative to the file that holds the index:

| Index file | Points at | Bullet |
|------------|-----------|--------|
| `intelligence/index.md` | flat topic | `- If <trigger> → read [intelligence/tests.md](tests.md)` |
| `intelligence/index.md` | hub topic | `- If <trigger> → read [intelligence/api/index.md](api/index.md)` |
| `intelligence/api/index.md` | sub-file | `- If <sub-trigger> → read [intelligence/api/rest.md](rest.md)` |
| `intelligence/api/index.md` | nested hub | `- If <sub-trigger> → read [intelligence/api/graphql/index.md](graphql/index.md)` |
| `intelligence/api/graphql/index.md` | deeper sub-file | `- If <sub-trigger> → read [intelligence/api/graphql/schema.md](schema.md)` |

## Moving a file re-bases every relative link in it

A relative link resolves from the folder of the file that **holds** it, so moving a file to a
different depth silently repoints every relative link in its body — `## Index` bullets, `## Shared`
prose, `## Reference` lists, inline links, all of them. Whenever a split, merge, or migration moves a
file, rewrite them all in the same edit:

- **One level deeper** (`intelligence/<topic>.md` → `intelligence/<topic>/index.md`): a target that
  starts with `<topic>/` loses that prefix (`(<topic>/rest.md)` → `(rest.md)`); **every other**
  relative target gains `../` (`(code-guidelines.md)` → `(../code-guidelines.md)`).
- **One level shallower** (`intelligence/<topic>/index.md` → `intelligence/<topic>.md`): a leading
  `../` is dropped; a bare sibling target gains the `<topic>/` prefix.
- Leave absolute URLs, repo-root paths, and bare `#anchor` links alone.

Then confirm: every relative target in the moved file resolves to a file that exists. Label text is
repo-relative and never changes — only the target in parentheses moves.

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

## The machine-local layer (`intelligence/local/`)

`intelligence/local/` is a **gitignored hub** holding rules that are true only on this user's
machine. Every layer has one — it is created by `/intel setup` and by migration `M004`, never
opted into. It is a normal hub in every structural respect (own `index.md`, sub-files, nesting to
any depth, same "Shape of an intelligence file" rules), with four differences:

1. **Never indexed from `intelligence/index.md`.** The root index is tracked; a bullet pointing at
   a gitignored folder dangles for every teammate. Discovery happens through the canonical
   preamble's rule 7 and through the `intel-haiku.sh` hook, which injects both indexes on every
   prompt.
2. **`local` is reserved at the top level.** `intelligence/local.md` must never exist, and
   `/intel add local` is refused — the name always means this hub.
3. **Gitignored in the repo's `.gitignore`**, via the exact line `intelligence/local/`.
4. **Precedence:** a local file wins on environment facts (where a tool lives on this machine,
   which personal plugin/agent is installed, this workstation's paths, ports, and versions). It
   must never restate or override a project convention — when a local rule contradicts a tracked
   rule about the project itself, the tracked rule wins and the conflict is reported.

### What belongs in `intelligence/local/`

Machine-local — route here:

- Rules that depend on the user's personal plugins, agents, skills, or slash commands.
- Absolute paths under `$HOME`, personal dotfiles, shell aliases, or editor setup.
- Tool locations, versions, or credentials paths specific to this workstation.
- Local service ports, container names, or database instances the team does not share.
- Personal workflow preferences that no teammate is expected to follow.
- Anything naming a specific branch, PR/MR, issue, ticket, or commit SHA — an instance, not a
  convention.
- Scratchpad and temp-file paths, and one-off command output, log excerpts, or stack traces from a
  session.
- Example sets, fixture data, or reproduction steps gathered from a single investigation.

Project-shared — route to the tracked layer:

- Anything derived from the repo's own code, config, scripts, or CI.
- Conventions a teammate on a fresh clone must also follow.
- Commands defined by the project (`package.json` scripts, Makefile targets, `composer.json`).
- The general rule behind an instance-specific observation, stated without the branch, PR number,
  path, or output that revealed it.

### Generalize first, then route

An observation that names a branch, a PR, a ticket, a scratchpad path, or one session's output is
an **instance**. Split it before routing: the durable general rule goes to the tracked layer, the
instance itself goes to `intelligence/local/`.

| Observed | Tracked layer gets | Local layer gets |
|----------|--------------------|------------------|
| `feat/checkout-v2` broke until `npm run codegen` ran after pulling schema changes | "Run `npm run codegen` after any schema change" | — |
| Review on PR #412 rejected inline SQL twice | "Use the query builder — inline SQL is rejected in review" | — |
| A scratchpad script reproduced the cache race | the reproduction pattern, if it holds generally | the script's path, when the user keeps reusing it |
| The local `api` container is named `acme-api-ian` | — | the container name |

- Never let a tracked file carry the instance.
- When nothing durable remains after extracting the general rule, save only the general rule — do
  not create a local file to hold the leftover instance.
- Instance facts go stale fast: delete them from the local layer once the branch merges or the PR
  closes.

### Shape of `intelligence/local/index.md`

```markdown
# Machine-local intelligence index

Index of machine-local instructions — rules that hold only on this workstation. This folder is
gitignored: nothing here is shared with the team.

## How to use this index

1. **Match the same way as the project index.** Read every file whose `If <trigger>` matches the
   task at hand, before acting.
2. **Environment facts only.** These files describe this machine — personal plugins, personal
   paths, local services, personal workflow. Project conventions live in the tracked
   `intelligence/` layer and always win on questions about the project itself.
3. **Keep it out of git.** Never move content from here into a tracked `intelligence/*.md` file
   without the user's explicit approval.

## Index

- If <trigger A> → read [intelligence/local/<topic-a>.md](<topic-a>.md)
```

The preamble (`# Machine-local intelligence index` through end of `## How to use this index`) is
**fixed**. Only the `## Index` bullets change. A freshly created local layer has an empty
`## Index` section — that is valid, not a gap.

### Creating the local layer

Whenever a branch must ensure the local layer exists (`setup`, `add` routing local, `M004`):

1. Create `intelligence/local/`.
2. Write `intelligence/local/index.md` with the fixed preamble above and an empty `## Index`.
3. Ensure the repo's `.gitignore` contains the exact line `intelligence/local/`; create
   `.gitignore` with that single line when the file does not exist, append it (on its own line)
   when the line is absent, and change nothing when it is already present.

## Shape of `intelligence/index.md`

```markdown
# Project intelligence index

Index of project instructions. Read the referenced file when its trigger matches.

## How to use this index

1. **Scan first, match liberally.** Every task: match against the `If <trigger>` bullets below and read
   each matching intelligence file in full before acting — when unsure whether a trigger applies, read
   it anyway. If a bullet points at a hub (`intelligence/<topic>/index.md`), match its sub-triggers the
   same way and read only the matching sub-file(s).
2. **Multiple triggers are normal.** A change can touch tests + migrations + API surface at once;
   read every matching file and apply all of them.
3. **Apply the rules during work, not after.** The intelligence files describe required practices
   (commands to run, files to update in lockstep, conventions to follow), not optional reading.
4. **Keep the intelligence up to date.** If you change behaviour that an intelligence file documents
   (e.g. a command name changes, a folder moves, a convention is dropped or added), update the matching
   intelligence file in the same change so the next reader doesn't get stale guidance. If a new
   recurring practice emerges that isn't covered yet, add a new `intelligence/<topic>.md` and link it
   from the index below.
5. **Fix mistakes on sight.** If, while working with an intelligence file, you find anything wrong —
   wrong path, wrong command, outdated rule, contradicts the current code, typo that changes meaning —
   fix it in the file as part of the current change. Don't leave a broken instruction in place for the
   next reader to trip over.
6. **Read the machine-local layer when present.** If `intelligence/local/index.md` exists, match its
   `If <trigger>` bullets the same way and read every matching file. It is gitignored, so its
   absence is normal — never treat a missing local layer as an error, and never move its content
   into a tracked file.
7. **Check the system-wide layer for local-app configs.** When the task touches configuration of
   local apps / dotfiles under `~/.config/`, also read `~/.config/intelligence/index.md` and scan
   its own index — it carries cross-config hooks and machine-wide intel that span configs beyond
   this repo.

## Index

- If <trigger A> → read [intelligence/<topic-a>.md](<topic-a>.md)
- If <trigger B> → read [intelligence/<topic-b>/index.md](<topic-b>/index.md)
...
```

The preamble (`# Project intelligence index` through end of `## How to use this index`) is **fixed**.
Only the `## Index` bullets change between projects. When rewriting `intelligence/index.md`, preserve
the preamble verbatim.

## Shape of `CLAUDE.md`

`CLAUDE.md` is **not** the index. It carries one fixed stanza pointing at the index, followed by
whatever the user keeps there that the intelligence layer did not put there:

```markdown
# CLAUDE.md

## Project intelligence

This project's instructions live in an intelligence layer. **Read
[intelligence/index.md](intelligence/index.md) first, every task**, and follow it: match its
`If <trigger>` bullets and read every matching file in full before acting.

When dispatching a subagent, include in its prompt: "Read intelligence/index.md and every matching
intelligence file before starting."
```

The `# CLAUDE.md` heading and the whole `## Project intelligence` stanza are **fixed** — reproduce
them verbatim. Everything below the stanza is user content: preserve it verbatim, in its original
order, and never delete a section the intelligence layer does not own.
