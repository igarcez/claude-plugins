# prose

One set of writing rules for everything Claude writes.

The reply in the chat, review comments, documentation, intelligence files, changelogs, commit and
PR bodies, issue text, and messages to third parties all follow the same rules: the point first,
only what is in place, the change named in the imperative, and plain language per ISO 24495-1.

## Install

```
/plugin marketplace add igarcez/claude-plugins
/plugin install prose@igarcez
```

## What it does

### Skill — `prose:prose`

The rule set: the surfaces it governs (chat replies included), the four ISO 24495-1 principles as
working imperatives, a written-to-write-instead rewrite table, the rules specific to a reply to the
user, and the length each surface takes. Loaded by the `/prose` command, by the hook's pointer, and
directly by `intel:add`, `pr-review:report`, and `pr-review:push`.

### Command — `/prose`

| Argument | What it does |
|----------|--------------|
| empty | Loads the rules and applies them to every piece of output for the rest of the turn. |
| a path to an existing file | Rewrites that file in place, then reports each change in one line. |
| anything else | Treats the argument as the text and prints the rewritten version. |

### UserPromptSubmit hook — `prose-style.sh`

Injects a digest of the rules, plus a pointer to `prose:prose`, on every user prompt, so the chat
reply and any text written that turn follow one style. The prompt proceeds — the hook never
blocks. It:

1. Exits immediately when `CLAUDE_PROSE=0` or when `jq` is missing.
2. Emits `{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:"..."}}` and
   exits 0. Verified on Claude Code 2.1.266: the context reaches the model and the prompt still
   runs.
3. Makes no child model call and reads nothing from disk, so it costs no measurable time per
   prompt and needs no `"timeout"` override. The event fires once per prompt, so it needs no
   marker file either.

## Configuration

| Env var | Effect |
|---------|--------|
| `CLAUDE_PROSE=0` | Disables the hook for the session. The skill and command stay available. |
