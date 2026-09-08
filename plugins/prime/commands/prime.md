---
description: Prime this repository for quality software engineering — installs direction-focused intelligence topics for AAA tests, Clean Code, Clean Architecture, comment-free code, the boy scout rule, and the detected stack.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
---

Prime this repository for quality software engineering practices by installing direction-focused
intelligence topics: Arrange–Act–Assert tests, Clean Code, Clean Architecture, comment-free code,
the boy scout rule, and one topic per detected language and per detected framework.

`/prime` takes no arguments. When "$ARGUMENTS" is non-empty, reply *"`/prime` takes no arguments."*
and stop.

Every write goes through the intel plugin — this command decides *what* the topics say and lets
`intel:add` decide *where* each file lands.

## 1. Decide the destination

- `intelligence/index.md` exists → destination is the intelligence layer; continue at step 2.
- `intelligence/` exists but `intelligence/index.md` does not → tell the user to run
  `/intel upgrade` first, and stop.
- Neither exists → ask with `AskUserQuestion`, two options:
  - *"Set up the intelligence layer"* — load skill `intel:setup`, follow it end to end, then
    continue at step 2 against the layer it produced.
  - *"Write into `AGENTS.md`"* — continue at step 6.
- Loading skill `intel:setup` or `intel:add` fails (the intel plugin is not installed) → report
  *"intel plugin not installed — writing the rules into `AGENTS.md` instead."* and continue at
  step 6.

## 2. Detect the stack

Detect languages from manifest files at the repo root and in every workspace/package folder.
Ignore `node_modules/`, `vendor/`, `.venv/`, `target/`, `dist/`, `build/`, and every path matched
by `.gitignore`.

| Manifest found | Language topic |
|----------------|----------------|
| `tsconfig.json`, or `package.json` with any `*.ts` / `*.tsx` source | `typescript` |
| `package.json` with no TypeScript source | `javascript` |
| `composer.json` | `php` |
| `go.mod` | `go` |
| `pyproject.toml`, `requirements.txt`, `setup.py` | `python` |
| `Cargo.toml` | `rust` |
| `Gemfile` | `ruby` |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | `java`, or `kotlin` when `*.kt` sources exist |
| `*.csproj`, `*.sln` | `csharp` |
| `mix.exs` | `elixir` |
| `pubspec.yaml` | `dart` |

Then read the **direct** dependencies declared by each detected manifest — `dependencies` +
`devDependencies` (`package.json`), `require` + `require-dev` (`composer.json`), the `require`
blocks (`go.mod`), `[project].dependencies` / `[tool.poetry.dependencies]` (`pyproject.toml`),
`[dependencies]` + `[dev-dependencies]` (`Cargo.toml`), the gems (`Gemfile`), declared
dependencies (`pom.xml` / `build.gradle`), `PackageReference` entries (`*.csproj`). Never read a
lockfile — direct declarations only.

Give a dependency its own topic when it carries house style: application framework, test runner or
assertion library, ORM or query builder, validation library, HTTP client, DI container, linter or
formatter, state manager, UI component library, migration tool, job/queue library. Skip type-only
packages (`@types/*`) and build utilities with no effect on code shape (`rimraf`, `cross-env`,
`dotenv`, `npm-run-all`).

Record per detected item: topic name, exact declared version, and the config that changes how code
is written — `tsconfig.json` `strict`/`target`/`module`, ESLint/Biome/Prettier config, `phpstan.neon`
level, `phpunit.xml`, `pytest.ini`/`ruff.toml`, `.editorconfig`, and the project's own test/lint/build
commands (`package.json` scripts, `composer.json` scripts, `Makefile` targets).

## 3. Confirm the plan once

Show, then ask with `AskUserQuestion` (*Proceed* / *Cancel*):

- Destination: `intelligence/` (via `intel:add`) or `AGENTS.md`.
- Detected languages with versions.
- Detected framework topics with versions.
- The exact topic list to be written, in write order, each marked *new* or *extend* (extend =
  a file for that topic already exists).

On *Cancel*, write nothing and stop. To drop or add topics, the user answers *Other* with the list
to use; honour it verbatim.

