---
name: upgrade
description: "Branch of /intel: detect and apply pending intelligence-layer migrations (subcommand upgrade). Internal: loaded by the intel command; not a standalone task."
---

# intel upgrade

Bring an existing intelligence layer up to the current layout. Requires the registry from
`intel:migrations` and the shapes from `intel:shape` — load both first if they are not already in
context.

## 1. Refuse when there is nothing to upgrade

If neither root `CLAUDE.md` nor `intelligence/` exists, tell the user *"No intelligence layer here —
run `/intel setup` first."* and stop.

## 2. Compute the pending set

Follow "How to compute the pending set" in `intel:migrations`: read the layer's ledger, skip every id
already in it without running its Detect, run Detect for the rest, and append any non-firing id as
`baseline`.

## 3. Stop when already current

If the pending set is empty, report *"Intelligence layer already current (ledger has M001–M`<nnn>`)."*
and stop.

## 4. Apply

Apply each pending migration's **Fix** in id order, immediately — do **not** ask for confirmation.
After each Fix, run that migration's **Verify**; on success append `M<nnn> <UTC timestamp> applied` to
the ledger before starting the next id. On a failed Verify, write **no** ledger line — stop before the
next migration and report exactly what failed and what was left half-applied.

## 5. Report

```
Intelligence upgrade
====================
Applied:   <ids + titles, or "none">
Baseline:  <ids recorded without work, or "none">
Skipped:   <ids already in the ledger>
Failed:    <id + what failed, or "none">
Ledger:    <absolute path to the ledger file>

Files written:
- <path>: <one-line summary>

Needs review:
- <generated index triggers, unresolved bullet targets, anything a Fix flagged>
```

Do not commit. Leave the user to review and stage.
