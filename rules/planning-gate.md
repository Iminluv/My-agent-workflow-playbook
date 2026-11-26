---
name: planning-gate
version: 2.1.0
priority: P0
trigger: always_on
description: Mandatory Human-in-the-Loop Planning Gate and Phase-to-Agent/Skill Delegation Matrix with Phase 0 Git Branch Setup, Phase 0.5 Base Context Scaffold Auto-Detection, Disjoint Ownership, and Proceed Approval Barrier.
---

# Human-in-the-Loop Planning Gate & Delegation Matrix (P0 — Enterprise v2.0)

> **Core Philosophy:** The user should never need to memorize agent rosters or manually decompose complex problems. The AI autonomously synthesizes an independent delegation plan, performs Git branch safety setup in Phase 0, and presents it for user review via the native "Proceed" button before touching any source code.

---

## 🛑 1. When This Gate Applies

Mandatory 100% adherence for:
1. **Comprehensive Audits & Reviews:** "review all code", "security audit", "system-wide review".
2. **Architectural Refactoring:** "refactor", "restructure codebase", "migrate architecture".
3. **Multi-Domain Features:** Tasks touching 2 or more distinct layers (Frontend + Backend + DB + CI/CD).
4. **Any request involving more than 3 non-trivial execution steps.**

---

## 📋 2. Enterprise Delegation Matrix (Including Phase 0)

Before executing any heavy inspection tools, modifying code, or running test suites, the AI (acting as `orchestrator`) MUST formulate the following table:

### Required Matrix Structure:

| Phase | Phase Name & Objective | Assigned Specialist Agent | Relevant Skills | Expected Deliverables |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 0** | **Workspace & Git Safety Setup** | `devops-engineer` / `orchestrator` | `@bash-linux` | Isolated `feat/*` branch checked out safely |
| **Phase 0.5** | **Base Context Scaffold & Auto-Detection** | `orchestrator` / `project-planner` / `devops-engineer` | `@bash-linux` | `.agents/` context structure bootstrapped with auto-detected tech stack & manifests |
| **Phase 1** | Discovery & Lineage Audit | `code-archaeologist` | `@architecture` | Current state map & test baseline |
| **Phase 2** | Specialized Audit & Patching | `security-auditor` / `backend-specialist` | `@vulnerability-scanner` | Source patches within disjoint file scopes |
| **Phase 3** | Acceptance Testing & Zero Regression | `qa-automation-engineer` | `@testing-patterns` | 100% automated test suite pass matrix |
| **Phase 4** | Consolidation, Release & PR Ready | `orchestrator` | `@clean-code` | Deliverable report & PR ready for merge |

---

## 🚪 3. The "Proceed" Approval Gate (Artifact Feedback Barrier)

1. **Publish Plan to an Artifact:**
   The AI MUST output the matrix and execution plan to a markdown file with metadata:
   ```json
   "ArtifactMetadata": {
     "RequestFeedback": true,
     "UserFacing": true,
     "Summary": "Multi-agent delegation plan and Git branch safety setup awaiting approval."
   }
   ```
2. **🛑 HARD STOP (Immediate Tool Termination):**
   - The AI **MUST STOP CALLING TOOLS IMMEDIATELY** after publishing the plan artifact.
   - **STRICTLY FORBIDDEN:** Do NOT execute Phase 0 or edit any files before the user clicks the **Proceed** button or confirms explicitly in chat.

---

## ⚡ 4. Execution Discipline Post-Approval

1. **Phase 0 is Mandatory:**
   - In Turn 1 following user approval, the Orchestrator runs: `git branch --show-current`.
   - If on `main` or `master`, create a new branch: `git checkout -b feat/<task-slug>-<date>`.
2. **Phase 0.5 Context Scaffold Execution (When Applicable):**
   - Immediately following branch safety verification in Phase 0 and before Phase 1 discovery begins, verify if `.agents/knowledge/project-overview.md` exists in the target repository.
   - If missing or uninitialized, execute `./scripts/scaffold.sh <target-dir>` (or `make scaffold-project TARGET=<target-dir>`) to automatically discover ecosystem manifests (Node.js `package.json`, Python `pyproject.toml`/`requirements.txt`, Rust `Cargo.toml`, Go `go.mod`) and populate standardized `.agents/` knowledge specs and workflow runbooks before Phase 1 discovery begins.
