---
name: maintain
description: "Branch of /intel: audit the intelligence layer end-to-end (subcommand maintain). Internal: loaded by the intel command; not a standalone task."
---

# intel maintain

Audit the intelligence layer end-to-end. Do not modify code outside the intelligence layer and
`CLAUDE.md` unless the user explicitly approves.
Requires the shared shapes from the `intel:shape` skill — load it first if it is not already in context.

## 1. Index ↔ files consistency

The layer nests to **any depth**: `CLAUDE.md` indexes top-level `intelligence/<topic>.md` files, and
any **hub** (a file whose body is a `## Index`) indexes its sub-files in the sibling folder named
after it — recursively. Audit every level.

- List every `intelligence/**/*.md` (files at all depths).
- Classify each file, at every depth, as a **leaf** (normal content) or a **hub** (body is an
  `## Index` of `If <sub-trigger> → read ...` bullets).
- `CLAUDE.md` ↔ top level — report:
  - Top-level files present but **not** indexed → propose an index bullet (ask the user for the
    `If <trigger>` wording via `AskUserQuestion`, then add).
  - Index entries pointing to **missing** files → propose either creating the file (run the `add`
    flow scoped to that topic) or removing the index line. Ask which.
  - Duplicate index entries for the same file → consolidate.
- Each hub ↔ its sibling folder — apply the same three checks at every depth, recursively:
  sub-files present but absent from the hub's `## Index`; hub bullets pointing at missing sub-files;
  duplicate sub-entries. A hub with an empty or single-entry folder is a merge candidate (step 3b),
  at any depth.

## 2. Preamble drift

Compare the `# CLAUDE.md` and `## How to use this index` block against the canonical preamble in
"Shape of `CLAUDE.md`" in `intel:shape`. If it has drifted (wording changes, missing rules), report
the diff and offer to restore the canonical preamble. Do not silently overwrite.

## 2a. Citation-convention presence

Ensure the project records the code-citation convention (see "Citing code locations" in `intel:shape`)
so future authors — and agents that read the intelligence layer without running this command — follow
it. Check for an intel file documenting it: a dedicated `intelligence/intel-citations.md`, or a
`## Citing code locations` section in an existing conventions/code-style file.

If absent, treat as a **safe fix**: create `intelligence/intel-citations.md` from the "Citing code
locations" rules in `intel:shape`, add an index bullet (`If writing or editing any intelligence/*.md
file, or citing a code location → read intelligence/intel-citations.md`), and list it in the report.
This is how the convention propagates into every project the skill maintains.

## 3. Per-file accuracy audit — fan out subagents

Auditing every file inline floods the main context with code reads that matter only long enough to
produce a finding. Instead, dispatch **one subagent per leaf/sub-file** (a hub's accuracy is its
`## Index`, covered in step 1) — all in a single message so they run in parallel. Dispatch the
step-5 coverage-gap agent in the same batch. Subagents cannot talk to the user: they verify, apply
safe fixes in their own file, and report; every judgement call bubbles up through their report.

Each auditor's prompt must contain:

