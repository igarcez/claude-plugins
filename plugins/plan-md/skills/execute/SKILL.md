---
name: execute
description: "Branch of /plan-md: execute a plan step by step — inline at a cold start, in a fresh subagent when the session carries prior context — tracking plan gaps (subcommand execute). Internal: loaded by the plan-md command; not a standalone task."
---

# plan-md execute

Load skill `plan-md:migrate` and run the legacy DONE migration first, so completed plans are normalized into `plans/done/` before name resolution.

Parse the plan name from the argument. The argument may be empty (when user types `/plan-md execute` with no id), a plan id (word-word like `river-tiger`, or legacy 3-character like `a3f`), or a full name. Handle all three:
- Empty argument: Auto-select logic kicks in (see below).
- Plan id or full name: Resolve per the dispatcher's id-lookup rule.

If the argument is empty (user typed `/plan-md execute` with no plan id):
- If there is exactly one plan in `plans/`, use that one.
- If there are multiple plans in `plans/`, list them (full filename format) and ask the user which one to execute via `AskUserQuestion`.
- If there are no plans in `plans/`, tell the user "No plans found in plans/." and stop.

Once the target plan is identified:

1. Read the `plans/<name>.plan.md` file.
2. **Open-comment guard.** Search the plan for any unaddressed `claude:` comments (same detection as `review` step 3 — lines containing `claude:`, e.g. `claude: this step should also handle edge case X`). If one or more are found, **STOP — do not execute, do not proceed to execution routing:**
   - Show the user every offending line with its location (which `### Step` heading it falls under, and the line text).
   - Explain that these are unaddressed feedback comments — executing now would run a plan the user may still be reviewing.
   - Use `AskUserQuestion` to ask whether they meant to review first. Offer: **Review first (Recommended)** — stop, then run `/plan-md review <name>` to address the comments; and **Execute anyway** — ignore the open comments and proceed.
   - If they choose *Review first*, tell them to run `/plan-md review <name>` and stop here. If they choose *Execute anyway*, continue to the next step.
3. **Execution routing.** Silently assess whether the context window already carries prior context — any prior turns of planning discussion, code reads, or file edits. Do not judge by plan size; a many-step plan predicts *future* spend, which routing cannot lower.
   - **Cold start** (the session was just cleared, or holds no prior context beyond this command): execute steps 4–9 inline yourself. Say nothing about context or routing.
   - **Any accumulated prior context:** delegate steps 4–9 to a fresh subagent automatically — no recommendation, no permission question, no token estimates. Call the `Agent` tool once with `subagent_type: "general-purpose"`, `description: "execute plan <ID>"`, and a prompt that carries everything the subagent needs, since it has none of this session's context:
     - the absolute path of the plan file, and the instruction to read it in full first;
     - the instruction to read `CLAUDE.md` in the working directory (if present) and follow it throughout execution;
     - the instruction *"Read intelligence/index.md and every matching intelligence file before starting"* (harmless when the repo has no intelligence layer);
     - steps 4–9 of this skill verbatim as its task: execute every plan step sequentially, mark each finished step done in the plan file (`### Step 1: ~~title~~ Done`), track plan gaps, continue past a blocked step where possible;
     - the instruction to return a final report containing the per-step outcome and the full plan-gap list (what the plan said or omitted, what was actually true, the one-line lesson).
     When the subagent finishes, relay its summary and adopt its reported plan-gap list as the step 7 list, then continue with steps 10 and 11 yourself in this session. Steps 10 and 11 stay in this session in both routes — they need `AskUserQuestion`.
4. Steps 4–9 run in whichever place step 3 chose — inline in this session, or inside the delegated subagent. If a `CLAUDE.md` file exists in the working directory, read it and follow its guidelines throughout execution.
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
