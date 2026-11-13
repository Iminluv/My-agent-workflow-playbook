---
name: git-safety
version: 1.0.0
priority: P0
trigger: always_active
description: Strictly forbids modifying or overwriting source code directly on the main or master branch. Enforces task isolation on dedicated feature branches or worktrees.
---

# 🛑 Git Branch Safety Protocol (P0 — Always Active)

> **HIGHEST PRIORITY (P0):** Applies universally to ALL agents with file-modification capabilities (`orchestrator`, `backend-specialist`, `frontend-specialist`, `security-auditor`, `debugger`, `devops-engineer`, `test-engineer`, etc.).

---

## 🚫 1. ABSOLUTE PROHIBITIONS

1. **NEVER** create, edit, write, delete files, or run git commit directly on the `main` or `master` branch.
2. **NEVER** force-push (`git push -f` or `--force`) to any shared or upstream branch.
3. **NEVER** execute destructive git actions (`git reset --hard`, `git clean -fdx`) without explicit user authorization in chat.

---

## ✅ 2. MANDATORY PRE-CODE GATE (STEP 0)

Before executing ANY file-modification tool (`edit_file`, `write_file`, or terminal commands that write source code):

### Check the current working branch:
```bash
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "not-a-git-repo")
```

- **If `CURRENT_BRANCH` is `main` or `master`:**
  👉 **STOP IMMEDIATELY!** Do not write a single byte to the working tree.
  👉 Create and switch to a dedicated feature branch following standard naming conventions:
  ```bash
  TASK_SLUG="<concise-kebab-case-task-slug>"
  DATE_STAMP=$(date +%Y%m%d)
  git checkout -b "feat/${TASK_SLUG}-${DATE_STAMP}"
  ```
  👉 Confirm branch switch:
  ```bash
  git branch --show-current  # Must output feat/... before proceeding
  ```

---

## 👥 3. SUBAGENT DELEGATION CONSTRAINTS (`invoke_subagent`)

When `orchestrator` delegates work to specialist subagents:

1. **Branch Prerequisite:** The `orchestrator` MUST ensure the feature branch (`feat/...`) is already checked out **BEFORE** invoking subagents.
2. **Explicit Prompt Injection:**
   The prompt passed to each subagent MUST explicitly declare:
   ```text
   BRANCH SAFETY CONSTRAINT:
   - Working branch: feat/<task-slug>-<date>
   - Run `git branch --show-current` to verify before making any file changes.
   - Modifying main or master is strictly forbidden.
   ```
3. **Disjoint File Ownership:**
   When running multiple writing subagents in parallel, each subagent MUST be assigned exclusive, non-overlapping file paths (`Allowed File Paths`) to completely eliminate race conditions and write contention.

---

## 🔄 4. SAFE MERGE & INTEGRATION PROTOCOL

Upon completing implementation:
1. Run the full automated verification test suite (`pytest`, `npm test`).
2. Commit verified changes on the feature branch:
   ```bash
   git commit -m "feat(scope): concise description of verified change"
   ```
3. Create a Pull Request or notify the user for manual verification prior to merging into `main`:
   ```markdown
   ✅ All changes have been safely isolated on branch: `feat/<task-slug>`
   📊 Test Results: [X passing tests]
   👉 Review diff before merge via: `git diff main..feat/<task-slug>`
   ```
