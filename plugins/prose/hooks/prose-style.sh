#!/usr/bin/env bash
set -u

cat >/dev/null 2>&1

case "${CLAUDE_PROSE:-1}" in
  0) exit 0 ;;
esac

command -v jq >/dev/null 2>&1 || exit 0

context=$(printf '%s\n' \
  "Write every piece of output this turn — the reply to the user and any text other people read — this way:" \
  "- Open with the point; cut preamble, praise, and sign-off." \
  "- State only what is in place; leave out what you did not verify." \
  "- Name the change to make, in the imperative." \
  "- Short sentences, active voice, common words (ISO 24495-1)." \
  "- No hedging (might/could/perhaps), no restating the question, no tool-call narration." \
  "- Keep code blocks, commands, identifiers, and error strings verbatim; write security and irreversible-action warnings in full." \
  "" \
  "Load the skill \`prose:prose\` for the full playbook.")

jq -n --arg c "$context" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $c
  }
}'
exit 0
