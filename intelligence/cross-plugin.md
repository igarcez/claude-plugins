# Cross-plugin reuse

Plugins in this marketplace reuse each other by **loading the other plugin's skill**, never by
copying its rules.

## Rules

- Reuse a skill with the `Skill` tool and the `<plugin>:<skill>` name (`intel:add`,
  `intel:setup`, `intel:shape`), and list `Skill` in the calling command's `allowed-tools`.
- Treat the loaded skill as the owner of its domain: `/prime` passes a **bare kebab-case topic
  name** to `intel:add` and lets `intel:add` plus `intel:shape` decide leaf vs hub, collisions,
  index bullets, and link re-basing.
- Ship a degraded path for every cross-plugin dependency — the other plugin may not be installed.
  `/prime` falls back to writing one `## Engineering practices` section into `AGENTS.md` when
  `intel:setup` / `intel:add` cannot be loaded.
- Declare the dependency in the calling plugin's README (`plugins/prime/README.md` names intel as
  the writer) rather than in the manifest — `plugin.json` has no dependency field.
- Never restate the other plugin's rules in your own skill or command body; cite the skill name.

## Lockstep across plugins

A rule one plugin writes and another enforces changes in both, in the same commit, with both
versions bumped:

| Rule | Written by | Enforced by |
|------|-----------|-------------|
| Comment ban, with the bare Arrange/Act/Assert exception in test files | `prime`'s `comments` and `tests` topics | `no-comments`'s `no-comments-guard.sh` + `no-comments:style` |
| Output writing rules — point first, only what is in place, plain language per ISO 24495-1, chat replies included | `prose`'s `prose:prose` skill | `prose`'s `prose-style.sh`, plus `intel:add`, `pr-review:report`, and `pr-review:push` loading the skill |

When such a rule changes, follow the hook lockstep in [intelligence/hooks.md](hooks.md) (plugin
README opening sentence **and** numbered list, the `## Reference` section in
`intelligence/hooks.md`), and update the writing plugin's template in the same change.

One intelligence file's rule is often restated in another — this file restates the hook lockstep
that [intelligence/hooks.md](hooks.md) owns. Before calling an intelligence edit done, grep the
whole `intelligence/` tree for the old wording and update every restatement in the same change,
so a narrowed rule leaves no file naming the dropped step.

## Reference

- `plugins/prime/commands/prime.md` — canonical cross-plugin caller.
- `plugins/intel/skills/add/SKILL.md`, `plugins/intel/skills/shape/SKILL.md` — the reused skills.
- `plugins/prose/skills/prose/SKILL.md` — reused by `intel:add`, `pr-review:report`, and
  `pr-review:push`, each with a continue-without-it path.
