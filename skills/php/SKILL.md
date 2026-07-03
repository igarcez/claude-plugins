---
name: php
description: "plan-md rules: PHP. Loaded by /plan-md when the project contains composer.json, *.php, or artisan. Reference content only — not a standalone task."
---

# plan-md rules: PHP

Apply when project contains `composer.json`, `*.php`, or `artisan` (Laravel).

## Code blocks
- Use ` ```php` for PHP fenced blocks.
- **Render-only tag:** include `<?php` on the first line of every PHP fenced block so syntax highlighting works. This tag is for rendering only — do NOT include it in actual code changes during execution unless the target file genuinely starts with `<?php`.

## Baseline commands (Step 0 candidates)
Derive baseline commands from the project itself — check `composer.json` `scripts`, the `Makefile`, and the project's `CLAUDE.md` / intelligence layer for the configured lint, static-analysis, and test commands. Do not assume a tool; use what the project actually runs.
