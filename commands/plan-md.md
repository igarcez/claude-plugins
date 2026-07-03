---
description: Interview-driven implementation plans for AI agents — setup, create, list, review, execute
argument-hint: "[setup | list | review <id> | execute <id>]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Agent, Skill
---

You are a planning assistant. Your behavior depends on the argument provided: "$ARGUMENTS"

**Audience:** Plans produced by this command are written for an **AI coding agent** to execute (not a human developer). The interview, the writing rules, and the format all optimize for unambiguous machine consumption: exact file paths, exact identifiers, exact code, exact commands. Prose intended to "explain" or "convince" a human reader is noise — strip it. If a step is not directly actionable by an LLM agent reading the file cold, it does not belong in the plan.

Plans are stored in a `plans/` directory in the current working directory, named as `<ID>-<kebab-case-description>.plan.md` where `ID` is a random 3-character lowercase alphanumeric code (e.g. `a3f`, `k90`, `zz1`). It is not sortable or sequential — it is just a unique handle. The kebab-case name should be a minimal description of the plan's goal (e.g., `a3f-add-auth-middleware.plan.md`, `k90-fix-upload-race-condition.plan.md`).

**Completed plans** are moved into a `plans/done/` subdirectory, keeping their original `<ID>-<name>.plan.md` filename (no rename). A plan is "done" when it lives under `plans/done/` — this is purely historical; id lookup ignores the `done/` folder.

**Folder verification (every branch):** Before running any branch below (`list`, `review`, `execute`, or plan creation), check that both `plans/` and `plans/done/` exist in the current working directory. If either is missing, run the **Setup procedure** (below) on the spot, then continue with the originally requested branch. `/plan-md setup` runs the same procedure explicitly.

**Legacy naming (pre-migration):** an earlier version of this command marked a completed plan by renaming it in place to `<ID>-DONE-<name>.plan.md` inside `plans/` (no `done/` folder). Those files may still be the last completed plans in a project. Treat any `plans/*.plan.md` whose name contains `DONE` as a completed plan, and migrate it (see **Legacy DONE migration** below) whenever this command scans the plans directory. (Old numeric ids like `001` are still valid 3-char handles, so they keep resolving.)

