#!/usr/bin/env bash
# PreToolUse hook (Write|Edit). Fires on every Write/Edit whose target is a
# TypeScript/JavaScript/PHP/Go source file, or a plans/*.plan.md file (code fences only).
# Denies the call when the incoming content adds a comment that is not a machine-read
# pragma, a license header, or — in a test file — a bare Arrange/Act/Assert block marker.
# CLAUDE_NO_COMMENTS=0 disables it.
# Degrades silently (allow) on any missing dependency or unparseable input.

set -u

case "${CLAUDE_NO_COMMENTS:-1}" in
  0) exit 0 ;;
esac

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
[ -n "$input" ] || exit 0

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null) || exit 0
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null) || exit 0
[ -n "$file_path" ] || exit 0

case "$tool_name" in
  Write) content=$(printf '%s' "$input" | jq -r '.tool_input.content // ""' 2>/dev/null) ;;
  Edit)  content=$(printf '%s' "$input" | jq -r '.tool_input.new_string // ""' 2>/dev/null) ;;
  *) exit 0 ;;
esac
[ -n "$content" ] || exit 0

mode=""
language=""
case "$file_path" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) mode="code"; language="js" ;;
  *.go) mode="code"; language="go" ;;
  *.php) mode="code"; language="php" ;;
  */plans/*.plan.md|plans/*.plan.md) mode="fences" ;;
  *) exit 0 ;;
esac

is_test=0
case "$file_path" in
  *.test.*|*.spec.*|*_test.go|*Test.php|*_test.php) is_test=1 ;;
  */tests/*|*/test/*|*/__tests__/*|*/spec/*) is_test=1 ;;
  tests/*|test/*|__tests__/*|spec/*) is_test=1 ;;
esac

if [ "$mode" = "fences" ]; then
  scan_input=$(printf '%s\n' "$content" | awk '
    BEGIN { inside = 0 }
    /^[[:space:]]*```/ {
      if (inside) { inside = 0; next }
      tag = $0
      sub(/^[[:space:]]*```[[:space:]]*/, "", tag)
      sub(/[[:space:]].*$/, "", tag)
      if (tag == "ts" || tag == "tsx" || tag == "typescript" || tag == "js" || tag == "jsx" || tag == "javascript" || tag == "php" || tag == "go") { inside = 1 }
      next
    }
    { if (inside) print }
  ')
  language="mixed"
else
  scan_input=$content
fi

[ -n "$scan_input" ] || exit 0

stripped=$(printf '%s\n' "$scan_input" \
  | sed -e 's/\\.//g' \
        -e 's/"[^"]*"//g' \
        -e "s/'[^']*'//g" \
        -e 's/`[^`]*`//g')

if [ "$language" = "php" ] || [ "$language" = "mixed" ]; then
  comment_pattern='(^|[[:space:]])(//|/\*|\*/|#)'
else
  comment_pattern='(^|[[:space:]])(//|/\*|\*/)'
fi

allow_pattern='(//|/\*|#)[[:space:]]*(eslint|prettier-ignore|biome-ignore|@ts-ignore|@ts-expect-error|@ts-nocheck|@phpstan-|@psalm-|phpcs:|@codeCoverageIgnore|go:|Code generated|SPDX-License-Identifier|Copyright|nolint:)'

aaa_marker_pattern='^[0-9]+:[[:space:]]*(//|#)[[:space:]]*(Arrange|Act|Assert):?[[:space:]]*$'

offenders=$(printf '%s\n' "$stripped" \
  | grep -nE "$comment_pattern" \
  | grep -vE "$allow_pattern" \
  | grep -vE '^[0-9]+:#!')

if [ "$is_test" = "1" ] && [ -n "$offenders" ]; then
  offenders=$(printf '%s\n' "$offenders" | grep -vE "$aaa_marker_pattern")
fi

offenders=$(printf '%s\n' "$offenders" | head -5)

[ -n "$offenders" ] || exit 0

reason=$(printf '%s\n' \
  "This write adds comments. Comments are not allowed in this project's code." \
  "" \
  "Offending lines (line numbers are relative to the content you sent, strings already stripped):" \
  "$offenders" \
  "" \
  "Rewrite the code so each comment is redundant: name the value, extract the block into a small well-named function, or replace the explanation with an intent-revealing identifier. Load the skill \`no-comments:style\` for the rewrite playbook, then resend the Write/Edit without comments." \
  "" \
  "Machine-read pragmas (eslint-*, @ts-*, @phpstan-*, phpcs:, //go:, generated-code markers, shebangs), license headers, and bare Arrange/Act/Assert markers in test files (exact capitalization, marker only) are allowed and were not flagged.")

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $r
  }
}'
exit 0
