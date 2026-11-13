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
🌿 Git Working Branch: [Pre-created feature branch name, e.g., feat/audit-20261113]
📁 Allowed File Paths (Exclusive Ownership):
   - [Exact file paths or glob patterns this subagent is PERMITTED to edit]
   - Example: frontend/src/components/** (Do NOT touch backend or root configs)
🚫 Prohibited File Paths:
   - [All paths outside designated scope, specifically shared configs and main branch files]
🧪 Required Verification Command:
   - [Mandatory command proving task completion, e.g., npm test or pytest tests/test_ui.py]
🛑 Stop Conditions:
   - Stop and report immediately upon encountering branch conflicts or locked files
   - Do NOT run git commit or git push autonomously
📦 Expected Deliverables:
   - Empirical verification report (test execution output)
   - Exact list of modified files with git diff summary
===========================
```

---

## 🔒 DISJOINT OWNERSHIP PRINCIPLE

1. **Zero Overlap Across Concurrent Agents:** During any parallel execution phase, two active subagents MUST NEVER share identical paths in their `Allowed File Paths`.
2. **Coordinator Integration Monopoly:**
   - Specialist subagents only produce code modifications within their assigned scope and report verification evidence.
   - The coordinator (`orchestrator`) remains the sole authority for reviewing `git status -s`, `git diff --stat`, and synthesizing final deliverables.
3. **Incident Recovery & Blast Radius Containment:** If a subagent introduces regressions or corrupts a working directory, the coordinator can restore only that specialist's disjoint scope (`git checkout -- <path>`) without impacting other specialists' verified work.
