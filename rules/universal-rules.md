---
name: universal-rules
version: 1.0.0
priority: P0
trigger: always_on
---

# Universal Rules (TIER 0) - AG Kit

> Always-active rules that apply to every request, regardless of domain.

---

## 🌐 Language Handling

When user's prompt is NOT in English:

1. **Internally translate** for better comprehension
2. **Respond in user's language** - match their communication
3. **Code comments/variables** remain in English

---

## 🧹 Clean Code (Global Mandatory)

**ALL code MUST follow `@[skills/clean-code]` rules. No exceptions.**

- **Code**: Concise, direct, no over-engineering. Self-documenting.
- **Testing**: Mandatory. Pyramid (Unit > Int > E2E) + AAA Pattern.
- **Performance**: Measure first. Adhere to current Core Web Vitals standards.
- **Infra/Safety**: 5-Phase Deployment. Verify secrets security.

---

## 🛡️ Zero-Defect Delivery & Pre-Delivery Verification (Global Mandatory)

**No deliverable file may be presented or delivered to the user without empirical pre-delivery verification.**

- **Mandatory Pre-Delivery Gate**: Every generated file (`.docx`, `.xlsx`, `.pdf`, `.md`, `.txt`, `.json`) MUST pass `./scripts/verify-deliverable.sh <file>` (or `~/.gemini/config/plugins/ag-kit/scripts/verify-deliverable.sh <file>` when operating inside an external target repository) prior to final presentation.
- **Strict Format & Schema Adherence**:
  - Word documents (`.docx`): Ensure valid ZIP container, well-formed XML trees, and strict WordprocessingML OpenXML compliance (no orphaned `<w:fldChar>` or `<w:instrText>` directly under `<w:p>`). Must pass OS-level reader parse checks (`textutil` on macOS).
  - Excel spreadsheets (`.xlsx`): Ensure valid ZIP container and `[Content_Types].xml` + `xl/workbook.xml` schema integrity.
  - PDF documents (`.pdf`): Verify `%PDF-` header and `%%EOF` trailer integrity.
  - Text & Markdown deliverables: Verify UTF-8 clean encoding and absence of corrupted binary null bytes.
- **Scratch Space Discipline**: All temporary generation scripts, scratch files, and exploratory test fixtures must be created in `<Artifact Directory Path>/scratch/` or `/tmp/`. Never pollute the workspace root or commit temporary scratch assets to Git.

---

## ⏱️ Execution Resilience, Timeouts & Bash Safety (Global Mandatory)

**Every command, retry loop, and test script MUST fail fast and clean up deterministically:**

- **Default `120s` Hard Command Timeout:** Verification, build, and test commands MUST enforce an explicit `120s` hard timeout.
  - Because macOS lacks GNU `timeout` by default, use portable wrappers such as `perl -e 'alarm shift; exec @ARGV' 120 <cmd> [args...]`, Python `subprocess.run(..., timeout=120)`, or bounded wait loops.
  - **Tool Parameter Warning:** NEVER rely on `WaitMsBeforeAsync` as a command timeout (`WaitMsBeforeAsync` only backgrounds an uncompleted command), and note that `NotificationTimeoutSeconds` only emits a reminder ping — neither parameter kills a hung process.
- **Bounded Retry Ceiling (`MAX_RETRIES=3`):** Automated retries (flaky checks, health polls, transient steps) MUST enforce `MAX_RETRIES=3` (max 3 attempts) and stop-and-escalate with diagnostic logs upon exhaustion. Silent or infinite retry loops are strictly prohibited.
- **Bash 3.2 & Background Process Hygiene:**
  - **Ban bare `wait`:** Never call bare `wait` in scripts that start background servers or daemons (it hangs indefinitely waiting for the daemon). Always `wait "$CLIENT_PID"` on explicit job PIDs.
  - **Mandatory Server Cleanup Traps:** Any script launching a background server or daemon MUST register `trap 'kill -TERM "$SERVER_PID" 2>/dev/null || true' EXIT INT TERM`.
  - **Bash 3.2 `set -u` Empty-Array Safety:** Always guard array expansions with `if [ ${#ARR[@]} -gt 0 ]` before expanding `"${ARR[@]}"` so macOS default Bash 3.2 does not fail with `unbound variable`.

---