## 4. Write the core topics via `intel:add`

For each core topic in this order — `tests`, `clean-code`, `architecture`, `comments`,
`boy-scout-rule` — load skill `intel:add` and follow it with the **bare kebab-case topic name** as
its argument.

- Never construct a hub path. `intel:add` and `intel:shape` own the leaf-vs-hub decision.
- Run `intel:add`'s interview (its step 3) as written, questions open. For any question the user
  leaves empty or skips, fill that answer from this command's template for that topic (step 7),
  verbatim.
- Fallback trigger, used when the user supplies none:

  | Topic | Trigger |
  |-------|---------|
  | `tests` | If writing or changing a test |
  | `clean-code` | If writing or changing a function, class, or name |
  | `architecture` | If adding a module, layer, boundary, or dependency |
  | `comments` | If tempted to write a comment or a doc block |
  | `boy-scout-rule` | If editing code that already exists |

- `intel:add` reports the topic is already a hub → re-invoke it with the sub-target from this
  table: `tests/arrange-act-assert`, `clean-code/practices`, `architecture/clean-architecture`,
  `comments/policy`, `boy-scout-rule/practice`.
- `intel:add` stops because the target already exists as a leaf → merge instead: `Edit` that file,
  appending every template rule it lacks under the matching section (create the section when it is
  absent), leave existing wording untouched wherever the two overlap, and leave its index bullet as
  it is. Record the file as *extended*.
- After each write, re-base every relative link the template carries to the file's final location,
  per "Moving a file re-bases every relative link in it" in `intel:shape`.

## 5. Write the stack topics via `intel:add`

Same delegation, one topic per detected language first, then one per detected framework, always as
a bare topic name (`typescript`, `php`, `react`, `vitest`, `prisma`).

- Fallback trigger: `If writing <Language> code` for a language, `If writing code that uses
  <Framework>` for a framework.
- Hub collision sub-target: `<topic>/style`.
- Content: write the file from the versions and config recorded in step 2 — real commands, real
  config values, real conventions for the versions in use. Follow the stack-file shape in step 8,
  and end every stack file with its `## Precedence` section verbatim.
- Verify before writing: every command must exist in the project (or the tool's binary must be
  installed), every cited config key must be present in the config file. Drop what does not verify.

## 6. `AGENTS.md` route

Append one `## Engineering practices` section to `AGENTS.md` (create the file with the heading
`# AGENTS.md` when it does not exist). No interview on this route — write the templates verbatim.

- The section holds the five template bodies from step 7 as `### ` subsections, in the order tests,
  clean code, architecture, comments, boy scout rule. Per body: demote its `# ` heading to `### `,
  demote its `## ` headings to `#### `, and drop its `## Reference` section.
- Then one `### <Language>` / `### <Framework>` subsection per detected stack item, following the
  step 8 shape with `## ` headings demoted to `#### ` and `## Reference` dropped.
- `AGENTS.md` already has a `## Engineering practices` section → merge into it: append only the
  rules it lacks, leave existing wording untouched.
- Never touch any other section of `AGENTS.md`.

## 7. Report

Print one table — `File | new | extended | unchanged` — plus the index bullets added, the
destination used, and the line: *"Run `/intel maintain` later to re-verify these topics against the
code."* Do not commit.

## 8. Templates

### `tests`

```markdown
# Tests

## Shape

Write every test as three blocks in this order, separated by one blank line and marked with a bare
`// Arrange`, `// Act`, `// Assert` comment — the only comments allowed anywhere in this codebase:

- **Arrange** — build the inputs, doubles, and starting state.
- **Act** — invoke the one behaviour under test, exactly once.
- **Assert** — assert on the outcome of that invocation.

## Rules

- Keep one `Act` per test. A second action belongs to a second test.
- Name the test after the behaviour and its expected outcome, so the name reads as a sentence
  (`expires a session past the grace period`).
- Assert on observable outcomes — returned values, persisted state, emitted events — not on the
  internal call sequence.
- Keep `Arrange` free of branching: build state with named factory helpers so the block reads as
  data, not logic.
