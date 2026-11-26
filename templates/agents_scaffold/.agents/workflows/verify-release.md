# Workflow Runbook — Zero-Regression Release Verification

> Mandatory multi-stage verification checklist to execute before cutting a release or merging to protected branches.

---

## 1. Automated Test Execution

> **Resilience Standard:** Enforce a `120s` hard timeout using macOS-portable wrappers (`perl -e 'alarm shift; exec @ARGV' 120 ...` or Python `subprocess.run(..., timeout=120)` — macOS lacks GNU `timeout` by default), cap retries at `MAX_RETRIES=3` with stop-and-escalate on exhaustion, and never rely on `WaitMsBeforeAsync` or `NotificationTimeoutSeconds` as a timeout.

```bash
# Run unit tests with 120s hard timeout
perl -e 'alarm shift; exec @ARGV' 120 [test-command-unit]

# Run integration & E2E tests safely (explicit wait "$PID", cleanup trap, Bash 3.2 array check)
SERVER_PID=""
trap 'kill -TERM "${SERVER_PID:-}" 2>/dev/null || true' EXIT INT TERM
# [start-server-command] & SERVER_PID=$!
# perl -e 'alarm shift; exec @ARGV' 120 [test-command-e2e] & CLIENT_PID=$!
# wait "$CLIENT_PID"   # Never call bare `wait` when background servers are running
# EXTRA_ARGS=()
# if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then echo "${EXTRA_ARGS[@]}"; fi
```

---

## 2. Static Analysis & Linting

```bash
# Code style and type checking (120s timeout)
perl -e 'alarm shift; exec @ARGV' 120 [lint-command]
perl -e 'alarm shift; exec @ARGV' 120 [type-check-command]
```

---

## 3. Pre-Release Security Audit

- [ ] Verify zero secrets or API keys in git diff (`git diff HEAD~1`).
- [ ] Confirm no temporary debug code or commented test bypasses remain.
- [ ] Verify dependencies match lockfile.

---

## 4. Deliverable & Governance Verification

- [ ] Validate any generated deliverable (`.docx`, `.xlsx`, `.pdf`, `.md`, `.txt`, `.json`) before release:
  ```bash
  ./scripts/verify-deliverable.sh <path> \
    || ~/.gemini/config/plugins/ag-kit/scripts/verify-deliverable.sh <path>
  ```
- [ ] Verify execution report includes the **Execution & Resilience Metrics** table (`Agent / Subagent (ID)`, `Model Tier`, `Wall Time`, `Timeouts Configured / Triggered`, `Retry Attempts (used/max)`, `Circuit-Breaker Denials`, `Completion Signal`).
