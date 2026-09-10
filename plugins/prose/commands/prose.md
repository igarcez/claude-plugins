---
description: Write or rewrite text for any reader, the user included — lead with the point, state only what is in place, plain language per ISO 24495-1
argument-hint: "[text to rewrite | path to a file | empty]"
allowed-tools: Read, Edit, Glob, Skill
---

Load the skill `prose:prose` and follow it for the rest of this turn.

Then act on the argument: `$ARGUMENTS`

The argument is a path when a file exists at it (as given, or relative to the working directory).

- **Empty** → reply in one line: the rules are loaded, naming the surfaces they govern. Apply them
  to every piece of output for the rest of the turn, chat replies included.
- **A path to an existing file** → read it, rewrite it in place with `Edit` so it follows the
  rules, then report each change as one line: `<what changed>`. Keep code blocks, commands, link
  targets, and identifiers verbatim.
- **A path-looking argument with no file at it** → reply in one line that no file exists at that
  path, and stop.
- **Anything else** → treat the argument as the text itself and print the rewritten text as the
  whole reply, with nothing around it.
