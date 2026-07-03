---
name: migrate
description: "Branch of /plan-md: legacy DONE-marker migration, run before any scan of the plans directory. Internal: loaded by other plan-md branches; not a standalone task."
---

# plan-md — legacy DONE migration

**Legacy naming (pre-migration):** an earlier version of `/plan-md` marked a completed plan by renaming it in place to `<ID>-DONE-<name>.plan.md` inside `plans/` (no `done/` folder). Those files may still be the last completed plans in a project. Treat any `plans/*.plan.md` whose name contains `DONE` as a completed plan, and migrate it with the script below whenever scanning the plans directory. (Old numeric ids like `001` are still valid 3-char handles, so they keep resolving.)

Run this at the start of the `list`, `review`, `execute`, and `setup` branches:

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