**ID assignment:** Before creating a new plan, run this inline script to get a fresh id (random 3-char code, retried until it doesn't collide with an existing active plan; the `done/` folder is intentionally ignored):

```bash
python3 -c "
import glob, os, random, string
active = {os.path.basename(f)[:3].lower() for f in glob.glob(os.path.join('plans', '*.plan.md'))}
while True:
    i = ''.join(random.choices(string.ascii_lowercase + string.digits, k=3))
    if i not in active:
        print(i); break
"
```

Use the output as the `<ID>` prefix for the new plan filename.

**Referencing plans by id:** Whenever a command expects a plan name (review, execute), the user may provide just the 3-character id (e.g., `a3f`) instead of the full name. Lookup ignores the `done/` folder — only active plans in `plans/` resolve. To find the file for an id:

```bash
ls plans/ | grep -i "^<ID>-"
```

Replace `<ID>` with the user-provided id. If output is empty, no active plan matches — tell the user. The full kebab-case name is also still accepted.

---

## Setup procedure (run by the `setup` branch and by folder verification)

1. **Create the structure:** run `mkdir -p plans/done`. Note first whether `plans/` existed beforehand — the git decision below depends on it.
2. **Git tracking decision.** Only applies when the current working directory is inside a git work tree (`git rev-parse --is-inside-work-tree` exits 0). If not a git repo, skip this step entirely.
   - **Already decided — skip the question** when either is true:
     - `git check-ignore -q plans` exits 0 → plans are already gitignored.
     - `git ls-files plans | head -1` prints a path → plans are already tracked.
   - **Ask-once rule:** when this procedure runs via folder verification (not an explicit `/plan-md setup`), ask the question only if `plans/` itself was missing in step 1. If `plans/` already existed and only `done/` was missing, create the folder silently and skip the question. An explicit `/plan-md setup` always evaluates the decision (but still skips the question when it is already decided per the checks above).
   - **Otherwise ask** with `AskUserQuestion`: "Should plan files be committed to this repository?"
     - **Commit plans** — planning history is shared with the team and plans are reviewable in PRs. Action: create empty `plans/.gitkeep` and `plans/done/.gitkeep` so the structure survives a fresh clone.
     - **Gitignore plans** — plans stay local scratch files, never committed. Action: append a line `plans/` to the `.gitignore` in the current working directory (create the file if it doesn't exist; do not add a duplicate if a `plans/` line is already present).
3. **Report:** state what was created vs. already in place, and the git decision taken (or that it was already decided / not applicable).

---

## Legacy DONE migration (run whenever scanning the plans directory)

Before listing, reviewing, or executing, normalize any legacy-marked completed plans into the new `plans/done/` layout. Run this at the start of the `list`, `review`, and `execute` branches:

```bash
python3 - <<'PY'
import glob, os, subprocess

def tracked(path):
    return subprocess.run(['git', 'ls-files', '--error-unmatch', path],
                          capture_output=True).returncode == 0

legacy = [f for f in glob.glob(os.path.join('plans', '*.plan.md'))
          if 'DONE' in os.path.basename(f)]
if legacy:
    os.makedirs(os.path.join('plans', 'done'), exist_ok=True)
for src in legacy:
    base = os.path.basename(src)
    # Strip the legacy '-DONE' marker: '001-DONE-name.plan.md' -> '001-name.plan.md'
    clean = base.replace('-DONE-', '-', 1).replace('DONE-', '', 1)
    dst = os.path.join('plans', 'done', clean)
    if tracked(src):
        subprocess.run(['git', 'mv', src, dst], check=True)
    else:
        os.replace(src, dst)
    print(f'migrated {src} -> {dst}')
PY
```

This moves each `plans/*DONE*.plan.md` into `plans/done/` and strips the `DONE-` marker from the name. If nothing is printed, there was nothing to migrate.

---

## If the argument is "setup":

1. Run the **Setup procedure** (see above). This is the explicit invocation: always evaluate the git tracking decision, skipping the question only when it is already decided.
2. Run the **Legacy DONE migration** script so any old-style completed plans are normalized.
3. Report the results of both.

---

## If the argument is "list":

1. Verify the folder structure (see **Folder verification**), then run the **Legacy DONE migration** script (see above) so any old-style completed plans are already in `plans/done/`.
2. List all active `*.plan.md` files in `plans/` AND all completed `*.plan.md` files in `plans/done/`.
3. For each plan, show its **id**, name, and the `## Goal` section content. Format: `[ID] <name> — <goal>`. Completed plans (those under `plans/done/`) display as `[ID] [DONE] <name> — <goal>`.
4. If no plans exist in either location, tell the user.
5. Remind the user they can reference plans by id, e.g., `/plan-md review a3f` or `/plan-md execute k90`.

---

## If no argument is provided (empty "$ARGUMENTS"):

First verify the folder structure (see **Folder verification**) so `plans/` and `plans/done/` exist and the git tracking decision is settled before any plan is written.

### 1. Establish goal
Ask the user what they want to accomplish, or infer from recent conversation. Restate the goal in one sentence and get confirmation before any further work.

### 2. Analyze codebase
If a `CLAUDE.md` file exists in the working directory, read it first and follow its guidelines throughout planning (conventions, constraints, forbidden patterns must shape the questions asked and the plan written).

Read whatever files are needed to understand current state of the area being changed. Identify every place the new behavior touches, every existing pattern to follow or break, every adjacent feature that could be affected. Do this BEFORE the interview so questions are informed by real code, not guesses.

### 3. Detect project stack & load language rules
Identify the project's primary language(s):
- `package.json` / `tsconfig.json` / `*.ts` / `*.tsx` / `*.js` → **typescript**
- `composer.json` / `*.php` / `artisan` → **php**
- (others are added as new rule skills under this plugin's `skills/` directory)

For each detected stack, load its rules by invoking the `Skill` tool with the skill name `plan-md:<lang>` (e.g. `plan-md:typescript`, `plan-md:php`) and apply those rules throughout planning. Do NOT load skills for languages not present.

### 4. Relentless interview — resolve every branch of the decision tree

The plan must contain only concrete actions. No "TBD", no "consider X", no "depending on Y". Every fork in the decision tree must be resolved by the user before writing.

**Phase A — Map the tree (batch).**
Use the `AskUserQuestion` tool with 2–4 grouped questions at a time. Cover the big forks first: scope boundaries, API/contract shape, data model, naming, file placement, dependencies to add/remove, breaking-change tolerance, migration approach, test strategy, error-handling stance, observability needs, rollout/feature-flag.

**Phase B — Drill (one-at-a-time).**
For each unresolved branch left after the batch (edge cases, exact identifiers, copy/wording, exact thresholds, exact file paths, exact function signatures), ask a single focused question. Repeat. Do not batch these — drill until that branch is closed, then move to next.

**Stop criteria.** Continue until you can honestly state: "no open branches remain — every step below is a concrete action with a definite file, signature, and behavior." Before writing the plan, explicitly tell the user: *"No open branches. Writing plan."* If you cannot say that, keep interviewing.

Things that count as open branches and MUST be closed:
- Any choice between two or more reasonable implementations.
- Any identifier (function/class/file/route/column/env var/flag) not yet named.
- Any data shape not yet specified field-by-field.
- Any error path not yet decided (throw / return / log / ignore).
- Any edge case (empty, null, concurrent, oversize, unauthorized, partial failure) not yet decided.
- Any tooling choice (lib X vs Y, version pin, dev vs prod dep).
- Any test left as "add tests" — must be specific scenarios.
- Any verification command not yet pinned to an exact invocation.

### 5. Baseline verification
If any step uses a verification command (type-check, lint, test, build), prepend **Step 0: Baseline check** that runs the same exact command(s) before changes. Record current output in the plan so post-change diff is unambiguous. If baseline already fails, list the failures in Step 0 so they are not later misattributed.

### 6. Write the plan — concrete actions only

Derive a minimal kebab-case name from the goal. Write to `plans/<ID>-<name>.plan.md`.

**Target reader: an AI coding agent.** Plan will be loaded by another LLM session that has no memory of this interview. Every fact it needs to act must be on the page — exact paths, exact identifiers, exact code, exact commands. Do not assume the executor can "figure it out", "use judgment", or "follow the existing pattern" — name the pattern, name the file, paste the snippet.

**Strict content rules:**
- Plan body is imperative steps only. Each step = exact file + exact action verb (create/edit/delete/rename/run) + exact code or command.
- Every code-touching step MUST include the concrete code diff or full snippet to write — not a description of it.
- No `## Notes` section. No caveats. No "open questions". No "considerations". If something would belong there, it was an unresolved branch — go back to interview.
- No rationale prose inside steps. Goal section holds the one-line why; steps hold the what.
- No human-oriented filler: no "we should", "let's", "note that", "be aware". Address executor directly via imperatives.
- Use correct language identifiers for fenced code blocks per the loaded stack rules.

Format:

```markdown
# Plan: <title>

## Goal
<one sentence — what will be true after this plan runs>

## Steps

### Step 0: Baseline check
- **Run:** `<exact command>`
- **Expected current output:** <captured baseline, or "clean">

### Step 1: <imperative title>
- **File:** `path/to/file`
- **Action:** <create | edit | delete | rename | run>
- **Change:**
  ```<lang>
  <exact code to write, or exact diff>
  ```

### Step 2: <imperative title>
...
```

**DO NOT implement any code changes.** Only produce the plan.

After writing, tell the user: "Plan written to `plans/<ID>-<name>.plan.md`. Reference by id: `/plan-md review <ID>` or `/plan-md execute <ID>`. Add `claude:` comments to any step for feedback. `/plan-md list` shows all plans."

---

## If the argument starts with "review":

Verify the folder structure (see **Folder verification**), then run the **Legacy DONE migration** script (see above) so completed plans are normalized into `plans/done/` before name resolution.

Parse the plan name from the argument (e.g., `review add-auth-middleware`). The name may or may not include the `.plan.md` suffix — handle both.

If no name is given after "review":
- If there is exactly one plan in `plans/`, use that one.
- If there are multiple plans, list them and ask the user which one to review.
- If there are no plans, tell the user.

Once the target plan is identified:

1. Read the `plans/<name>.plan.md` file.
2. If a `CLAUDE.md` file exists in the working directory, read it and follow its guidelines when addressing feedback (ensure updates respect project conventions and constraints).
3. Search for all comments prefixed with `claude:` (e.g., lines containing `claude: this step should also handle edge case X`).
4. For each `claude:` comment found, address the feedback by updating the relevant section of the plan.
5. Remove the `claude:` comments after addressing them.
6. Write the updated plan back to the same file.
7. **DO NOT implement any code changes.** Only update the plan.

After updating, tell the user what changed and remind them they can add more `claude:` comments or run `/plan-md execute <name>` when ready.

---

## If the argument starts with "execute":

Verify the folder structure (see **Folder verification**), then run the **Legacy DONE migration** script (see above) so completed plans are normalized into `plans/done/` before name resolution.

Parse the plan name from the argument (e.g., `execute fix-csv-export`). The name may or may not include the `.plan.md` suffix — handle both.

If no name is given after "execute":
- If there is exactly one plan in `plans/`, use that one.
- If there are multiple plans, list them and ask the user which one to execute.
- If there are no plans, tell the user.

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

   For `clear` or `compact`, output the recommendation as that single word — no token estimates, no justification, no surrounding prose — and wait for the user's answer. If they clear or compact, remind them to re-run `/plan-md execute <name>` afterward. If they decline, continue immediately.
4. If a `CLAUDE.md` file exists in the working directory, read it and follow its guidelines throughout execution.
5. Execute each step in the plan sequentially, implementing all the code changes described.
6. After completing each step, update the plan file by marking the step as done (prefix the step title with a checkmark, e.g., `### Step 1: ~~title~~ Done`).
7. **Track plan gaps.** A *plan gap* is anything the plan got wrong or left out that you only discovered while executing — a step that was incorrect or incomplete, a missing prerequisite/setup step, a false assumption, an unanticipated error path or edge case, a wrong path/identifier/command. Whenever you hit one, record it in a running list with three things: what the plan said (or omitted), what was actually true, and the one-line lesson that would have prevented it.
8. If a step fails or is blocked, note it in the plan and continue with the next step if possible. A failure or block is itself a plan gap — add it to the list in step 7.
9. After all steps are complete, summarize what was done, including the recorded plan gaps.
10. **Capture plan gaps as intelligence.** If step 7 recorded any gaps, convert the generalizable ones into the intelligence layer (see `/intel`) so the next plan and execution avoid the same pitfall.
   - **Filter first.** Drop one-off gaps specific to this plan (a typo in one step, an index that was off). Keep gaps that would recur across future work: a missing build/setup step, a project convention the plan violated, an undocumented gotcha, an error path the codebase always needs.
   - **No `/intel` command available (it is a separate tool some users don't have):** skip this step after listing the lessons worth capturing, so the user can record them however they prefer.
   - **No intelligence layer:** if `intelligence/` does not exist, list the lessons worth capturing and suggest the user run `/intel setup` then `/intel add <topic>`. Do not create files yourself.
   - **Layer exists:** group the kept gaps by topic. For each topic, check whether `intelligence/<topic>.md` already exists:
     - Exists → the lesson belongs in it. Propose an `Edit` that appends the lesson under the right section. Do **not** call `/intel add` — it refuses on collision.
     - Missing → propose `/intel add <topic>` to create it.
   - Present the grouped proposals via `AskUserQuestion` (which topics to capture; new file vs. extend existing) before writing anything. Apply only what the user approves, following the **Shape of an intelligence file** rules from `/intel`, and verify each cited path/command before writing.
11. Move the completed plan file into `plans/done/`, keeping its filename unchanged (no rename). For example, `plans/001-fix-csv-export.plan.md` becomes `plans/done/001-fix-csv-export.plan.md`. Create `plans/done/` if it does not exist. Use `git mv` if the file is tracked, otherwise `mv`. Tell the user the plan is done and now lives at `plans/done/<ID>-<name>.plan.md`.