- Extract shared setup into named builders (`aPaidInvoice()`), never into a comment-annotated
  block.
- Cover the boundary and the failure path of every behaviour: empty, null, unauthorized,
  concurrent, oversize, partial failure.
- Hold test code to the same clean-code rules as production code.
- Test a use case with the framework, HTTP, and database out of the picture; reach for an
  end-to-end test only for behaviour that only exists once wired.

## Reference

- [intelligence/clean-code.md](clean-code.md) — how each test helper is written.
- [intelligence/comments.md](comments.md) — why Arrange/Act/Assert markers are the one exception.
```

### `clean-code`

```markdown
# Clean code

Robert C. Martin's Clean Code, applied as the house style for every function, class, and name.

## Functions

- Keep a function to a handful of lines — aim for three, and split as soon as it holds more than
  one thought.
- Give a function one job at one level of abstraction. A function that mixes levels is an
  orchestrator plus a step: extract the step.
- Split a function whose name needs "and", and any function whose body needs a blank line to
  separate phases.
- Take the fewest arguments that express the call — zero or one is ideal, three is the ceiling.
  Bundle related arguments into a named value object.
- Replace a boolean flag argument with two specialist functions named after the branches
  (`renderInvoice()` and `renderInvoiceDraft()`).
- Return early on guard failures and keep the happy path unindented.
- Keep a function free of side effects its name does not promise.

## Names

- Name a function as a verb phrase for its outcome; name a boolean as an assertion
  (`hasPendingInvoice`, `isWithinGracePeriod`).
- Spell names out — `request`, never `req`; no single letters outside a tight loop index.
- Bind every magic value to a named constant and every compound condition to a named boolean.
- Name so the calling code reads as the narrative of what happens — that narrative is what
  replaces the comment.
- Keep one word per concept across the codebase: pick `fetch`, `get`, or `load` and stay with it.

## Classes and data

- Keep a class small and cohesive: one reason to change, fields that most of its methods use.
- Prefer immutable values, and construct fully-formed objects instead of mutating after
  construction.
- Keep data structures and behaviour-carrying objects apart — no half-object that exposes its
  internals and also acts on them.
- Tell, don't ask: put the decision in the object that owns the data.

## Errors

- Signal failure with a thrown or returned typed error that names the failure — never a null, a
  magic number, or an out-parameter.
- Handle an error at the level that can act on it, and let it propagate everywhere else.
- Keep error construction out of the happy path: one named guard function per rejection.

## Reference

- [intelligence/comments.md](comments.md) — the comment ban these techniques serve.
- [intelligence/architecture.md](architecture.md) — which layer each unit belongs to.
```

### `architecture`

```markdown
# Architecture

Robert C. Martin's Clean Architecture, applied as the layering rule for every module.

## Layers

Innermost first:

| Layer | Holds | May depend on |
|-------|-------|---------------|
| Entities | domain types and their invariants | nothing |
| Use cases | application behaviour, one unit per use case | entities |
| Interface adapters | controllers, presenters, repository implementations, mappers | use cases, entities |
| Infrastructure | framework, HTTP, database, queues, third-party SDKs | adapters |

## The dependency rule

- Point every source-code dependency inward. An inner layer never imports an outer one and never
  names a framework, ORM, HTTP, or SDK type.
- Declare the port (interface) in the layer that needs it, and implement it in the outer layer.
- Cross a boundary with a plain data structure owned by the inner layer — never a framework
  request/response, an ORM model, or a database row.
- Invert control at every boundary an outer layer would otherwise reach across.

## Placement

- Put business rules in a use case, not in a controller, handler, job, or ORM model.
- Keep frameworks at the edge: a use case runs unchanged when the framework is swapped out.
- Let the top-level source folders name the layers or the domains — never the frameworks.
- Add a new dependency at the outermost layer that needs it, behind a port when an inner layer
  needs its behaviour.

## Reference

- [intelligence/clean-code.md](clean-code.md) — how each unit inside a layer is written.
- [intelligence/tests.md](tests.md) — testing a use case without the framework.
```

### `comments`

```markdown
# Comments

Code carries its own explanation. A comment marks a place where the code failed to say what it
meant — so fix the code.

