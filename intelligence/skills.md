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

## Description conventions

- **Internal skills** (loaded only by a command dispatcher, never run standalone) end the
  `description` with: *"Internal: loaded by the <plugin> command; not a standalone task."* — see
  `plugins/intel/skills/add/SKILL.md`, `plugins/plan-md/skills/new/SKILL.md`.
- **Stack / reference skills** state their activation condition on the first body lines
  (e.g. `plan-md:php` — "Apply when project contains `composer.json`, `*.php`, or `artisan`").
- **Lockstep with the body.** When a skill's scope changes, update its frontmatter `description` and
  any branch list in its opening lines in the same edit — both name what the skill covers, and the
  dispatcher and the skill picker read the `description`, not the body.

## Shared-reference skill

A plugin may ship skills that other branches load first for shared definitions: `intel:shape` (the
intelligence-file, `intelligence/index.md`, and `CLAUDE.md` shapes) and `intel:migrations` (the
numbered layer-migration registry read by `intel:setup`, `intel:maintain`, and `intel:upgrade`). Load
them before any branch that writes against those shapes, and mark their `description` internal.

## Reference

- `plugins/intel/skills/`, `plugins/plan-md/skills/` — every skill follows this shape.
