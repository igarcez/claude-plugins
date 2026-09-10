#!/usr/bin/env bash

case "${CLAUDE_INTEL_CAPTURE:-1}" in 0) exit 0 ;; esac

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

case "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" in true) exit 0 ;; esac

[ -z "$(printf '%s' "$input" | jq -r '.agent_id // empty')" ] || exit 0

cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
[ -n "$cwd" ] || exit 0
if [ ! -f "$cwd/intelligence/index.md" ] && [ ! -f "$cwd/intelligence/local/index.md" ]; then exit 0; fi

session_id="$(printf '%s' "$input" | jq -r '.session_id // empty')"
[ -n "$session_id" ] || exit 0
prompt_id="$(printf '%s' "$input" | jq -r '.prompt_id // empty')"
[ -n "$prompt_id" ] || prompt_id="session"

case "$session_id$prompt_id" in *[!A-Za-z0-9._-]*) exit 0 ;; esac

key="${TMPDIR:-/tmp}/intel-capture-${session_id}-${prompt_id}"
[ -e "$key" ] && exit 0
: > "$key" 2>/dev/null || exit 0
find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'intel-capture-*' -mtime +7 -delete 2>/dev/null

ctx="Intel check: anything durable from this turn worth \`/intel add\` — project-shared, or machine-local (personal tooling, \$HOME paths, this-workstation-only facts) into intelligence/local/ — or any intelligence rule this turn proved wrong (fix or remove)? One line, or stay silent."

jq -n --arg c "$ctx" '{hookSpecificOutput:{hookEventName:"Stop",additionalContext:$c}}'
