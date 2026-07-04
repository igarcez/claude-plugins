# Plugins

This repo is a Claude Code plugin **marketplace monorepo**: one directory per plugin under
`plugins/<name>/`, all registered in a single marketplace manifest.

## Layout

- `.claude-plugin/marketplace.json` — marketplace manifest (lists every plugin).
- `plugins/<name>/.claude-plugin/plugin.json` — per-plugin manifest.
- `plugins/<name>/commands/*.md` — slash commands. See [commands.md](commands.md).
- `plugins/<name>/skills/<skill>/SKILL.md` — skills. See [skills.md](skills.md).
- `plugins/<name>/hooks/` — hooks (`hooks.json` + scripts). See [hooks.md](hooks.md).
- `plugins/<name>/README.md` — per-plugin usage doc.

## Adding a plugin (lockstep)

A plugin is invisible to the marketplace until registered. Three files change together:

1. Create `plugins/<name>/.claude-plugin/plugin.json`.
2. Add an entry to the `plugins` array in `.claude-plugin/marketplace.json`.
3. Add a row to the Plugins table in the root `README.md`.

Keep `name` identical across the folder name, the `plugin.json`, and the marketplace entry.

## marketplace.json shape

Top level: `name`, `description`, `owner` (`{name, url}`), `plugins` (array). Each `plugins` entry:

| Field | Value |
|-------|-------|
| `name` | plugin id, matches the `plugins/<name>/` folder |
| `source` | `./plugins/<name>` (relative path) |
| `description` | one-line summary |

## plugin.json shape

Fields used by both current plugins: `name`, `description`, `version` (semver, e.g. `1.0.0`),
`author` (`{name, url}`), `homepage`, `repository`, `license`, `keywords` (array).

## Reference

- `.claude-plugin/marketplace.json`, `plugins/intel/.claude-plugin/plugin.json`,
  `plugins/plan-md/.claude-plugin/plugin.json` — canonical manifests.
