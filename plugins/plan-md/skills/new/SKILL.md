---
name: new
description: "Branch of /plan-md: interview the user and write a new plan (empty argument). Internal: loaded by the plan-md command; not a standalone task."
---

# plan-md — create a new plan

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
