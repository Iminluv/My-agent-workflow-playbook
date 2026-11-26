#!/usr/bin/env bash
# ==============================================================================
# Antigravity Rules & Agents Verification Script (Enterprise v2.0)
# Validates integrity and completeness of governance rules, all 20 specialist
# agents, Antigravity native tool declarations, and YAML frontmatter.
# ==============================================================================

set -euo pipefail

# Display Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_PLUGIN_DIR="${TARGET_PLUGIN_DIR:-${HOME}/.gemini/config/plugins/ag-kit}"
REPO_RULES_DIR="${REPO_RULES_DIR:-${ROOT_DIR}/rules}"
REPO_AGENTS_DIR="${REPO_AGENTS_DIR:-${ROOT_DIR}/agents}"
REPO_HOOKS_DIR="${REPO_HOOKS_DIR:-${ROOT_DIR}/hooks}"
REPO_HOOKS_CONFIG="${REPO_HOOKS_CONFIG:-${ROOT_DIR}/hooks.json}"
REPO_SCRIPTS_DIR="${REPO_SCRIPTS_DIR:-${ROOT_DIR}/scripts}"
TARGET_RULES_DIR="${TARGET_RULES_DIR:-${TARGET_PLUGIN_DIR}/rules}"
TARGET_AGENTS_DIR="${TARGET_AGENTS_DIR:-${TARGET_PLUGIN_DIR}/agents}"
TARGET_HOOKS_DIR="${TARGET_HOOKS_DIR:-${TARGET_PLUGIN_DIR}/hooks}"
TARGET_HOOKS_CONFIG="${TARGET_HOOKS_CONFIG:-${TARGET_PLUGIN_DIR}/hooks.json}"
TARGET_SCRIPTS_DIR="${TARGET_SCRIPTS_DIR:-${TARGET_PLUGIN_DIR}/scripts}"

CHECK_MODE="all" # Options: all, repo, target

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Validates the integrity, frontmatter, hooks, scripts, and tool declarations of Antigravity rules and agents.

