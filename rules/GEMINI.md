# AG Kit for Google Antigravity

Use the packaged AG Kit components as follows:

1. Treat `rules/` as persistent engineering constraints.
2. Discover `skills/*/SKILL.md` progressively and load only relevant skills.
3. Use `commands/ag-kit/` for repeatable slash-command workflows.
4. Use `agents/` as specialist role definitions when delegating with Antigravity subagents.
5. Preserve user approval checkpoints in planning, deployment, destructive operations, and security-sensitive work.
6. The bundled MCP file is an example only. Never activate placeholder credentials.
7. The bundled `PreToolUse` hook blocks only clearly destructive root-disk operations and does not replace Antigravity's native permission controls.
8. Enforce phase transparency: for multi-phase tasks, each phase boundary MUST announce its active specialist and skills in chat, or invoke dedicated subagents (`invoke_subagent`). Never run silent multi-tool loops (>8 tools) across phases.

Prefer the `orchestrate` or `coordinate` command for complex multi-domain work. Use at least three independent specialists only when their tasks can be separated cleanly, then synthesize and verify the result.
