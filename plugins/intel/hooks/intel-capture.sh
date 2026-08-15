#!/usr/bin/env bash
# intel-capture.sh — intel plugin's Stop hook. See intelligence/hooks.md.
#
# At the end of every main-thread turn in a project that has an intelligence layer, inject a
# one-line self-check: is anything this turn established worth /intel add, or did the turn prove
# an existing intelligence/*.md rule wrong? The main model is the judge — no child model call.

case "${CLAUDE_INTEL_CAPTURE:-1}" in 0) exit 0 ;; esac

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

# additionalContext on a Stop hook continues the conversation, so this hook can re-fire on the
# continuation it caused. First guard: the harness flags a stop that a hook already blocked.
case "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" in true) exit 0 ;; esac

# Registered Stop hooks are converted to SubagentStop for subagents; only the main thread checks.
[ -z "$(printf '%s' "$input" | jq -r '.agent_id // empty')" ] || exit 0

cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
[ -n "$cwd" ] || exit 0
[ -f "$cwd/intelligence/index.md" ] || exit 0

session_id="$(printf '%s' "$input" | jq -r '.session_id // empty')"
[ -n "$session_id" ] || exit 0
prompt_id="$(printf '%s' "$input" | jq -r '.prompt_id // empty')"
[ -n "$prompt_id" ] || prompt_id="session"

# Both ids are harness-generated; refuse anything that is not filename-safe rather than sanitize.
case "$session_id$prompt_id" in *[!A-Za-z0-9._-]*) exit 0 ;; esac

# Second guard, and the once-per-user-turn rule: write the marker BEFORE emitting, so the
# continuation this injection triggers finds it and exits silently.
key="${TMPDIR:-/tmp}/intel-capture-${session_id}-${prompt_id}"
[ -e "$key" ] && exit 0
: > "$key" 2>/dev/null || exit 0
find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'intel-capture-*' -mtime +7 -delete 2>/dev/null

ctx="Intel check: anything durable from this turn worth \`/intel add\`, or any intelligence/*.md rule this turn proved wrong (fix or remove)? One line, or stay silent."

jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"Stop",additionalContext:$c}}'
