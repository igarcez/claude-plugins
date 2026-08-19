#!/usr/bin/env bash
# intel-haiku.sh — intel plugin's UserPromptSubmit hook. See intelligence/hooks.md.

case "${CLAUDE_INTEL_SELECTOR:-}" in 1) exit 0 ;; esac

input="$(cat)"
command -v jq >/dev/null 2>&1 || exit 0

cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
prompt="$(printf '%s' "$input" | jq -r '.prompt // empty')"
[ -n "$cwd" ] || exit 0

emit() { jq -n --arg c "$1" '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}'; }

# Two indexes: the tracked intelligence/index.md and the gitignored, machine-local
# intelligence/local/index.md. Both are injected on every prompt; either one alone is enough to
# run. CLAUDE_INTEL_LOCAL=0 turns the local layer off without touching the tracked one.
index_file="$cwd/intelligence/index.md"
local_index_file="$cwd/intelligence/local/index.md"
case "${CLAUDE_INTEL_LOCAL:-1}" in 0) local_index_file="" ;; esac
if [ -n "$local_index_file" ] && [ ! -f "$local_index_file" ]; then local_index_file=""; fi

# A tracked layer without intelligence/index.md is on the legacy layout (index still inside
# CLAUDE.md): warn instead of loading it, and stay silent in projects with no layer at all.
warn=""
if [ ! -f "$index_file" ]; then
  legacy=0
  if [ -f "$cwd/CLAUDE.md" ] && grep -q '^## Index' "$cwd/CLAUDE.md" 2>/dev/null; then legacy=1; fi
  if [ "$legacy" -eq 0 ] && ls "$cwd"/intelligence/*.md >/dev/null 2>&1; then legacy=1; fi
  case "$legacy" in
    1) warn="Intelligence layer is on the legacy layout: no intelligence/index.md. Auto-loading of tracked intel files is OFF until it is migrated — tell the user to run \`/intel upgrade\`." ;;
  esac
  if [ -z "$local_index_file" ]; then
    case "$warn" in "") exit 0 ;; *) emit "$warn"; exit 0 ;; esac
  fi
fi

ctx=""
index=""
case "$warn" in "") ;; *) ctx="$warn"$'\n\n' ;; esac
if [ -f "$index_file" ]; then
  index="$(cat "$index_file")"
  ctx="$ctx""Project intel index (intelligence/index.md). Scan its If-triggers and read any matching intelligence file in full before acting:"$'\n\n'"$index"$'\n'
fi
local_index=""
if [ -n "$local_index_file" ]; then
  local_index="$(cat "$local_index_file")"
  case "$ctx" in "") ;; *) ctx="$ctx"$'\n' ;; esac
  ctx="$ctx""Machine-local intel index (intelligence/local/index.md — gitignored, rules for this workstation only). Scan its If-triggers the same way:"$'\n\n'"$local_index"$'\n'
fi

if ! command -v claude >/dev/null 2>&1 || [ -z "$prompt" ]; then emit "$ctx"; exit 0; fi

# Resolve plan references in the prompt as evidence (see intelligence/hooks.md).
evidence=""
seen_plan=" "
cands="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]' | grep -owE '[a-z]{3,8}-[a-z]{3,8}' | head -n 4)
$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]' | grep -owE '[a-z0-9]{3}' | head -n 8)
$(printf '%s' "$prompt" | grep -owE '[0-9]{1,3}' | head -n 4 | while IFS= read -r n; do [ -n "$n" ] && printf '%03d\n' "$((10#$n))"; done)"
for tok in $cands; do
  for plan in "$cwd"/plans/"$tok"-*.plan.md; do
    [ -f "$plan" ] || continue
    case "$seen_plan" in *" $plan "*) continue ;; esac
    seen_plan="$seen_plan$plan "
    evidence="$evidence"$'\n'"===== ${plan#$cwd/} (excerpt) ====="$'\n'"$(head -c 8000 "$plan")"$'\n'
  done
done

# Expand hubs so nested sub-files can be selected directly (see intelligence/hooks.md). Every hub is
# an intelligence/<path>/index.md; -mindepth 2 skips the root index, already in $ctx. The
# machine-local root index is already in $ctx too — skip it, but keep expanding hubs nested inside it.
hubs=""
if [ -d "$cwd/intelligence" ]; then
  while IFS= read -r hubfile; do
    [ -f "$hubfile" ] || continue
    case "$hubfile" in
      "$cwd/intelligence/local/index.md") continue ;;
    esac
    case "${CLAUDE_INTEL_LOCAL:-1}" in
      0) case "$hubfile" in "$cwd/intelligence/local/"*) continue ;; esac ;;
    esac
    hubs="$hubs"$'\n'"===== hub: ${hubfile#$cwd/} ====="$'\n'"$(head -c 4000 "$hubfile")"$'\n'
  done <<EOF
$(find "$cwd/intelligence" -mindepth 2 -name 'index.md' 2>/dev/null | head -n 20)
EOF
fi

selector_prompt="You are an intelligence-file selector. Do NOT use any tools or take any action; only answer.

Given the project's intelligence index, the user's prompt, and any referenced file contents, output ONLY the relative paths of the intelligence files whose rules are relevant to the user's task — one path per line, nothing else. Write each path repo-relative, starting with \`intelligence/\` (the index's bullet labels use that form; its link targets are relative to the index file). Never output \`intelligence/index.md\` or \`intelligence/local/index.md\` themselves. Decide relevance from each index bullet's If-trigger clause. Prefer recall: if a file might be relevant, include it. Match domain-specific files by the prompt and any referenced contents.

Some bullets point at hubs — an \`intelligence/<topic>/index.md\` whose body is itself an index of \`If <sub-trigger> → read ...\` bullets over the files in its folder (nested to any depth; a sub-topic can be a hub too — those indexes are listed below as well). When a hub's area matches the task, follow its index and output the matching SUB-FILE paths instead of only the hub; include the hub's own \`index.md\` only if it carries shared rules (a Shared section) that apply.

== Project index (intelligence/index.md) ==
${index:-none}

== Machine-local index (intelligence/local/index.md — gitignored, this workstation only) ==
${local_index:-none}

== Hub file indexes ==
${hubs:-none}

== User prompt ==
$prompt

== Referenced files ==
${evidence:-none}

Output the relevant intelligence file paths now, one per line:"

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
  case "$path" in intelligence/index.md|intelligence/local/index.md) continue ;; esac
  case "${CLAUDE_INTEL_LOCAL:-1}" in
    0) case "$path" in intelligence/local/*) continue ;; esac ;;
  esac
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
