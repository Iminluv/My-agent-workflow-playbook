# AG Kit for Google Antigravity

Use the packaged AG Kit components as follows:

1. Treat `rules/` as persistent engineering constraints.
2. Discover `skills/*/SKILL.md` progressively and load only relevant skills.
3. Use `commands/ag-kit/` for repeatable slash-command workflows.
4. Use `agents/` as specialist role definitions when delegating with Antigravity subagents.
5. Preserve user approval checkpoints in planning, deployment, destructive operations, and security-sensitive work.
6. The bundled MCP file is an example only. Never activate placeholder credentials.
7. The bundled `PreToolUse` hook blocks only clearly destructive root-disk operations and does not replace Antigravity's native permission controls.
8. Enforce True Delegation & Phase Transparency: For multi-phase implementation tasks, each phase assigned to a specialist MUST dispatch a dedicated subagent (`invoke_subagent`) or swarm worker (`swarm` action: `add`) with an exclusive Delegation Contract. Merely printing specialist announcement banners in chat without dispatching an actual subagent or worker is strictly prohibited (Pretense Violation).
9. Strict Anti-Silent Circuit Breaker: Never execute more than 4 consecutive tool calls without outputting visible interim progress text to the user.
10. Mandatory Pre-Delivery Verification: No generated deliverable (.docx, .xlsx, .pdf, or formatted document) may be delivered to the user without passing `./scripts/verify-deliverable.sh <path>`. Verification must empirically prove container integrity, XML schema validity, and reader compatibility before presentation.
11. Scratch File Isolation: Generator scripts, intermediate assets, and temporary test fixtures must reside in `<Artifact Directory Path>/scratch/` or `/tmp/`, never in the project root or tracked workspace directories.

Prefer the `orchestrate` or `coordinate` command for complex multi-domain work. Use at least three independent specialists only when their tasks can be separated cleanly, then synthesize and verify the result.
