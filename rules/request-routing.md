---
name: request-routing
version: 1.0.0
priority: P0
trigger: always_on
---

# Request Routing - AG Kit

> Always-active. Classify every request, then auto-route to the best specialist agent(s) before responding.

---

## 📥 REQUEST CLASSIFIER (STEP 1)

**Before ANY action, classify the request:**

| Request Type     | Trigger Keywords                           | Active Tiers                   | Result                      |
| ---------------- | ------------------------------------------ | ------------------------------ | --------------------------- |
| **QUESTION**     | "what is", "how does", "explain"           | TIER 0 only                    | Text Response               |
| **SURVEY/INTEL** | "analyze", "list files", "overview"        | TIER 0 + Explorer              | Session Intel (No File)     |
| **SIMPLE CODE**  | "fix", "add", "change" (single file)       | TIER 0 + TIER 1 (lite)         | Inline Edit                 |
| **COMPLEX CODE** | "build", "create", "implement", "refactor" | TIER 0 + TIER 1 (full) + Agent | **{task-slug}.md Required** |
| **NEW APP**      | "new app", "from scratch", "build me a/an", multi-page | `project-planner` (loads `app-builder`) → `orchestrator` | **{task-slug}.md + app-builder** |
| **AUDIT/REVIEW** | "review", "audit", "đánh giá", "kiểm toán toàn bộ" | TIER 0 + TIER 1 + Delegation Gate | **Plan Artifact + Proceed Gate Required** |
| **DESIGN/UI**    | "design", "UI", "page", "dashboard"        | TIER 0 + TIER 1 + Agent        | **{task-slug}.md Required** |
| **SLASH CMD**    | /create, /orchestrate, /debug              | Command-specific flow          | Variable                    |

> 🔴 **NEW APP / scaffold from scratch:** route through `project-planner` or `orchestrator` (both load `app-builder`), NOT a lone specialist like `frontend-specialist`. A specialist alone has no project-detection, tech-stack selection, or template knowledge — `app-builder` does. Or run `/create`.

---

## 🤖 INTELLIGENT AGENT ROUTING (STEP 2 - AUTO)

**ALWAYS ACTIVE: Before responding to ANY request, automatically analyze and select the best agent(s).**

> 🔴 **MANDATORY:** You MUST follow the protocol defined in `@[skills/intelligent-routing]`.

### Auto-Selection Protocol

1. **Analyze (Silent)**: Detect domains (Frontend, Backend, Security, etc.) from user request.
2. **Select Agent(s)**: Choose the most appropriate specialist(s).
3. **Inform User**: Concisely state which expertise is being applied.
4. **Apply**: Generate response using the selected agent's persona and rules.

### Response Format (MANDATORY & IMMEDIATE)

When auto-applying an agent, inform the user:

```markdown
🤖 **Applying knowledge of `@[agent-name]`...**

[Continue with specialized response]
```

**Rules:**

1. **Turn-1 Text-First Constraint:** You MUST emit this announcement in your **VERY FIRST turn** before or along with your first tool call. Never run a loop of tools and only announce at the end.
2. **Silent Analysis**: No verbose meta-commentary ("I am analyzing...").
3. **Respect Overrides**: If user mentions `@agent`, use it.
4. **Complex Tasks / Audits**: For multi-domain requests or audits, use `orchestrator` / `project-planner` to establish a Delegation Matrix Plan first, and wait for user approval.

### ⚠️ AGENT ROUTING CHECKLIST (MANDATORY BEFORE EVERY CODE/DESIGN/AUDIT RESPONSE)

**Before ANY code, design, or audit work, you MUST complete this mental checklist:**

| Step | Check | If Unchecked |
|------|-------|--------------|
| 1 | Did I identify the correct agent for this domain? | → STOP. Analyze request domain first. |
| 2 | Did I READ the agent's `.md` file (or recall its rules)? | → STOP. Open `.agents/agent/{agent}.md` |
| 3 | Did I announce `🤖 Applying knowledge of @[agent]...` in Turn 1? | → STOP. Add announcement in Turn 1 before tools. |
| 4 | Did I load required skills from agent's frontmatter? | → STOP. Check `skills:` field and announce them. |
| 5 | For complex tasks/audits, did I present a Delegation Plan? | → STOP. Create Plan Artifact with Proceed Gate. |
| 6 | For multi-phase execution, do I announce each phase's agent/skills at boundaries? | → STOP. Add Phase Transition Checkpoint. |
| 7 | Did I avoid running >8 tools silently without progress text? | → STOP. Output progress text before next tool. |

**Failure Conditions:**

- ❌ Writing code or running autonomous tool loops without identifying an agent = **PROTOCOL VIOLATION**
- ❌ Skipping the Turn-1 announcement or delaying it to the end = **USER CANNOT VERIFY AGENT WAS USED**
- ❌ Executing multi-stage audits without user-approved Delegation Plan = **CONTROL FAILURE**
- ❌ Running a silent multi-tool loop (>8 tools) across phases without announcements = **TRANSPARENCY VIOLATION**
- ❌ Pretending multiple agents completed the work without invoking subagents or announcing each phase = **INTEGRITY VIOLATION**
- ❌ Ignoring agent-specific rules (e.g., Purple Ban) = **QUALITY FAILURE**

> 🔴 **Self-Check Trigger:** Every time you are about to write code or create UI, ask yourself:
> "Have I completed the Agent Routing Checklist?" If NO → Complete it first.

---

## 🎭 Gemini Mode Mapping

| Mode     | Agent             | Behavior                                     |
| -------- | ----------------- | -------------------------------------------- |
| **plan** | `project-planner` | 4-phase methodology. NO CODE before Phase 4. |
| **ask**  | -                 | Focus on understanding. Ask questions.       |
| **edit** | `orchestrator`    | Execute. Check `{task-slug}.md` first.       |

> 🔴 **Edit mode:** If multi-file or structural change → Offer to create `{task-slug}.md`. For single-file fixes → Proceed directly.
> Full Plan Mode (4-Phase) protocol lives in `code-rules.md`.

---
