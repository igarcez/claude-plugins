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
  under the user's subscription — **no API key**. Keep the child lean: set
  `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS=1` and pass `--strict-mcp-config` (a tool-less selector never
  needs MCP servers; skipping them cuts several seconds of startup per prompt).
- **Bound every headless child call below the harness hook timeout.** The harness kills the whole
  hook at its timeout (60s default; raise per command with a `"timeout"` field in `hooks.json`, in
  seconds — the intel hook uses 120). A killed hook emits NOTHING, losing even the fallback output,
  so the child call must die first: bound it with the watchdog pattern below and degrade instead.
  Real numbers from `intel-haiku.sh` on a warm mac: minimal child call ≈ 3.5s, typical prompt ≈ 9s,
  `/plan-md execute` prompt (largest selector payload) ≈ 20s — API-latency tails cross 60s.
- **Emit the documented envelope:** print
  `{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}`, built with `jq -n`.

## Portability

Scripts must run on macOS (bash 3.2 / BSD userland) **and** Linux:

- Target bash 3.2 — no bash-4 features (associative arrays, `${var,,}`). Lowercase via `tr`.
- `timeout` is absent on stock macOS — never rely on it. Bound long child calls with a plain-bash
  watchdog instead (single code path on both platforms): run the child in the background writing to a
  `mktemp` file, spawn a subshell that polls `kill -0` once per second up to the bound and then kills
  the child, `wait` for the child, kill+reap the watchdog, read the temp file. See the selector call
  in `intel-haiku.sh` (bound env-overridable via `CLAUDE_INTEL_SELECTOR_TIMEOUT`, default 40s).
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
