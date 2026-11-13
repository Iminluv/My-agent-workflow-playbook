# 🤖 Antigravity Multi-Agent Workflow & Enterprise Governance Kit (v2.0)

> Multi-agent orchestration rules, Human-in-the-Loop Planning Gate, and enterprise Standard Operating Procedures (SOP) for Google Antigravity.

---

## 📌 Overview

This repository standardizes collaboration principles between human engineers and autonomous AI agent teams:
1. **Human-in-the-Loop Planning Gate:** Mandates that the AI formulate an explicit Delegation Matrix and pause execution at a "Proceed" barrier before modifying source code or running heavy tasks.
2. **Phase 0 Git Branch Safety (P0):** Strictly prohibits direct edits or commits on `main` or `master`. Enforces isolated feature branches (`feat/*`).
3. **True Multi-Agent Delegation:** Dispatches independent, specialized subagents (`security-auditor`, `backend-specialist`, `frontend-specialist`, `devops-engineer`) with disjoint file ownership contracts instead of monolithic execution.
4. **Anti-Silent Execution & Transparency:** Enforces immediate Turn-1 skill announcements, phase boundary checkpoints, and circuit breakers against silent tool loops (>8 tools).
5. **Decoupled CI/CD Architecture:** Provides 2-stage GitHub Actions templates (CI Gate on PRs with secret scanning and tests; CD on verified tags with health-check-driven rollback).
6. **Obsidian SOP Playbook:** Comprehensive operational guide with native Mermaid architecture diagrams, callouts, and empirical real-world case studies.

---

## 📂 Repository Structure

```text
.
├── WORKFLOW-PLAYBOOK.md        # 📘 Enterprise SOP playbook (Obsidian-compliant)
├── README.md                   # 📖 Documentation and onboarding guide
├── Makefile                    # ⚡ Developer commands (make install, make verify)
├── skills-lock.json            # 🔒 Deterministic skill dependency lockfile
├── rules/                      # 🏛️ Persistent governance rules for Antigravity
│   ├── GEMINI.md               # Persistent constraints and specialist delegation
│   ├── core-protocol.md        # Turn-1 constraints, path awareness, anti-silent loop
│   ├── planning-gate.md        # Phase 0 setup & Proceed gate approval barrier (v2.0)
│   ├── git-safety.md           # P0 rule: strict prohibition of direct edits on main
│   ├── delegation-contract.md  # Multi-agent prompt injection & file ownership contract
│   ├── impact-analysis.md      # Full-stack "One Change, Two Sides" synchronization
│   ├── request-routing.md      # Autonomous domain classifier and specialist router
│   ├── universal-rules.md      # Global engineering constraints (Clean code, standards)
│   ├── code-rules.md           # Implementation rules and Socratic gate
│   ├── design-rules.md         # UI/UX engineering constraints
│   └── quick-reference.md      # High-speed lookup index for agents and skills
├── agents/                     # 🤖 Specialist agent role definitions
│   ├── orchestrator.md         # Multi-agent coordinator with trust boundary
│   ├── backend-specialist.md   # Backend engineer with Step 0 branch check
│   └── devops-engineer.md      # CI/CD and deployment engineer
├── templates/                  # 📦 Reusable project templates
│   ├── cicd/                   # Enterprise GitHub Actions workflows (CI Gate, Deploy)
│   └── agents_scaffold/        # Standard .agents/ scaffold (knowledge, workflows)
└── scripts/                    # ⚙️ Automation and validation tooling
    ├── install.sh              # One-click bootstrap script (symlink/copy)
    └── verify.sh               # Comprehensive integrity verification script
```

---

## 🚀 Quick Start & Synchronization

### Step 1: Clone Repository
```bash
git clone <YOUR_GITHUB_REPO_URL> ~/Vscode/Agent-test
cd ~/Vscode/Agent-test
```

### Step 2: Run Automated Installation
```bash
make install
```
*   **Default Mode (Symlink):** Creates symbolic links to `~/.gemini/config/plugins/ag-kit/rules/` and `agents/`. Any updates in this repository take effect immediately across Antigravity sessions.
*   **Static Copy Mode:** Run `make install-copy` to copy static files without symlinks.
*   *Automated Backup:* Detects existing configurations and creates a safe timestamped backup.

### Step 3: Verify Configuration Integrity
```bash
make verify
```

---

## 📓 Integration with Obsidian

The file `WORKFLOW-PLAYBOOK.md` is 100% compatible with **Obsidian**:
*   Full support for **Obsidian Callouts** (`[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!ABSTRACT]`).
*   Interactive **Mermaid Diagrams** (multi-tier system architecture, sequential reactive loop).
*   Bidirectional **Wikilinks** (`[[...]]`) to seamlessly link into your personal Knowledge Graph.

Simply drag and drop `WORKFLOW-PLAYBOOK.md` into your Obsidian Vault to reference anytime.

---

## 📜 License
MIT License. Free to use, adapt, and distribute for personal and enterprise engineering workflows.
