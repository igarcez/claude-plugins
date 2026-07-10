---
name: execute
description: "Branch of /plan-md: execute a plan step by step, tracking plan gaps (subcommand execute). Internal: loaded by the plan-md command; not a standalone task."
---

# plan-md execute

Load skill `plan-md:migrate` and run the legacy DONE migration first, so completed plans are normalized into `plans/done/` before name resolution.

Parse the plan name from the argument. The argument may be empty (when user types `/plan-md execute` with no id), a 3-character id, or a full name. Handle all three:
- Empty argument: Auto-select logic kicks in (see below).
- 3-character id or full name: Resolve per the dispatcher's id-lookup rule.

If the argument is empty (user typed `/plan-md execute` with no plan id):
- If there is exactly one plan in `plans/`, use that one.
- If there are multiple plans in `plans/`, list them (full filename format) and ask the user which one to execute via `AskUserQuestion`.
- If there are no plans in `plans/`, tell the user "No plans found in plans/." and stop.

Once the target plan is identified:

1. Read the `plans/<name>.plan.md` file.
2. **Open-comment guard.** Search the plan for any unaddressed `claude:` comments (same detection as `review` step 3 — lines containing `claude:`, e.g. `claude: this step should also handle edge case X`). If one or more are found, **STOP — do not execute, do not proceed to context evaluation:**
   - Show the user every offending line with its location (which `### Step` heading it falls under, and the line text).
   - Explain that these are unaddressed feedback comments — executing now would run a plan the user may still be reviewing.
   - Use `AskUserQuestion` to ask whether they meant to review first. Offer: **Review first (Recommended)** — stop, then run `/plan-md review <name>` to address the comments; and **Execute anyway** — ignore the open comments and proceed.
   - If they choose *Review first*, tell them to run `/plan-md review <name>` and stop here. If they choose *Execute anyway*, continue to the next step.
3. **Context evaluation:** Silently assess the current conversation context (rough prior-turn count, plan step count) and pick one of three outcomes:
   - **Continue** — fewer than 5 prior turns AND the plan has fewer than 4 steps. Do not mention context at all; proceed directly to the next step.
   - **`clear`** — 5+ prior turns or 4+ plan steps, and the prior context is mostly planning discussion with no code the executor needs.
   - **`compact`** — 5+ prior turns or 4+ plan steps, and there are prior code reads or file edits the executor may still need.

   For `clear` or `compact`, do not output the bare recommendation word — it is too easy to miss. Instead surface it as a single **bold question** naming the matching slash command, then wait for the user's answer:
   - for `clear`: **Run `/clear` first to save tokens before proceeding?**
   - for `compact`: **Run `/compact` first to save tokens before proceeding?**

   Output nothing else — no token estimates, no justification, no other surrounding prose. If they clear or compact, remind them to re-run `/plan-md execute <name>` afterward. If they decline, continue immediately.
4. If a `CLAUDE.md` file exists in the working directory, read it and follow its guidelines throughout execution.
5. Execute each step in the plan sequentially, implementing all the code changes described.
6. After completing each step, update the plan file by marking the step as done (prefix the step title with a checkmark, e.g., `### Step 1: ~~title~~ Done`).
7. **Track plan gaps.** A *plan gap* is anything the plan got wrong or left out that you only discovered while executing — a step that was incorrect or incomplete, a missing prerequisite/setup step, a false assumption, an unanticipated error path or edge case, a wrong path/identifier/command. Whenever you hit one, record it in a running list with three things: what the plan said (or omitted), what was actually true, and the one-line lesson that would have prevented it.
8. If a step fails or is blocked, note it in the plan and continue with the next step if possible. A failure or block is itself a plan gap — add it to the list in step 7.
9. After all steps are complete, summarize what was done, including the recorded plan gaps.
10. **Capture plan gaps as intelligence.** If step 7 recorded any gaps, convert the generalizable ones into the intelligence layer (see `/intel`) so the next plan and execution avoid the same pitfall.
   - **Filter first.** Drop one-off gaps specific to this plan (a typo in one step, an index that was off). Keep gaps that would recur across future work: a missing build/setup step, a project convention the plan violated, an undocumented gotcha, an error path the codebase always needs.
   - **No `/intel` command available (it is a separate plugin some users don't have):** skip this step after listing the lessons worth capturing, so the user can record them however they prefer.
   - **No intelligence layer:** if `intelligence/` does not exist, list the lessons worth capturing and suggest the user run `/intel setup` then `/intel add <topic>`. Do not create files yourself.
   - **Layer exists:** group the kept gaps by topic. For each topic, check whether `intelligence/<topic>.md` already exists:
     - Exists → the lesson belongs in it. Propose an `Edit` that appends the lesson under the right section. Do **not** call `/intel add` — it refuses on collision.
     - Missing → propose `/intel add <topic>` to create it.
   - Present the grouped proposals via `AskUserQuestion` (which topics to capture; new file vs. extend existing) before writing anything. Apply only what the user approves, following the intelligence-file shape rules from `/intel`, and verify each cited path/command before writing.
11. Move the completed plan file into `plans/done/`, keeping its filename unchanged (no rename). For example, `plans/001-fix-csv-export.plan.md` becomes `plans/done/001-fix-csv-export.plan.md`. Create `plans/done/` if it does not exist. Use `git mv` if the file is tracked, otherwise `mv`. Tell the user the plan is done and now lives at `plans/done/<ID>-<name>.plan.md`.
