# Hooks

Hooks live at `plugins/<plugin>/hooks/`: a `hooks.json` manifest plus the scripts it invokes.
Installing the plugin registers the hooks — no user `settings.json` edits needed.

## hooks.json shape

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh\"" } ] }
    ]
  }
}
```

- Reference scripts via `${CLAUDE_PLUGIN_ROOT}` — never a hardcoded path.
- `type: "command"` hooks run in a normal shell (no agent/tools), receive the event JSON on stdin,
  and must never block the prompt.

## Authoring rules (command hooks)

- **Fail-safe: degrade, never error.** On any missing dependency or failure, exit cleanly with
  reduced output. `intel-haiku.sh` degrades in order: no `jq` / `cwd` / `CLAUDE.md` → `exit 0`
  (silent); no `claude` CLI or empty prompt → emit index only; selector failure → index only.
- **Guard against recursion.** A hook that calls `claude -p` re-fires the same hook in the child.
  Set a sentinel env var on the child and exit early when present:
  `case "${CLAUDE_INTEL_SELECTOR:-}" in 1) exit 0 ;; esac`, invoking the child with
  `CLAUDE_INTEL_SELECTOR=1 ... claude -p ...`.
- **Headless subagent = subscription auth.** `claude -p --model claude-haiku-4-5-20251001` runs
  under the user's subscription — **no API key**. Also set `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS=1`
  on the child to keep it lean.
- **Emit the documented envelope:** print
  `{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}`, built with `jq -n`.

## Portability

Scripts must run on macOS (bash 3.2 / BSD userland) **and** Linux:

- Target bash 3.2 — no bash-4 features (associative arrays, `${var,,}`). Lowercase via `tr`.
- `timeout` is absent on stock macOS — probe and degrade to an unbounded call:
  `if command -v timeout ...; then timeout_cmd="timeout 60"; else timeout_cmd=""; fi`.
- Use `printf`, not `echo -e`; POSIX `grep -oE` / `case` globs over GNU-only flags.
- Optional dependencies (`jq`, `claude`) are probed with `command -v`.

## Reference: intel-haiku.sh (intel plugin's UserPromptSubmit hook)

On every prompt in a project whose cwd root has a `CLAUDE.md`, it:

1. Injects the `CLAUDE.md` index as context.
2. Resolves plan references in the prompt (plan-md ids: 3-char lowercase-alphanumeric like `a3f`;
   legacy numerics `11` → `plans/011-*.plan.md`) and feeds matched plan files as evidence.
3. Expands hubs — any `intelligence/**/*.md` containing a `## Index` section is a hub; its body is
   appended to the selector input so nested sub-files (any depth) can be selected directly.
4. Asks headless Haiku which `intelligence/*.md` files match, then injects the selected files in full.

No-ops instantly when the cwd root has no `CLAUDE.md`.
