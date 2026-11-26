---
description: Standard operating procedure for implementing a new feature end-to-end
---

# 🚀 Add New Feature Workflow (End-to-End SOP)

## Step 1: Initialize Feature Branch (MANDATORY FIRST STEP)
> ⚠️ **NEVER write or edit code directly on `main` or `master`.**

```bash
git fetch origin
git checkout main
git pull origin main
git checkout -b feat/<feature-name>-$(date +%Y%m%d)
git branch --show-current
```

## Step 2: Impact Analysis & Scope Identification
1. Identify all affected system layers (Database, Models, API Routers, Client UI).
2. Apply `impact-analysis.md`: Verify whether API schema modifications impact existing frontend consumers.

## Step 3: Backend & Database Implementation (If Applicable)
1. Update database models and request/response schemas (Pydantic / Zod / SQLAlchemy).
2. Generate and test database migrations (Alembic / Prisma).
3. Implement API router endpoints and attach business services.
4. Add comprehensive unit tests covering happy paths and error states.

## Step 4: Frontend Implementation
1. Create or update reusable UI components (following Mobile-First design, touch targets ≥ 44×44px).
2. Integrate API client with complete error boundaries (loading spinners, error toasts, fallback states).
3. Synchronize localization files simultaneously if user-facing strings are added (e.g., `en.json`).

## Step 5: Verification & Regression Testing
```bash
# Run the complete test suite
pytest
cd frontend && npm test
```

## Step 6: Commit Changes & Open Pull Request
```bash
git status -s
git add <specific-files>
git commit -m "feat(<scope>): <concise-description>"
git push -u origin feat/<feature-name>-$(date +%Y%m%d)
```
Open a Pull Request on GitHub/GitLab and ensure all automated CI checks pass before merging.