3. **Phase Boundary Checkpoints & Mandatory Dispatch:**
   - Every time execution transitions to an implementation phase, announce publicly in chat:
   ```markdown
   ---
   ### 🚀 Phase [X]: [Phase Name]
   🤖 **Applying knowledge of `@[specialist-agent]`...**
   📚 **Using skills: `@[skill-1]` + `@[skill-2]`...**
   > **Objective:** [Concise 1-2 sentence summary of phase scope]
   ```
   - 🛑 **MANDATORY DISPATCH (No-Pretense Gate):** The Phase checkpoint announcement MUST be accompanied in the same or immediately following step by the actual dispatch tool call (`invoke_subagent` or `swarm action: 'add'`) with the structured Delegation Contract.
   - **STRICTLY FORBIDDEN:** The Orchestrator MUST NEVER emit a specialist announcement and then execute the code implementation itself in the coordinator thread (*Pretense Violation*).
4. **Anti-Silent Circuit Breaker:** Never execute more than 4 consecutive tool calls without interim progress updates to the user.
5. **Contract-Based Delegation:** Every subagent must receive a contract enforcing `Allowed File Paths` per `rules/delegation-contract.md`.
6. **Coordinator Synthesis Monopoly:** Specialist subagents write code within their isolated scopes; the Orchestrator remains the sole authority for final git validation, test suite execution, and deliverable reporting in Phase 4.
7. **Subagent Model Tiering & `schedule` Watchdogs:** Coordinators calling `invoke_subagent` MUST default to `Model: "flash"` for discovery (`explorer-agent`), routine implementation, and QA/test scripting (reserving `inherit` / `pro` for deep architecture, complex debugging, or multi-domain synthesis) and attach a `schedule` one-shot watchdog (`DurationSeconds: 600`, `TimerCondition: "<subagentId>"` or `"any"`) for long-running subagents.
8. **Background Task Communication & Clean Wakeups:** Subagents launching a background `run_command` MUST send an interim `send_message` update to the parent BEFORE ending their turn to wait (monitoring with `NotificationTimeoutSeconds` / `schedule`), since canceled tasks emit `MESSAGE_PRIORITY_LOW` and will NOT wake an idle subagent. Coordinators waking on watchdog timeout or user `"Continue"` MUST communicate via `send_message` / `manage_subagents`, never peeking raw `transcript.jsonl` via shell.
9. **Bounded Execution (`120s` Timeout & `MAX_RETRIES=3`):** Verification and test commands MUST enforce a `120s` portable hard timeout (never relying on `WaitMsBeforeAsync` or `NotificationTimeoutSeconds` to terminate processes) and `MAX_RETRIES=3` retry cap before escalating.


---

---

## 🛑 5. Phase 4 Completion & The Human Merge Barrier

1. **Phase 4 Verification & Deliverables:**
   - Phase 4 (Consolidation, Release & PR Ready) must conclude on the feature branch with:
     - 100% automated test suite passing on the feature branch.
     - Verified deliverable presentation and comprehensive diff summary.
     - All documentation, summaries, dashboards, and manifests committed to the feature branch.
     - An **Execution & Resilience Metrics** table covering: `Agent / Subagent (ID)`, `Model Tier`, `Wall Time`, `Timeouts Configured / Triggered`, `Retry Attempts (used/max)`, `Circuit-Breaker Denials`, and `Completion Signal` (`send_message` vs watchdog/manual resume).

2. **HARD STOP ON FEATURE BRANCH (The Human Merge Barrier):**
   - The coordinator is **STRICTLY PROHIBITED** from autonomously executing `git checkout main && git merge`.
   - The coordinator must remain on the feature branch and explicitly prompt the user:
     > "All Phase 4 verification tests have passed on `feat/<task-slug>`. Would you like me to merge this branch into `main`, or keep it on the feature branch / create a PR?"

3. **Explicit User Merge Order Required:**
   - Merging into `main` is permitted **ONLY** after the user explicitly responds with a merge order (e.g., `merge`, `merge all`).
   - Autonomous merging without explicit user confirmation is strictly forbidden.
