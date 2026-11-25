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
10. Mandatory Pre-Delivery Verification: No generated deliverable (.docx, .xlsx, .pdf, or formatted document) may be delivered to the user without passing `./scripts/verify-deliverable.sh <path>` (or `~/.gemini/config/plugins/ag-kit/scripts/verify-deliverable.sh <path>` when working inside external target repos). Verification must empirically prove container integrity, XML schema validity, and reader compatibility before presentation.
11. Scratch File Isolation: Generator scripts, intermediate assets, and temporary test fixtures must reside in `<Artifact Directory Path>/scratch/` or `/tmp/`, never in the project root or tracked workspace directories.
12. Bounded Timeouts & Retries: Verification and test commands MUST enforce a `120s` hard timeout using macOS-portable wrappers (e.g., `perl -e 'alarm shift; exec @ARGV' 120 ...`, Python `subprocess.run(..., timeout=120)`, or bounded wait loops — never rely on `WaitMsBeforeAsync` or `NotificationTimeoutSeconds` to terminate commands) and a `MAX_RETRIES=3` retry ceiling with stop-and-escalate on failure. Bash test scripts MUST avoid bare `wait` with background daemons (use `wait "$PID"`), set `trap 'kill -TERM ... 2>/dev/null || true' EXIT INT TERM`, and guard arrays for Bash 3.2 `set -u` (`if [ ${#ARR[@]} -gt 0 ]`).
13. Subagent Watchdogs, Messaging & Model Tiering: Default to `Model: "flash"` on `invoke_subagent` for discovery (`explorer-agent`), routine implementation, and QA/test scripting; reserve `inherit` / `pro` for deep architecture, complex debugging, or multi-domain synthesis. Attach a `schedule` one-shot watchdog (`DurationSeconds: 600`, `TimerCondition: "<subagentId>"` or `"any"`) for long-running subagents, communicate on wakeup via `send_message` / `manage_subagents` (never inspect raw `transcript.jsonl` via shell), and require subagents to send an interim `send_message` to the parent BEFORE ending their turn to wait on a background `run_command` (monitoring via `NotificationTimeoutSeconds` / `schedule`, since canceled tasks emit `MESSAGE_PRIORITY_LOW` and will not wake an idle subagent).

Prefer the `orchestrate` or `coordinate` command for complex multi-domain work. Use at least three independent specialists only when their tasks can be separated cleanly, then synthesize and verify the result.
