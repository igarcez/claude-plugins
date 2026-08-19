# Plugins

This repo is a Claude Code plugin **marketplace monorepo**: one directory per plugin under
`plugins/<name>/`, all registered in a single marketplace manifest.

## Layout

- `.claude-plugin/marketplace.json` — marketplace manifest (lists every plugin).
- `plugins/<name>/.claude-plugin/plugin.json` — per-plugin manifest.
- `plugins/<name>/commands/*.md` — slash commands. See [commands.md](commands.md).
- `plugins/<name>/skills/<skill>/SKILL.md` — skills. See [skills.md](skills.md).
- `plugins/<name>/skills/<skill>/scripts/` — helper scripts bundled with a skill. See [skills.md](skills.md).
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

## Versioning

Bump the `version` in `plugins/<name>/.claude-plugin/plugin.json` on **every** change to that plugin.
Versions are per-plugin and independent; only `plugin.json` carries a version — `marketplace.json`
does not. Follow semver:

| Change | Bump | Example |
|--------|------|---------|
| Breaking change | major | `1.4.2` → `2.0.0` |
| New feature | minor | `1.4.2` → `1.5.0` |
| Fix | patch | `1.4.2` → `1.4.3` |

## Plugin state on the user's machine

A plugin that must remember something between runs writes the file itself — there is no plugin-state
API. Where it goes:

| Scope | Path | Use |
|-------|------|-----|
| Per-user | `${XDG_STATE_HOME:-$HOME/.local/state}/<plugin>/` | Ledgers, caches, cross-project state |
| Per-project | `<repo>/.claude/<plugin>/` (gitignored when machine-local) | State the repo owns |
| Per-session/turn | `${TMPDIR:-/tmp}/<plugin>-<session_id>-<prompt_id>` | Dedupe markers, recursion guards |

Rules:

- **Never write inside `${CLAUDE_PLUGIN_ROOT}`.** It is a versioned cache
  (`~/.claude/plugins/cache/<owner>/<plugin>/<version>/`) replaced on every plugin update — state
  written there disappears.
- Key per-user state by the layer/repo it describes (repo root with `/` → `-`), never globally, or one
  repo's state leaks into another.
- `mkdir -p` first, and treat every write as optional: `|| exit 0` in a hook, never block the prompt.
- Offer an env override for testing (`CLAUDE_INTEL_STATE_DIR` in the intel plugin).
- Prune what accumulates — `intel-capture.sh` deletes its turn markers after 7 days.
- Concurrent sessions race on the same file: append, or write-then-`mv`, rather than rewriting.

The intel plugin's applied-migration ledger (`intel:migrations`) is the canonical example.

## Reference

- `.claude-plugin/marketplace.json`, `plugins/intel/.claude-plugin/plugin.json`,
  `plugins/plan-md/.claude-plugin/plugin.json` — canonical manifests.
