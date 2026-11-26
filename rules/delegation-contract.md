---
name: delegation-contract
version: 1.0.0
priority: P0
trigger: invoke_subagent
description: Mandatory delegation contract specification that the Orchestrator must pass into each Subagent's prompt to ensure branch safety, file path isolation, and prevent resource contention.
---

# 📜 Subagent Delegation Contract Specification (P0)

> **MANDATORY:** Every `invoke_subagent` call that assigns source code modifications or test execution MUST contain a complete contract structured as follows inside the `Prompt` argument.

---

## 📋 STANDARD DELEGATION CONTRACT TEMPLATE

```markdown
=== DELEGATION CONTRACT ===
🎯 Role & Objective: [Specialist role name and 1-2 sentence specific scope]
🤖 Model Tier: [flash (default for discovery/routine/QA) | inherit/pro (architecture/complex debugging/synthesis)]
🌿 Git Working Branch: [Pre-created feature branch name, e.g., feat/audit-20261113]
📁 Allowed File Paths (Exclusive Ownership):
   - [Exact file paths or glob patterns this subagent is PERMITTED to edit]
   - Example: frontend/src/components/** (Do NOT touch backend or root configs)
🚫 Prohibited File Paths:
   - [All paths outside designated scope, specifically shared configs and main branch files]
⏱️ Timeout & Retry Budget:
   - Enforce `120s` hard timeout on verification/test commands via portable wrapper (`perl -e 'alarm shift; exec @ARGV' 120 ...` or Python `subprocess.run(..., timeout=120)`); never treat `WaitMsBeforeAsync` or `NotificationTimeoutSeconds` as a timeout
   - Cap retries at `MAX_RETRIES=3` and stop-and-escalate on exhaustion
📡 Watchdog & Background Protocol:
   - Coordinator attaches `schedule` one-shot watchdog (`DurationSeconds: 600`, `TimerCondition: "<subagentId>"` or `"any"`)
   - Subagent MUST send an interim `send_message` to parent BEFORE ending turn to wait on a background `run_command` (and monitor via `NotificationTimeoutSeconds` / `schedule`, since canceled tasks emit `MESSAGE_PRIORITY_LOW` and will not wake an idle subagent)
🧪 Required Verification Command:
   - [Mandatory command proving task completion, e.g., npm test or pytest tests/test_ui.py]
🛑 Stop Conditions:
   - Stop and report immediately upon encountering branch conflicts or locked files
   - Do NOT run git commit or git push autonomously
📦 Expected Deliverables:
   - Empirical verification report (test execution output)
   - Exact list of modified files with git diff summary
   - Execution & Resilience Metrics (Model Tier, Wall Time, Timeouts Configured/Triggered, Retry Attempts used/max, Circuit-Breaker Denials, Completion Signal)
===========================
```

---

## 🔒 DISJOINT OWNERSHIP PRINCIPLE

1. **Zero Overlap Across Concurrent Agents:** During any parallel execution phase, two active subagents MUST NEVER share identical paths in their `Allowed File Paths`.
2. **Coordinator Integration Monopoly:**
   - Specialist subagents only produce code modifications within their assigned scope and report verification evidence.
   - The coordinator (`orchestrator`) remains the sole authority for reviewing `git status -s`, `git diff --stat`, and synthesizing final deliverables.
3. **Incident Recovery & Blast Radius Containment:** If a subagent introduces regressions or corrupts a working directory, the coordinator can restore only that specialist's disjoint scope (`git checkout -- <path>`) without impacting other specialists' verified work.

---

## ⏱️ WATCHDOG, MODEL TIERING & COMMUNICATION RULES

1. **Subagent `Model` Tiering:** Use `Model: "flash"` by default on `invoke_subagent` for discovery (`explorer-agent`), routine implementation, and QA/test scripting; reserve `inherit` / `pro` for deep architecture, complex debugging, or multi-domain synthesis.
2. **Coordinator Watchdog & Wakeup Discipline:** Attach a `schedule` one-shot timer (`DurationSeconds: 600`, `TimerCondition: "<subagentId>"` or `"any"`) for long-running subagents. When waking on timeout or user `"Continue"`, interact via `send_message` / `manage_subagents` rather than reading raw `transcript.jsonl` via shell.
3. **Background Wait Handshake:** If a subagent launches a background `run_command` task, it MUST call `send_message` to notify the parent of the active background task ID BEFORE ending its turn to wait (paired with `NotificationTimeoutSeconds` / `schedule`), because canceled tasks emit `MESSAGE_PRIORITY_LOW` and will NOT wake an idle subagent.
