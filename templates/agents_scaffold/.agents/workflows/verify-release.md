# Workflow Runbook — Zero-Regression Release Verification

> Mandatory multi-stage verification checklist to execute before cutting a release or merging to protected branches.

---

## 1. Automated Test Execution

```bash
# Run unit tests
[test-command-unit]

# Run integration & E2E tests
[test-command-e2e]
```

---

## 2. Static Analysis & Linting

```bash
# Code style and type checking
[lint-command]
[type-check-command]
```

---

## 3. Pre-Release Security Audit

- [ ] Verify zero secrets or API keys in git diff (`git diff HEAD~1`).
- [ ] Confirm no temporary debug code or commented test bypasses remain.
- [ ] Verify dependencies match lockfile.
