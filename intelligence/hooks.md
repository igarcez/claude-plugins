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

- Reference scripts via `${CLAUDE_PLUGIN_ROOT}`.
- `type: "command"` hooks run in a normal shell (no agent/tools), receive the event JSON on stdin,
  and must exit so the prompt proceeds.
- One manifest registers many events — add a sibling key per event. The intel plugin registers
  `UserPromptSubmit` (`intel-haiku.sh`) and `Stop` (`intel-capture.sh`).

## Authoring rules (command hooks)

- **Fail-safe: degrade.** On any missing dependency or failure, exit cleanly with
  reduced output. `intel-haiku.sh` degrades in order: no `jq` / `cwd` → `exit 0` (silent); no
  `intelligence/index.md` → legacy-layout warning if a pre-2.0 layer is detected, else `exit 0`
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
  `{hookSpecificOutput:{hookEventName:"<event>",additionalContext:$c}}` built with `jq -n`, with
  `hookEventName` matching the event that fired.
- **Guard against continuation recursion (`Stop`).** `additionalContext` on a `Stop` hook
  *continues the conversation*, so the turn it injects ends in another `Stop` and re-fires the hook.
  Guard twice: exit when `.stop_hook_active` is `true`, and write a once-per-turn marker keyed
  `session_id` + `prompt_id` **before** emitting, exiting when it already exists. Registered `Stop`
  hooks are also converted to `SubagentStop`, so exit when `.agent_id` is non-empty unless
  subagent turns are meant to fire too.

- **Lockstep when a hook's trigger condition or env flag changes.** The condition ("fires in a project
  that has X") and every env switch are stated in three places: the comment at the top of the hook
  script, the hook section of `plugins/<plugin>/README.md` (**both** its opening sentence and its
  numbered list — patching only the list leaves the section contradicting itself), and the matching
  `## Reference: <script>` section in `intelligence/hooks.md`. Update all three in the same change.

## Portability

Scripts must run on macOS (bash 3.2 / BSD userland) **and** Linux:

- Target bash 3.2 — no bash-4 features (associative arrays, `${var,,}`). Lowercase via `tr`.
- `timeout` is absent on stock macOS — bound long child calls with a plain-bash
  watchdog (single code path on both platforms): run the child in the background writing to a
  `mktemp` file, spawn a subshell that polls `kill -0` once per second up to the bound and then kills
  the child, `wait` for the child, kill+reap the watchdog, read the temp file. See the selector call
  in `intel-haiku.sh` (bound env-overridable via `CLAUDE_INTEL_SELECTOR_TIMEOUT`, default 40s).
- Use `printf`; POSIX `grep -oE` / `case` globs over GNU-only flags.
- Optional dependencies (`jq`, `claude`) are probed with `command -v`.

## Reference: intel-haiku.sh (intel plugin's UserPromptSubmit hook)

On every prompt in a project whose cwd root has an `intelligence/index.md` **or** an
`intelligence/local/index.md`, it:

1. Injects the `intelligence/index.md` index as context, plus the gitignored machine-local
   `intelligence/local/index.md` when it exists (`CLAUDE_INTEL_LOCAL=0` disables the local half).
   Either index alone is enough to run; a legacy-layout warning is prepended, not substituted, when
   the tracked index is missing but a local layer exists.
2. Resolves plan references in the prompt (plan-md ids: two hyphenated BIP39 words like
   `river-tiger`; legacy 3-char lowercase-alphanumeric like `a3f`; legacy numerics `11` →
   `plans/011-*.plan.md`) and feeds matched plan files as evidence.
3. Expands hubs — every `intelligence/<path>/index.md` is a hub (`find -mindepth 2 -name index.md`,
   which skips the already-injected root index); its body is appended to the selector input so nested
   sub-files (any depth) can be selected directly.
4. Asks headless Haiku which `intelligence/*.md` files match, then injects the selected files in full.
   The root `intelligence/index.md` is never re-injected as a selection.
5. Skips both `index.md` files when injecting the selector's answer — they are already in the
   context — and prunes `intelligence/local/index.md` from the hub scan while still expanding hubs
   nested inside the local layer.

When there is no `intelligence/index.md` but a pre-2.0 layer is detected (root `CLAUDE.md` with a
`## Index` section, or `intelligence/*.md` files), it emits a single line telling the user to run
`/intel upgrade` and loads nothing. No-ops instantly when neither is present.

## Reference: intel-capture.sh (intel plugin's Stop hook)

At the end of every main-thread turn in a project whose cwd root has an `intelligence/index.md` or an
`intelligence/local/index.md`, it injects a one-line self-check: is anything this turn established
worth `/intel add` (project-shared or machine-local), or did the turn prove an existing intelligence
rule wrong (fix or remove)? Claude answers in one line or stays silent.

- No child model call — the main model already holds the turn's context and is the judge, so the
  hook is instant and needs no `"timeout"` override.
- Fires at most once per user turn: marker `${TMPDIR:-/tmp}/intel-capture-<session_id>-<prompt_id>`,
  written before emitting, pruned after 7 days.
- Skips subagents (`.agent_id` non-empty) and continuations (`.stop_hook_active`).
- `CLAUDE_INTEL_CAPTURE=0` disables it without touching the auto-loading hook.
- No-ops instantly when `jq` is missing or the cwd root has neither `intelligence/index.md` nor
  `intelligence/local/index.md`.

## Reference: no-comments-guard.sh (no-comments plugin's PreToolUse hook)

Before every `Write` / `Edit` whose `tool_input.file_path` ends in `.ts .tsx .js .jsx .mjs .cjs
.php .go`, or matches `plans/*.plan.md`, it scans the *incoming* content — `content` for `Write`,
`new_string` for `Edit` — and denies the tool call when it adds a comment. In a test file it
allows bare Arrange/Act/Assert block markers.

- Denial envelope is the PreToolUse shape:
  `{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}`,
  exit 0. Allowing is expressed by printing nothing and exiting 0, never by a decision field.
- `plans/*.plan.md` is scanned through an `awk` fence extractor: only blocks tagged `ts`, `tsx`,
  `typescript`, `js`, `jsx`, `javascript`, `php`, `go` reach the detector.
- False positives are cut by stripping escapes and quoted spans (`sed`) before matching, so `//`
  inside a URL or a regex literal does not deny.
- `#` is a comment marker only for `.php` and for mixed-language plan fences; shebangs are
  exempted separately.
- Test paths (`*.test.*`, `*.spec.*`, `*_test.go`, `*Test.php`, `*_test.php`, or a `tests/`,
  `test/`, `__tests__/`, `spec/` path segment) set `is_test=1`, which filters offenders through
  `aaa_marker_pattern` — a comment whose whole content is `Arrange`, `Act`, or `Assert` with an
  optional trailing colon, exact capitalization. The filter runs as a separate `grep -vE` guarded
  by `[ -n "$offenders" ]`, never as an empty alternative inside `allow_pattern`, because
  `grep -vE ''` would drop every line and allow everything.
- `CLAUDE_NO_COMMENTS=0` disables it. Missing `jq`, empty stdin, unmatched extension, or empty
  content all exit 0 silently.
