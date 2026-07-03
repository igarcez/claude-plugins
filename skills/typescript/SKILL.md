---
name: typescript
description: "plan-md rules: TypeScript / JavaScript. Loaded by /plan-md when the project contains package.json, tsconfig.json, or *.ts/*.tsx/*.js files. Reference content only — not a standalone task."
---

# plan-md rules: TypeScript / JavaScript

Apply when project contains `package.json`, `tsconfig.json`, `*.ts`, `*.tsx`, `*.js`, `*.jsx`, or `*.mjs`.

## Code blocks
- Use ` ```ts` for TypeScript, ` ```tsx` for TSX, ` ```js` for JavaScript, ` ```jsx` for JSX.
- Use ` ```json` for JSON snippets (tsconfig, package.json, etc.).

## Baseline commands (Step 0 candidates)
Pick the ones the project actually uses — check `package.json` `scripts` first.
- Type check: `tsc --noEmit` (or `npm run typecheck` / `pnpm typecheck` / `yarn typecheck` if defined).
- Lint: `eslint .` or `npm run lint`.
- Tests: `npm test` / `vitest run` / `jest` — match what's configured.
- Build: `npm run build` if relevant.

## Conventions
- Prefer the package manager already in use (lockfile signals: `package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` → bun).
- Respect `tsconfig.json` `strict` settings when proposing types.
