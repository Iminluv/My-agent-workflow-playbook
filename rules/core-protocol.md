---
name: core-protocol
version: 1.0.0
priority: P0
trigger: always_on
---

# Core Protocol - AG Kit

> The highest-priority workspace rules. How the AI loads agents/skills and what it must do before any implementation.

---

## CRITICAL: AGENT & SKILL PROTOCOL (START HERE)

> **MANDATORY:** You MUST read the appropriate agent file and its skills BEFORE performing any implementation. This is the highest priority rule.

### 1. Modular Skill Loading Protocol

Agent activated → Check frontmatter "skills:" → Read SKILL.md (INDEX) → Read specific sections.

- **Selective Reading:** DO NOT read ALL files in a skill folder. Read `SKILL.md` first, then only read sections matching the user's request.
- **Rule Priority:** P0 (Workspace Rules in `.agents/rules/`) > P1 (Agent `.md`) > P2 (SKILL.md). All rules are binding.

### 1.1 Skill Announcement (MANDATORY & IMMEDIATE)

**Every time you load and apply a skill, announce it BEFORE or AT THE START of using it** — so the user can verify which knowledge is active from the very first second.

```markdown
📚 **Using skill: `@[skill-name]`...**
```

- List multiple skills together: `📚 Using skills: @frontend-design + @design-spec...`
- Announce on-demand skills too (e.g. a companion skill pulled from a hub, or `app-builder` for a new app), not just frontmatter ones.
- 🔴 **CRITICAL TIMING (Turn-1 Text-First Constraint):** You MUST emit the announcement text (`🤖 Applying knowledge of...` and `📚 Using skill:...`) in your **VERY FIRST turn**, BEFORE or along with your first tool call.
- ❌ **FORBIDDEN:** NEVER defer announcements to the final response or hide them behind a long tool-execution loop. Running multiple tools silently and only announcing at the end is a **STRICT PROTOCOL VIOLATION**.
- ❌ Applying a skill without announcing it = **USER CANNOT VERIFY THE SKILL WAS USED**.

### 1.2 Phase Transition & Anti-Silent Execution Protocol (MANDATORY)

- **Phase Boundary Announcement:** In multi-phase or multi-domain tasks, announcements are **NOT** a one-time event for Turn 1. Every time execution crosses a phase or domain boundary, the AI **MUST** emit an explicit transition checkpoint before calling tools in that phase:
  ```markdown
  ---
  ### 🚀 Phase [X]: [Phase Name]
  🤖 **Applying knowledge of `@[specialist-agent]`...**
  📚 **Using skills: `@[skill-1]` + `@[skill-2]`...**
  ```
- **Circuit Breaker against Silent Tool Loops:** An agent **MUST NOT** execute more than 8 tool calls consecutively without outputting visible interim progress text to the user.
- **Transparency Mandate:** The user must be able to verify at all times:
  1. Which specialist agent is currently active.
  2. What skills are loaded for the current phase.
  3. What step/milestone is currently being executed.

### 2. Enforcement Protocol

1. **When agent is activated:**
    - ✅ Activate: Read Rules → Check Frontmatter → Load SKILL.md → Apply All.
2. **Forbidden:** Never skip reading agent rules or skill instructions. "Read → Understand → Apply" is mandatory.

---

## 📁 File Dependency Awareness

**Before modifying ANY file:**

1. If `CODEBASE.md` exists, check its File Dependencies section.
2. Otherwise, discover dependencies with targeted search/import analysis; do not block waiting for a missing file.
3. Identify dependent files and update all affected files together.

---

## 🗺️ System Map & Memory Read

> 🔴 **MANDATORY:** At session start, you MUST read `.agents/memory/MEMORY.md` to load persistent project conventions, user preferences, and decisions.

> 📚 **Catalog lookup (on-demand, NOT every session):** Need the full list of Agents / Skills / Scripts? The `quick-reference` rule has the essentials. For the complete catalog, read `.agents/ARCHITECTURE.md` only when you actually need it (e.g. orchestration, or discovering a skill you're unsure exists) — do NOT load it on every request.

**Path Awareness (Note: the project directory name is `.agents` plural):**

- Agents: `.agents/agent/` (Project)
- Skills: `.agents/skills/` (Project)
- Memory: `.agents/memory/` (Project)
- Runtime Scripts: `.agents/skills/<skill>/scripts/`

---

## 🧠 Read → Understand → Apply

```
❌ WRONG: Read agent file → Start coding
✅ CORRECT: Read → Understand WHY → Apply PRINCIPLES → Code
```

**Before coding, answer:**

1. What is the GOAL of this agent/skill?
2. What PRINCIPLES must I apply?
3. How does this DIFFER from generic output?

---
