---
name: planning-gate
version: 1.0.0
priority: P0
trigger: always_on
description: Mandatory Human-in-the-Loop Planning Gate and Phase-to-Agent/Skill Delegation Matrix for audits, reviews, complex features, and multi-step implementations.
---

# Human-in-the-Loop Planning Gate & Delegation Matrix (P0)

> **Core Philosophy:** The user should never need to memorize all agents and skills, nor manually figure out how to divide complex tasks across specialists. The AI must autonomously formulate the delegation plan, present it for review, and wait for explicit human approval before executing.

---

## 🛑 1. When This Gate Applies

This protocol is **MANDATORY** whenever a request involves:
1. **Audits & Comprehensive Reviews** ("review every code, plan, decision", "kiểm toán toàn diện", "security review").
2. **Complex Code & Architectural Refactoring** ("refactor", "tái cấu trúc", "build new architecture").
3. **Multi-Domain Features** (involving backend, frontend, database, or security combined).
4. **Any task requiring more than 3 non-trivial execution steps.**

---

## 📋 2. Autonomous Delegation Matrix Formulation

Before running extensive tools, deep test suites, or modifying code, the AI (acting as `project-planner` or `orchestrator`) MUST synthesize a structured **Delegation Matrix**:

### Required Matrix Format:

| Phase | Phase Name & Objective | Assigned Specialist Agent | Relevant Skills to Apply | Expected Deliverable |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 1** | Discovery & History Audit | `code-archaeologist` | `@architecture`, `@bash-linux` | Worktree lineage & plan comparison report |
| **Phase 2** | Test Automation & Regression | `qa-automation-engineer` | `@testing-patterns` | Automated test suite execution & pass matrix |
| **Phase 3** | Offensive Security Audit | `security-auditor` | `@vulnerability-scanner` | Process sandbox, argv & CSRF vulnerability report |
| **Phase 4** | Code Quality & Refactoring | `orchestrator` / `backend-specialist` | `@clean-code`, `@python-patterns` | Actionable refactoring & consolidation roadmap |

### Rules for Agent & Skill Selection:
- **Auto-Discovery:** Select agents from the project/system roster (`security-auditor`, `frontend-specialist`, `backend-specialist`, `devops-engineer`, `code-archaeologist`, `qa-automation-engineer`, etc.).
- **Domain Pairing:** Pair each phase with 1–2 specific skills from the catalog (e.g. `@vulnerability-scanner`, `@clean-code`, `@testing-patterns`, `@frontend-architecture`).
- **No User Burden:** Never ask the user "Which agent should I use?". The AI proposes the optimal roster upfront.

---

## 🚪 3. The "Proceed" Approval Gate (Artifact with Feedback)

1. **Publish as Plan Artifact:**
   The AI MUST write the complete plan and Delegation Matrix to an artifact markdown file (e.g., `<appDataDir>/brain/<conversation-id>/plan.md` or `{task-slug}-plan.md`) with:
   ```json
   "ArtifactMetadata": {
     "RequestFeedback": true,
     "UserFacing": true,
     "Summary": "Detailed delegation matrix and execution plan awaiting user review and approval."
   }
   ```
   > 💡 Setting `RequestFeedback: true` renders a native, clickable **"Proceed"** button directly in the chat UI!

2. **Present Concise Summary to User:**
   In chat, concisely highlight:
   - The phases and their assigned Specialist Agents + Skills.
   - Any key open architectural trade-offs or optional dimensions.
   - Point the user to review the plan artifact.

3. **🛑 HARD STOP (Strict Barrier):**
   - The AI **MUST STOP CALLING TOOLS IMMEDIATELY** after creating the plan artifact and sending the presentation message.
   - **STRICTLY FORBIDDEN:** Do NOT begin executing Phase 1, running heavy test suites, or editing code until the user clicks **Proceed** or confirms in chat (e.g., *"Proceed"*, *"OK"*, *"Đồng ý"*).

---

## 👥 4. Third-Party & Peer Review Capability

Because the plan is rendered in a dedicated Artifact document:
- The user, colleagues, or peer reviewers can read the exact breakdown.
- They can adjust the scope, add special audit dimensions (e.g. "Add API rate limiting audit to Phase 3"), or swap specialists before any compute or quota is spent.
- Once feedback is incorporated, the user confirms to proceed.

---

## ⚡ 5. Execution after Approval & Multi-Phase Discipline

Once approval is granted:

### 5.1. Phase-to-Phase Transition Checkpoints (MANDATORY)
- **Turn 1 of Execution:** Immediately announce Phase 1:
  `🤖 **Applying knowledge of `@[specialist-agent]`...**`
  `📚 **Using skill: `@[skill-name]`...**`
- **At EVERY Phase Boundary:** When Phase N completes and Phase N+1 begins, the coordinator MUST emit an explicit text checkpoint in chat:
  ```markdown
  ---
  ### 🚀 Bắt đầu Phase [X]: [Tên Phase]
  🤖 **Applying knowledge of `@[specialist-agent]`...**
  📚 **Using skills: `@[skill-1]` + `@[skill-2]`...**
  > **Mục tiêu:** [Tóm tắt 1-2 câu về phạm vi và kết quả mong muốn của Phase này]
  ```
- ❌ **STRICTLY FORBIDDEN:** Running multiple phases in a single silent tool-execution loop. Transitioning to a new domain (e.g., from Backend Security to Frontend SPA) without an explicit announcement is a **CRITICAL PROTOCOL VIOLATION**.

### 5.2. Subagent Delegation vs Monolithic Execution
- **True Multi-Agent Execution (Recommended for Separable Domains):**
  - When the plan involves distinct domains (e.g., Security, Backend, Frontend, Testing), the coordinator (`orchestrator`) SHOULD invoke dedicated subagents (`invoke_subagent`) matching the assigned specialist role:
    - Pass `TypeName: "self"` (or specialist name), `Role: "<Specialist Name>"`, and a clear scoped prompt.
    - Each subagent executes in its own isolated turn/context and sends the result back.
- **Monolithic Execution (When executing in the parent turn):**
  - If running in the parent conversation, the agent MUST strictly adhere to the **Phase Transition Checkpoints** above.
  - **No Pretense Rule:** The agent must NEVER claim in the final summary that "the team of specialists A, B, C completed the tasks" unless each specialist was actually either invoked as a subagent or explicitly announced at their phase transition.

### 5.3. Anti-Silent Loop Circuit Breaker (Max 8 Tool Calls)
- The agent **MUST NOT** execute more than 8 tool calls consecutively without outputting visible interim progress text to the user.
- Periodic progress reports (e.g., test suite finished, scanning module X completed) ensure transparency and prevent user perception of a hung or unresponsive session.

### 5.4. Deliverable Synthesis & Final Artifact
- Consolidate all phase findings into the final deliverable artifact (e.g. `{task-slug}-report.md`) with `UserFacing: true`.
- Present a concise executive summary in chat referencing the artifact. DO NOT duplicate the entire report content into the chat message.