## The rule

Write no comments. When a piece of code looks like it needs one, rewrite it with the clean-code
techniques below until the comment would add nothing, then leave it out.

Allowed, and only these:

- `// Arrange`, `// Act`, `// Assert` — bare block markers in test files, exactly capitalized.
- Machine-read pragmas: `eslint-*`, `prettier-ignore`, `biome-ignore`, `@ts-ignore`,
  `@ts-expect-error`, `@ts-nocheck`, `@phpstan-*`, `@psalm-*`, `phpcs:*`, `//go:*`, `//nolint:*`,
  `// Code generated ... DO NOT EDIT.`
- Shebangs and license headers (`SPDX-License-Identifier`, `Copyright`).

Doc blocks — JSDoc, PHPDoc, docstrings — are comments, and are left out too. A type signature says
what a doc block would restate.

## Comment to refactor

| The comment would say | Write this instead |
|-----------------------|--------------------|
| What a magic value means | A named constant: `const SESSION_TIMEOUT_MINUTES = 30` |
| What a block does | A function named after that sentence, called in its place |
| What a condition tests | A named boolean: `const isExpiredSession = ...` |
| Why a branch exists | A named guard function: `rejectWhenQuotaExhausted(request)` |
| What a parameter is | A renamed parameter, or a named type / value object |
| Section headers inside a long function | One function per section — the function does too much |
| Numbered steps | One named function per step, called in order by a short orchestrator |
| A workaround for external behaviour | A wrapper named after the workaround: `retryOnUpstream429(...)` |
| Commented-out code | Deletion — git holds the history |
| A TODO | The work now, or a note raised with the user outside the code |

## Where the knowledge goes instead

- Platform, database, or external-spec semantics that have no home in code → an intelligence file
  or a project doc.
- An expectation about behaviour → a test whose name states it.

## Reference

- [intelligence/clean-code.md](clean-code.md), [intelligence/tests.md](tests.md)
- Install the `no-comments` plugin (`/plugin install no-comments@igarcez`) to enforce this at write
  time; its `no-comments:style` skill holds the rewrite playbook.
```

### `boy-scout-rule`

```markdown
# Boy scout rule

Leave every file cleaner than you found it.

## When editing existing code

- Apply the current rules — [intelligence/clean-code.md](clean-code.md),
  [intelligence/comments.md](comments.md), [intelligence/tests.md](tests.md),
  [intelligence/architecture.md](architecture.md) — to the code you touch, even when the
  surrounding file predates them.
- Make one small improvement in the neighbourhood of the change: rename an unclear identifier,
  extract an over-long function, bind a magic value, delete dead code, make a comment redundant
  and drop it.
- Keep the cleanup inside the blast radius of the change at hand; rewriting the whole module is
  its own task.
- Keep behaviour identical while cleaning: run the tests green before and after, and keep a
  behaviour change out of the commit that carries a rename or an extraction.
- Add the missing test for the behaviour you are about to change, before changing it.
- Never widen a violation you find — no new comment, no new flag argument, no new inward
  dependency — even to match the surrounding style.

## Reference

- [intelligence/clean-code.md](clean-code.md), [intelligence/comments.md](comments.md),
  [intelligence/tests.md](tests.md), [intelligence/architecture.md](architecture.md)
```

### Stack file shape (language or framework)

```markdown
# <Language or Framework>

<one line: what was detected, with versions — e.g. "TypeScript 5.6, strict mode on, ESM, Node 22">

## Conventions

- <rule tied to the detected version and config, phrased as a positive imperative>

## Commands

| Command | Purpose |
|---------|---------|
| `<exact project command>` | <one line> |

## Precedence

The core topics win. Where a <language or framework> idiom conflicts with
[intelligence/tests.md](tests.md), [intelligence/clean-code.md](clean-code.md),
[intelligence/architecture.md](architecture.md), [intelligence/comments.md](comments.md), or
[intelligence/boy-scout-rule.md](boy-scout-rule.md), follow the core topic. Idiomatic doc blocks,
framework-generated comments, and flag-argument helpers are dropped in favour of the core rules.
```