Options:
  -a, --all        Verify both repository source files and installed plugins (default).
  -r, --repo       Verify only repository source files (rules/*.md, agents/*.md, hooks/*, hooks.json, scripts/*).
  -t, --target     Verify only installed plugin configuration files.
  -h, --help       Show this help message and exit.

Environment Variables:
  TARGET_PLUGIN_DIR    Base installed plugin directory (default: ~/.gemini/config/plugins/ag-kit)
  TARGET_RULES_DIR     Target rules directory (default: \$TARGET_PLUGIN_DIR/rules)
  TARGET_AGENTS_DIR    Target agents directory (default: \$TARGET_PLUGIN_DIR/agents)
  TARGET_HOOKS_DIR     Target hooks directory (default: \$TARGET_PLUGIN_DIR/hooks)
  TARGET_HOOKS_CONFIG  Target hooks.json file (default: \$TARGET_PLUGIN_DIR/hooks.json)
  TARGET_SCRIPTS_DIR   Target scripts directory (default: \$TARGET_PLUGIN_DIR/scripts)

EOF
}

# Parse Command-Line Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            CHECK_MODE="all"
            shift
            ;;
        -r|--repo)
            CHECK_MODE="repo"
            shift
            ;;
        -t|--target)
            CHECK_MODE="target"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown argument '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}🔍 VERIFYING ANTIGRAVITY ENTERPRISE GOVERNANCE (v2.0)${NC}"
echo -e "${BLUE}=================================================================${NC}"

REQUIRED_RULES=(
    "GEMINI.md"
    "core-protocol.md"
    "planning-gate.md"
    "git-safety.md"
    "delegation-contract.md"
    "impact-analysis.md"
    "request-routing.md"
    "universal-rules.md"
    "code-rules.md"
    "design-rules.md"
    "quick-reference.md"
)

# Complete roster of all 20 Enterprise agents
REQUIRED_AGENTS=(
    "backend-specialist.md"
    "code-archaeologist.md"
    "database-architect.md"
    "debugger.md"
    "devops-engineer.md"
    "documentation-writer.md"
    "explorer-agent.md"
    "frontend-specialist.md"
    "game-developer.md"
    "mobile-developer.md"
    "orchestrator.md"
    "penetration-tester.md"
    "performance-optimizer.md"
    "product-manager.md"
    "product-owner.md"
    "project-planner.md"
    "qa-automation-engineer.md"
    "security-auditor.md"
    "seo-specialist.md"
    "test-engineer.md"
)

# Standard Antigravity native tool suite
REQUIRED_NATIVE_TOOLS=(
    "read_file"
    "edit_file"
    "write_file"
    "run_command"
    "manage_task"
    "search_web"
)

REQUIRED_HOOKS=(
    "circuit-breaker.mjs"
    "validate-tool-call.mjs"
)

REQUIRED_SCRIPTS=(
    "verify-deliverable.sh"
)

ERRORS=0

# ==============================================================================
# Helper: Verify File Existence and Minimal Size
# ==============================================================================
verify_list() {
    local target_dir="$1"
    local label="$2"
    shift 2
    local items=("$@")

    echo -e "\n📂 Checking: ${YELLOW}${label}${NC} (${target_dir})"
    printf "%-26s | %-10s | %-10s | %s\n" "File Name" "Type" "Size" "Status"
    echo "--------------------------------------------------------------------------------"

    if [[ ! -d "${target_dir}" ]]; then
        echo -e "${RED}❌ Directory not found: ${target_dir}${NC}"
        ERRORS=$((ERRORS + ${#items[@]}))
        return 1
    fi

    for item in "${items[@]}"; do
        local target_file="${target_dir}/${item}"
        if [[ -L "${target_file}" && ! -e "${target_file}" ]]; then
            printf "%-26s | %-10s | %-10s | ${RED}BROKEN SYMLINK${NC}\n" "${item}" "Symlink" "---"
            ERRORS=$((ERRORS + 1))
            continue
        fi
        if [[ ! -e "${target_file}" ]]; then
            printf "%-26s | %-10s | %-10s | ${RED}MISSING${NC}\n" "${item}" "---" "---"
            ERRORS=$((ERRORS + 1))
            continue
        fi

        local type="File"
        [[ -L "${target_file}" ]] && type="Symlink"
        local size
        size="$(wc -c < "${target_file}" | tr -d ' ')"

        if [[ ${size} -lt 50 ]]; then
            printf "%-26s | %-10s | %-10s | ${YELLOW}EMPTY/TOO SHORT${NC}\n" "${item}" "${type}" "${size}B"
            ERRORS=$((ERRORS + 1))
        else
            printf "%-26s | %-10s | %-10s | ${GREEN}VALID (OK)${NC}\n" "${item}" "${type}" "${size}B"
        fi
    done
}

# ==============================================================================
# Helper: Verify Hooks Syntax & Executable Permissions
# ==============================================================================
verify_hooks_runtime() {
    local hooks_dir="$1"
    local label="$2"
    shift 2
    local items=("$@")

    echo -e "\n🪝 Validating Hooks Syntax & Permissions: ${YELLOW}${label}${NC}"
    printf "%-26s | %-10s | %-12s | %s\n" "Hook File" "Exec Bit" "Node Check" "Status"
    echo "--------------------------------------------------------------------------------"

    if [[ ! -d "${hooks_dir}" ]]; then
        echo -e "${RED}❌ Directory not found: ${hooks_dir}${NC}"
        ERRORS=$((ERRORS + ${#items[@]}))
        return 1
    fi

    for item in "${items[@]}"; do
        local hook_file="${hooks_dir}/${item}"
        if [[ ! -f "${hook_file}" ]]; then
            printf "%-26s | %-10s | %-12s | ${RED}MISSING${NC}\n" "${item}" "---" "---"
            ERRORS=$((ERRORS + 1))
            continue
        fi

        local exec_status="${GREEN}OK${NC}"
        local syntax_status="${GREEN}OK${NC}"
        local has_err=false

        if [[ ! -x "${hook_file}" ]]; then
            exec_status="${RED}NOT +x${NC}"
            has_err=true
        fi

        if command -v node >/dev/null 2>&1; then
            if ! node --check "${hook_file}" >/dev/null 2>&1; then
                syntax_status="${RED}SYNTAX ERR${NC}"
                has_err=true
            fi
        else
            syntax_status="${YELLOW}SKIPPED${NC}"
        fi

        if [[ "${has_err}" == "true" ]]; then
            printf "%-26s | %-10b | %-12b | ${RED}INVALID${NC}\n" "${item}" "${exec_status}" "${syntax_status}"
            ERRORS=$((ERRORS + 1))
        else
            printf "%-26s | %-10b | %-12b | ${GREEN}VALID (OK)${NC}\n" "${item}" "${exec_status}" "${syntax_status}"
        fi
    done
}

# ==============================================================================
# Helper: Verify hooks.json Structure & Valid JSON
# ==============================================================================
verify_hooks_config() {
    local config_path="$1"
    local label="$2"

    echo -e "\n⚙️  Validating Hooks Configuration: ${YELLOW}${label}${NC} (${config_path})"
    echo "--------------------------------------------------------------------------------"

    if [[ -L "${config_path}" && ! -e "${config_path}" ]]; then
        echo -e "  ${RED}❌ BROKEN SYMLINK: ${config_path}${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
    if [[ ! -f "${config_path}" ]]; then
        echo -e "  ${RED}❌ MISSING: ${config_path}${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    local size
    size="$(wc -c < "${config_path}" | tr -d ' ')"
    if [[ ${size} -lt 20 ]]; then
        echo -e "  ${RED}❌ EMPTY/TOO SHORT (${size}B): ${config_path}${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    if command -v node >/dev/null 2>&1; then
        if node --input-type=module -e '
            import fs from "node:fs";
            const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
            if (!data || typeof data !== "object" || Array.isArray(data)) {
                throw new Error("hooks.json root must be an object");
            }
            const serialized = JSON.stringify(data);
            if (!serialized.includes("./hooks/validate-tool-call.mjs") || !serialized.includes("./hooks/circuit-breaker.mjs")) {
                throw new Error("hooks.json missing expected hook commands");
            }
        ' "${config_path}" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ VALID JSON & HOOK REFERENCES OK (${size}B)${NC}"
        else
            echo -e "  ${RED}❌ INVALID hooks.json (JSON syntax or missing hook references)${NC}"
            ERRORS=$((ERRORS + 1))
            return 1
        fi
    elif command -v python3 >/dev/null 2>&1; then
        if python3 -m json.tool "${config_path}" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ VALID JSON (${size}B)${NC}"
        else
            echo -e "  ${RED}❌ INVALID JSON in ${config_path}${NC}"
            ERRORS=$((ERRORS + 1))
            return 1
        fi
    else
        echo -e "  ${RED}❌ Neither node nor python3 found to validate JSON${NC}"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# ==============================================================================
# Helper: Verify Deliverable & Utility Scripts Syntax & Permissions
# ==============================================================================
verify_scripts_runtime() {
    local scripts_dir="$1"
    local label="$2"
    shift 2
    local items=("$@")

    echo -e "\n📜 Validating Scripts Syntax & Permissions: ${YELLOW}${label}${NC}"
    printf "%-26s | %-10s | %-12s | %s\n" "Script File" "Exec Bit" "Bash Check" "Status"
    echo "--------------------------------------------------------------------------------"

    if [[ ! -d "${scripts_dir}" ]]; then
        echo -e "${RED}❌ Directory not found: ${scripts_dir}${NC}"
        ERRORS=$((ERRORS + ${#items[@]}))
        return 1
    fi

    for item in "${items[@]}"; do
        local script_file="${scripts_dir}/${item}"
        if [[ ! -f "${script_file}" ]]; then
            printf "%-26s | %-10s | %-12s | ${RED}MISSING${NC}\n" "${item}" "---" "---"
            ERRORS=$((ERRORS + 1))
            continue
        fi

        local exec_status="${GREEN}OK${NC}"
        local bash_status="${GREEN}OK${NC}"
        local has_err=false

        if [[ ! -x "${script_file}" ]]; then
            exec_status="${RED}NOT +x${NC}"
            has_err=true
        fi

        if ! bash -n "${script_file}" >/dev/null 2>&1; then
            bash_status="${RED}SYNTAX ERR${NC}"
            has_err=true
        fi

        if [[ "${has_err}" == "true" ]]; then
            printf "%-26s | %-10b | %-12b | ${RED}INVALID${NC}\n" "${item}" "${exec_status}" "${bash_status}"
            ERRORS=$((ERRORS + 1))
        else
            printf "%-26s | %-10b | %-12b | ${GREEN}VALID (OK)${NC}\n" "${item}" "${exec_status}" "${bash_status}"
        fi
    done
}

# ==============================================================================
# Helper: Dedicated Agent Frontmatter & Tool Declarations Validation
# ==============================================================================
verify_agents_frontmatter() {
    local agents_dir="$1"
    local label="$2"
    shift 2
    local items=("$@")

    echo -e "\n🔬 Validating Agent Frontmatter & Native Tool Declarations: ${YELLOW}${label}${NC}"
    printf "%-26s | %-11s | %-12s | %-12s | %s\n" "Agent Name" "Role" "Legacy Tools" "Native Tools" "Status"
    echo "--------------------------------------------------------------------------------"

    if [[ ! -d "${agents_dir}" ]]; then
        echo -e "${RED}❌ Directory not found: ${agents_dir}${NC}"
        ERRORS=$((ERRORS + ${#items[@]}))
        return 1
    fi

    for item in "${items[@]}"; do
        local agent_file="${agents_dir}/${item}"
        if [[ ! -f "${agent_file}" ]]; then
            printf "%-26s | %-11s | %-12s | %-12s | ${RED}FILE NOT FOUND${NC}\n" "${item}" "---" "---" "---"
            ERRORS=$((ERRORS + 1))
            continue
        fi

        # Check YAML opening delimiter
        local has_opening_delimiter
        has_opening_delimiter="$(head -n 1 "${agent_file}")"
        if [[ "${has_opening_delimiter}" != "---" ]]; then
            printf "%-26s | %-11s | %-12s | %-12s | ${RED}NO FRONTMATTER${NC}\n" "${item}" "---" "---" "---"
            ERRORS=$((ERRORS + 1))
            continue
        fi

        # Extract frontmatter between opening and closing ---
        local frontmatter
        frontmatter="$(awk 'NR==1 && /^---$/ {in_fm=1; next} in_fm && /^---$/ {exit} in_fm {print}' "${agent_file}")"
        if [[ -z "${frontmatter}" ]]; then
            printf "%-26s | %-11s | %-12s | %-12s | ${RED}EMPTY FRONTMATTER${NC}\n" "${item}" "---" "---" "---"
            ERRORS=$((ERRORS + 1))
            continue
        fi

        # 1. Check for legacy Claude tool names (Read, Grep, Glob, Bash, Edit, Write)
        local legacy_tools
        legacy_tools="$(printf "%s\n" "${frontmatter}" | grep -E "^\s*-\s*(Read|Grep|Glob|Bash|Edit|Write)$" || true)"

        # 2. Extract tools declared in frontmatter tools list
        local tools_list
        tools_list="$(printf "%s\n" "${frontmatter}" | awk '
            /^tools:/ {in_tools=1; next}
            in_tools && /^[a-zA-Z]/ {in_tools=0}
            in_tools && /^  - / {gsub(/^[ \t]*-[ \t]*/, ""); print}
        ')"

        # Check that all required Antigravity native tools are declared
        local missing_native=()
        for native_tool in "${REQUIRED_NATIVE_TOOLS[@]}"; do
            if ! printf "%s\n" "${tools_list}" | grep -qx "${native_tool}"; then
                missing_native+=("${native_tool}")
            fi
        done

        # Check for unknown / invalid tools
        local invalid_tools=()
        for declared_tool in ${tools_list}; do
            case "${declared_tool}" in
                read_file|edit_file|write_file|run_command|manage_task|search_web)
                    ;;
                *)
                    invalid_tools+=("${declared_tool}")
                    ;;
            esac
        done

        # 3. Check subagent and mainAgent flags
        local subagent_val
        local mainagent_val
        subagent_val="$(printf "%s\n" "${frontmatter}" | awk -F': *' '/^subagent:/{print $2}' | tr -d ' \r\t')"
        mainagent_val="$(printf "%s\n" "${frontmatter}" | awk -F': *' '/^mainAgent:/{print $2}' | tr -d ' \r\t')"

        local role="Subagent"
        local role_valid=true
        if [[ "${item}" == "orchestrator.md" ]]; then
            role="Coordinator"
            if [[ "${subagent_val}" != "false" || "${mainagent_val}" != "true" ]]; then
                role_valid=false
            fi
        else
            if [[ "${subagent_val}" != "true" || "${mainagent_val}" != "false" ]]; then
                role_valid=false
            fi
        fi

        # Evaluation & Reporting
        local file_has_error=false
        local legacy_status="0 (OK)"
        local native_status="${#REQUIRED_NATIVE_TOOLS[@]} (OK)"
        local status_msg="${GREEN}VALID (OK)${NC}"

        if [[ -n "${legacy_tools}" ]]; then
            local count_legacy
            count_legacy="$(printf "%s\n" "${legacy_tools}" | wc -l | tr -d ' ')"
            legacy_status="${RED}${count_legacy} LEGACY${NC}"
            file_has_error=true
        fi

        if [[ ${#missing_native[@]} -gt 0 || ${#invalid_tools[@]} -gt 0 ]]; then
            native_status="${RED}MISSING/BAD${NC}"
            file_has_error=true
        fi

        if [[ "${role_valid}" != "true" ]]; then
            file_has_error=true
        fi

        if [[ "${file_has_error}" == "true" ]]; then
            status_msg="${RED}INVALID${NC}"
            ERRORS=$((ERRORS + 1))
        fi

        printf "%-26s | %-11s | %-12b | %-12b | %b\n" "${item}" "${role}" "${legacy_status}" "${native_status}" "${status_msg}"

        # Print detailed diagnostics if errors detected
        if [[ -n "${legacy_tools}" ]]; then
            local formatted_legacy
            formatted_legacy="$(printf "%s\n" "${legacy_tools}" | tr -d ' ' | tr '\n' ' ')"
            echo -e "   ${RED}↳ Legacy Claude tool(s) detected: ${formatted_legacy}${NC}"
        fi
        if [[ ${#missing_native[@]} -gt 0 ]]; then
            echo -e "   ${RED}↳ Missing native tool(s): ${missing_native[*]}${NC}"
        fi
        if [[ ${#invalid_tools[@]} -gt 0 ]]; then
            echo -e "   ${RED}↳ Invalid tool(s): ${invalid_tools[*]}${NC}"
        fi
        if [[ "${role_valid}" != "true" ]]; then
            if [[ "${item}" == "orchestrator.md" ]]; then
                echo -e "   ${RED}↳ Role flag mismatch: expected subagent=false, mainAgent=true (got subagent='${subagent_val}', mainAgent='${mainagent_val}')${NC}"
            else
                echo -e "   ${RED}↳ Role flag mismatch: expected subagent=true, mainAgent=false (got subagent='${subagent_val}', mainAgent='${mainagent_val}')${NC}"
            fi
        fi
    done
}

# ==============================================================================
# Execution Flow
# ==============================================================================

# Section 1 & 2: Repository Source Files Verification
if [[ "${CHECK_MODE}" == "all" || "${CHECK_MODE}" == "repo" ]]; then
    verify_list "${REPO_RULES_DIR}" "Governance Rules (rules/*.md)" "${REQUIRED_RULES[@]}"
    verify_list "${REPO_AGENTS_DIR}" "Specialist Agents (agents/*.md)" "${REQUIRED_AGENTS[@]}"
    verify_agents_frontmatter "${REPO_AGENTS_DIR}" "Repository Agents (agents/*.md)" "${REQUIRED_AGENTS[@]}"
    verify_list "${REPO_HOOKS_DIR}" "Repository Hooks (hooks/*.mjs)" "${REQUIRED_HOOKS[@]}"
    verify_hooks_runtime "${REPO_HOOKS_DIR}" "Repository Hooks Syntax & Permissions" "${REQUIRED_HOOKS[@]}"
    verify_hooks_config "${REPO_HOOKS_CONFIG}" "Repository Hooks Config (hooks.json)"
    verify_list "${REPO_SCRIPTS_DIR}" "Repository Scripts (scripts/*.sh)" "${REQUIRED_SCRIPTS[@]}"
    verify_scripts_runtime "${REPO_SCRIPTS_DIR}" "Repository Scripts Syntax & Permissions" "${REQUIRED_SCRIPTS[@]}"
fi

# Section 3: Installed Target Plugins Verification
if [[ "${CHECK_MODE}" == "all" || "${CHECK_MODE}" == "target" ]]; then
    if [[ -d "${TARGET_RULES_DIR}" || -d "${TARGET_AGENTS_DIR}" || -d "${TARGET_HOOKS_DIR}" || -e "${TARGET_HOOKS_CONFIG}" || -L "${TARGET_HOOKS_CONFIG}" || -d "${TARGET_SCRIPTS_DIR}" || "${CHECK_MODE}" == "target" ]]; then
        verify_list "${TARGET_RULES_DIR}" "Installed Governance Rules (P0/P1)" "${REQUIRED_RULES[@]}"
        verify_list "${TARGET_AGENTS_DIR}" "Installed Specialist Agents" "${REQUIRED_AGENTS[@]}"
        verify_list "${TARGET_HOOKS_DIR}" "Installed Hooks (hooks/*.mjs)" "${REQUIRED_HOOKS[@]}"
        verify_hooks_runtime "${TARGET_HOOKS_DIR}" "Installed Hooks Syntax & Permissions" "${REQUIRED_HOOKS[@]}"
        verify_hooks_config "${TARGET_HOOKS_CONFIG}" "Installed Hooks Config (hooks.json)"
        verify_list "${TARGET_SCRIPTS_DIR}" "Installed Scripts (scripts/*.sh)" "${REQUIRED_SCRIPTS[@]}"
        verify_scripts_runtime "${TARGET_SCRIPTS_DIR}" "Installed Scripts Syntax & Permissions" "${REQUIRED_SCRIPTS[@]}"
    fi
fi

echo "--------------------------------------------------------------------------------"
if [[ ${ERRORS} -eq 0 ]]; then
    echo -e "${GREEN}🎉 100% OF ENTERPRISE RULES, AGENTS, HOOKS, AND SCRIPTS ARE VERIFIED AND READY!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Detected ${ERRORS} issue(s). Please run ./scripts/install.sh to resynchronize.${NC}"
    exit 1
fi