- The assigned file's path, and that it may edit **only that file** — everything else is read-only.
- The audit checklist:
  - Re-verify every command (Makefile targets, npm/composer scripts, binaries) still exists with
    the same signature.
  - Re-verify every path/glob still resolves.
  - Spot-check cited conventions against 1–2 real files.
  - Re-verify cited **code locations**: each symbol / quoted-string anchor still resolves, and any
    `:line` is current — refresh drifted line numbers by **re-grepping the symbol**, never by
    hand-counting.
  - Check for contradictions between the file and current code (e.g. file says "tests live in
    `tests/`" but tests now live in `spec/`).
- The full "Citing code locations" rules copied from `intel:shape` — a subagent does not inherit
  your loaded skills; the rules must travel in the prompt.
- Authority to apply **safe fixes** directly in its assigned file: typos, wrong paths, renamed
  commands with an obvious replacement, drifted `:line` refreshes. Everything else is report-only.
- The report format to return:
  - `status`: OK | drift-minor (fixed) | drift-major
  - `fixes`: safe fixes applied (exact line, before → after)
  - `major`: drift-major items (exact line, what is wrong, proposed correction)
  - `structure`: line count; distinct sub-areas covered; split candidate yes/no, and if yes the
    proposed sub-files with an `If <sub-trigger>` each (criteria in step 3b)
  - `contradictions`: file-vs-code conflicts found

Collect all reports before continuing. Trust them — do not re-verify audited items in the main
thread; spot-check only a report that is internally inconsistent.

## 3b. Structure audit — split over-broad files, merge decayed hubs

The aim is the **narrowest context per request**: a reader should rarely load a file far larger than
the task needs. Judge the `structure` signals from the step-3 auditor reports, plus the hub shapes
from step 1, against the split/merge criteria (see "When a file grows too broad: split into a
sub-index" in `intel:shape`) — no re-reading of the files themselves should be needed.

- **Split candidates.** Flag any leaf where all three hold: it is past ~150 lines or visibly
  sprawling; it covers ≥3 sub-areas whose triggers rarely co-occur (a reader for one task needs one
  section and never the others); and splitting would cut what a typical reader loads. For each
  candidate, propose the split via `AskUserQuestion` — list the proposed sub-files and the
  `If <sub-trigger>` for each, and let the user reassign/rename. On approval:
  1. Create the `intelligence/<topic>/` folder.
  2. Move each section into `intelligence/<topic>/<sub>.md`, preserving its rules verbatim and
     re-grepping any cited code locations (never hand-count lines — see "Citing code locations"
     in `intel:shape`).
  3. Rewrite `intelligence/<topic>.md` as a hub: optional `## Shared` core (rules every sub-topic
     needs) + a `## Index` of the new sub-triggers.
  4. Leave the `CLAUDE.md` bullet pointing at the hub; broaden its `If <trigger>` wording to the
     whole area if it was specific to the old flat file.
- **Merge candidates.** Flag any hub whose folder now holds 0–1 sub-files, or whose sub-files are
  each tiny and always read together. Propose collapsing back to a flat `intelligence/<topic>.md`
  via `AskUserQuestion` (fold the sub-files' content back in, delete the folder).

Splitting and merging are **judgement calls** — never restructure silently; confirm via
`AskUserQuestion` first, then apply in step 4.

## 4. Apply fixes

Per-file safe fixes were already applied by the step-3 auditors — carry their `fixes` lists into the
report. What remains for the main thread:

- **Cross-file safe fixes** (index bullets from step 1, the citation-convention file from step 2a) —
  apply directly and list what changed.
- **Judgement calls** (drift-major items, rule no longer applies, convention has shifted, file should
  be split or merged) — surface via `AskUserQuestion` before changing anything, then apply what the
  user approves.

## 5. Coverage gap check

Run as a subagent, dispatched in the same batch as the step-3 auditors. Its prompt: scan recent
commits (`git log --since='3 months ago' --name-only`) for recurring workflow signals, compare them
against the `CLAUDE.md` index (include the index in the prompt), and return candidate topics not
covered by any intelligence file (e.g. lots of changes under `infra/` with no intelligence file) —
report-only, no writes. For each returned gap, ask the user whether to add a new intelligence file
via `/intel add <topic>`.

## 6. Report

Print a structured summary:

```
Intelligence audit
==================
Index ↔ files:       <N OK, M issues fixed, K issues raised>
Preamble:            <ok | drifted, restored | drifted, awaiting decision>
Citation convention: <present | added intel-citations.md>
Per-file accuracy:   <N OK, M drift-minor (fixed), K drift-major (raised)>
Structure:           <N splits, M merges — proposed/applied; sub-files touched>
Coverage gaps:       <list of topics flagged for the user>

Changes applied:
- <file>: <one-line summary>
...

Open decisions:
- <question>
...
```

Do not commit. Leave the user to review and stage.
