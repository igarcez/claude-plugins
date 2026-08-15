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
6. **Check the system-wide layer for local-app configs.** When the task touches configuration of
   local apps / dotfiles under `~/.config/`, also read `~/.config/intelligence/index.md` and scan
   its own index — it carries cross-config hooks and machine-wide intel that span configs beyond
   this repo.

## Index

- If changing any plugin (manifest, command, skill, or hook), registering a new plugin, storing plugin state on the user's machine, or preparing to publish (monorepo layout, manifest shapes, version bumps) → read [intelligence/plugins.md](plugins.md)
- If authoring or editing a slash command (`commands/*.md`, frontmatter, `$ARGUMENTS`, dispatcher routing to skills) → read [intelligence/commands.md](commands.md)
- If authoring or editing a skill (`skills/<name>/SKILL.md`, frontmatter, internal-skill convention, `plugin:skill` naming) → read [intelligence/skills.md](skills.md)
- If authoring or editing a hook (`hooks/hooks.json`, hook shell scripts, `${CLAUDE_PLUGIN_ROOT}`, portability, fail-safe/recursion) → read [intelligence/hooks.md](hooks.md)
