---
name: planning-gate
version: 2.0.0
priority: P0
trigger: always_on
description: Mandatory Human-in-the-Loop Planning Gate and Phase-to-Agent/Skill Delegation Matrix with Phase 0 Git Branch Setup, Disjoint Ownership, and Proceed Approval Barrier.
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
2. **Phase Boundary Checkpoints:**
   Every time execution transitions to a new phase or domain, announce publicly in chat:
   ```markdown
   ---
   ### 🚀 Phase [X]: [Phase Name]
   🤖 **Applying knowledge of `@[specialist-agent]`...**
   📚 **Using skills: `@[skill-1]` + `@[skill-2]`...**
   > **Objective:** [Concise 1-2 sentence summary of phase scope]
   ```
3. **Anti-Silent Circuit Breaker:** Never execute more than 8 consecutive tool calls without interim progress updates to the user.
4. **Contract-Based Delegation:** Every subagent must receive a contract enforcing `Allowed File Paths` per `rules/delegation-contract.md`.
