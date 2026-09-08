# prime

Prime a repository for quality software engineering practices.

`/prime` installs direction-focused intelligence topics — Arrange–Act–Assert tests, Clean Code,
Clean Architecture, comment-free code, the boy scout rule — plus one topic per language and per
framework it detects in the repo, so every later task loads the practices that apply to it.

## Install

```
/plugin marketplace add igarcez/claude-plugins
/plugin install prime@igarcez
```

The [intel](../intel/) plugin is the writer: `/prime` delegates every file and index edit to
`intel:add`, which owns the leaf-vs-hub layout decision. Without intel installed, `/prime` falls
back to writing one `## Engineering practices` section into `AGENTS.md`.

## Usage

| Command | What it does |
|---------|--------------|
| `/prime` | Detects the stack, confirms the topic list with you, then writes each topic through `intel:add`. |

## What it writes

| Topic | Trigger it is indexed under |
|-------|-----------------------------|
| `tests` | If writing or changing a test |
| `clean-code` | If writing or changing a function, class, or name |
| `architecture` | If adding a module, layer, boundary, or dependency |
| `comments` | If tempted to write a comment or a doc block |
| `boy-scout-rule` | If editing code that already exists |
| one per language | If writing `<Language>` code |
| one per framework | If writing code that uses `<Framework>` |

Every stack topic ends with a `## Precedence` section: where a language or framework idiom
conflicts with a core topic, the core topic wins.

## Flow

1. **Destination.** An existing `intelligence/index.md` is used as-is. A repo with no layer is
   offered a choice: run `intel:setup` first, or write into `AGENTS.md` instead.
2. **Detection.** Languages from manifests (`package.json`, `composer.json`, `go.mod`,
   `pyproject.toml`, `Cargo.toml`, `Gemfile`, `pom.xml`, `*.csproj`, `mix.exs`, `pubspec.yaml`),
   frameworks from those manifests' direct dependencies — every dependency that carries house
   style gets its own topic.
3. **One confirmation.** The detected stack and the exact topic list are shown once before
   anything is written.
4. **Write.** One `intel:add` per topic, with `intel:add`'s own interview; anything you leave
   empty is filled from the shipped template.
5. **Re-run safe.** An existing topic file is extended with the rules it lacks — existing wording
   wins — and newly detected languages or frameworks get new topics.

## Pairs with

[no-comments](../no-comments/) enforces the `comments` topic at write time: its PreToolUse hook
denies any `Write`/`Edit` that adds a comment, while allowing bare `Arrange`/`Act`/`Assert`
markers in test files.
