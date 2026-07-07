#!/usr/bin/env bash
# intel-haiku.sh — intel plugin's UserPromptSubmit hook. See intelligence/hooks.md.

case "${CLAUDE_INTEL_SELECTOR:-}" in 1) exit 0 ;; esac

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
prompt="$(printf '%s' "$input" | jq -r '.prompt // empty')"
[ -n "$cwd" ] || exit 0
index_file="$cwd/CLAUDE.md"
[ -f "$index_file" ] || exit 0

index="$(cat "$index_file")"
header="Project intel index (CLAUDE.md). Scan its If-triggers and read any matching intelligence/*.md in full before acting:"
ctx="$header"$'\n\n'"$index"$'\n'

emit() { jq -n --arg c "$1" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}'; }

if ! command -v claude >/dev/null 2>&1 || [ -z "$prompt" ]; then emit "$ctx"; exit 0; fi

# Resolve plan references in the prompt as evidence (see intelligence/hooks.md).
evidence=""
seen_plan=" "
cands="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]' | grep -owE '[a-z0-9]{3}' | head -n 8)
$(printf '%s' "$prompt" | grep -owE '[0-9]{1,3}' | head -n 4 | while IFS= read -r n; do [ -n "$n" ] && printf '%03d\n' "$((10#$n))"; done)"
for tok in $cands; do
  for plan in "$cwd"/plans/"$tok"-*.plan.md; do
    [ -f "$plan" ] || continue
    case "$seen_plan" in *" $plan "*) continue ;; esac
    seen_plan="$seen_plan$plan "
    evidence="$evidence"$'\n'"===== ${plan#$cwd/} (excerpt) ====="$'\n'"$(head -c 8000 "$plan")"$'\n'
  done
done

# Expand hubs so nested sub-files can be selected directly (see intelligence/hooks.md).
hubs=""
if [ -d "$cwd/intelligence" ]; then
  while IFS= read -r hubfile; do
    [ -f "$hubfile" ] || continue
    hubs="$hubs"$'\n'"===== hub: ${hubfile#$cwd/} ====="$'\n'"$(head -c 4000 "$hubfile")"$'\n'
  done <<EOF
$(find "$cwd/intelligence" -name '*.md' -exec grep -l '^## Index' {} + 2>/dev/null | head -n 20)
EOF
fi

selector_prompt="You are an intelligence-file selector. Do NOT use any tools or take any action; only answer.

Given the project's CLAUDE.md index, the user's prompt, and any referenced file contents, output ONLY the relative paths of the intelligence/*.md files whose rules are relevant to the user's task — one path per line, nothing else. Decide relevance from each index bullet's If-trigger clause. Prefer recall: if a file might be relevant, include it. Match domain-specific files by the prompt and any referenced contents.

Some intelligence files are hubs: their body is itself an index of \`If <sub-trigger> → read ...\` bullets pointing at sub-files (nested to any depth; sub-files can be hubs too — their indexes are listed below as well). When a hub's area matches the task, follow its index and output the matching SUB-FILE paths instead of only the hub; include the hub itself only if it carries shared rules (a Shared section) that apply.

== CLAUDE.md index ==
$index

== Hub file indexes ==
${hubs:-none}

== User prompt ==
$prompt

== Referenced files ==
${evidence:-none}

Output the relevant intelligence/*.md paths now, one per line:"

# Bound the selector call with a watchdog instead of `timeout` (absent on stock macOS); an over-bound
# call is killed and the hook degrades to index-only instead of being killed whole by the harness's
# hook timeout. --strict-mcp-config: the selector needs no tools, so skip MCP server startup.
bound="${CLAUDE_INTEL_SELECTOR_TIMEOUT:-40}"
sel_file="$(mktemp "${TMPDIR:-/tmp}/intel-selector.XXXXXX")" || { emit "$ctx"; exit 0; }
CLAUDE_INTEL_SELECTOR=1 CLAUDE_CODE_DISABLE_BUNDLED_SKILLS=1 \
  claude -p --model claude-haiku-4-5-20251001 --strict-mcp-config "$selector_prompt" \
  >"$sel_file" 2>/dev/null &
claude_pid=$!
(
  waited=0
  while [ "$waited" -lt "$bound" ]; do
    sleep 1
    kill -0 "$claude_pid" 2>/dev/null || exit 0
    waited=$((waited + 1))
  done
  kill "$claude_pid" 2>/dev/null
) &
watchdog_pid=$!
wait "$claude_pid" 2>/dev/null
kill "$watchdog_pid" 2>/dev/null
wait "$watchdog_pid" 2>/dev/null
selected="$(cat "$sel_file" 2>/dev/null)"
rm -f "$sel_file"

matched=""
seen=" "
while IFS= read -r line; do
  path="$(printf '%s' "$line" | grep -oE 'intelligence/[A-Za-z0-9._/-]+\.md' | head -n1)"
  [ -n "$path" ] || continue
  case "$seen" in *" $path "*) continue ;; esac
  file="$cwd/$path"
  [ -f "$file" ] || continue
  seen="$seen$path "
  matched="$matched===== $path ====="$'\n'"$(cat "$file")"$'\n\n'
done <<EOF
$selected
EOF

if [ -n "$matched" ]; then
  ctx="$ctx"$'\n'"--- Auto-loaded relevant intel (Haiku-selected for this prompt; apply before acting) ---"$'\n\n'"$matched"
fi

emit "$ctx"
