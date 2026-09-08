# Skills

Skills live at `plugins/<plugin>/skills/<skill>/SKILL.md`. They are loaded on demand by a command
dispatcher (or the user) and invoked as `<plugin>:<skill>` (e.g. `intel:setup`, `plan-md:php`).

## Frontmatter

```yaml
---
name: <skill>            # must match the skills/<skill>/ folder name
description: "<when to use it>"
---
```

- `name` must equal the folder name (`skills/setup/` → `name: setup`).
- The body starts with an `# <Heading>` followed by the skill's instructions.
- `allowed-tools` is optional — add it only when the skill runs a bundled script (see Bundled scripts).

## Description conventions

- **Internal skills** (loaded only by a command dispatcher) end the
  `description` with: *"Internal: loaded by the <plugin> command; not a standalone task."* — see
  `plugins/intel/skills/add/SKILL.md`, `plugins/plan-md/skills/new/SKILL.md`.
- **Stack / reference skills** state their activation condition on the first body lines
  (e.g. `plan-md:php` — "Apply when project contains `composer.json`, `*.php`, or `artisan`").
- **Lockstep with the body.** When a skill's scope changes, update its frontmatter `description` and
  any branch list in its opening lines in the same edit — both name what the skill covers, and the
  dispatcher and the skill picker read the `description`.
- **Cross-references inside the body.** Renaming a numbered step or a bolded step heading leaves
  other steps pointing at the old name. Grep the skill body for the old wording and update every
  reference in the same edit — `plan-md:execute` step 2 guards against proceeding to step 3 by name.

## Bundled scripts

A skill that ships a helper script keeps it in `skills/<skill>/scripts/`, invokes it through
`${CLAUDE_SKILL_DIR}` in the body, and repeats the same path in `allowed-tools` so running it needs
no permission prompt:

```yaml
---
name: new
description: "..."
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/new-plan-id.sh)
---
```

- Ship the script executable (`chmod +x`) and invoke it directly — no `bash <path>` prefix.
- `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PLUGIN_ROOT}` are substituted both in the skill body and in
  `allowed-tools` Bash rules; use `${CLAUDE_PLUGIN_ROOT}` only for files shared across skills.
- Keep the script self-contained (no network at run time) and portable per the rules in
  [hooks.md](hooks.md) — bash 3.2, POSIX tools.
- State in the skill body what to do when the script is unavailable, so the branch still works.
- Fetching the data to embed: `curl` to `raw.githubusercontent.com` is rate-limited from a sandboxed
  session (HTTP 429/503, every retry). Use `gh api <owner>/<repo>/contents/<path> --jq .content |
  base64 -d` instead, and verify the payload (sha256 + a shape check) so the transport swap can't
  change what gets embedded.

## Shared-reference skill

A plugin may ship skills that other branches load first for shared definitions: `intel:shape` (the
intelligence-file, `intelligence/index.md`, and `CLAUDE.md` shapes) and `intel:migrations` (the
numbered layer-migration registry read by `intel:setup`, `intel:maintain`, and `intel:upgrade`). Load
them before any branch that writes against those shapes, and mark their `description` internal.

## Reference

- `plugins/intel/skills/`, `plugins/plan-md/skills/` — every skill follows this shape.
- `plugins/plan-md/skills/new/scripts/new-plan-id.sh` — canonical bundled script (embeds its
  2048-word BIP39 list so id generation needs no network or data file).
