#!/usr/bin/env bash
# ==============================================================================
# Antigravity Rules & Agents Verification Script (Enterprise v2.0)
# Validates integrity and completeness of all governance rules and specialist agents.
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_RULES_DIR="${HOME}/.gemini/config/plugins/ag-kit/rules"
TARGET_AGENTS_DIR="${HOME}/.gemini/config/plugins/ag-kit/agents"

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

REQUIRED_AGENTS=(
    "orchestrator.md"
    "backend-specialist.md"
    "devops-engineer.md"
)

ERRORS=0

verify_list() {
    local target_dir="$1"
    local label="$2"
    shift 2
    local items=("$@")

    echo -e "\n📂 Checking: ${YELLOW}${label}${NC} (${target_dir})"
    printf "%-25s | %-10s | %-10s | %s\n" "File Name" "Type" "Size" "Status"
    echo "--------------------------------------------------------------------------------"

    for item in "${items[@]}"; do
        local target_file="${target_dir}/${item}"
        if [[ ! -e "${target_file}" && ! -L "${target_file}" ]]; then
            printf "%-25s | %-10s | %-10s | ${RED}MISSING${NC}\n" "${item}" "---" "---"
            ERRORS=$((ERRORS + 1))
            continue
        fi

        local type="File"
        [[ -L "${target_file}" ]] && type="Symlink"
        local size="$(wc -c < "${target_file}" | tr -d ' ')"

        if [[ ${size} -lt 50 ]]; then
            printf "%-25s | %-10s | %-10s | ${YELLOW}EMPTY/TOO SHORT${NC}\n" "${item}" "${type}" "${size}B"
            ERRORS=$((ERRORS + 1))
        else
            printf "%-25s | %-10s | %-10s | ${GREEN}VALID (OK)${NC}\n" "${item}" "${type}" "${size}B"
        fi
    done
}

verify_list "${TARGET_RULES_DIR}" "Governance Rules (P0/P1)" "${REQUIRED_RULES[@]}"
verify_list "${TARGET_AGENTS_DIR}" "Specialist Agents" "${REQUIRED_AGENTS[@]}"

echo "--------------------------------------------------------------------------------"
if [[ ${ERRORS} -eq 0 ]]; then
    echo -e "${GREEN}🎉 100% OF ENTERPRISE RULES AND AGENTS ARE VERIFIED AND READY!${NC}"
else
    echo -e "${RED}⚠️  Detected ${ERRORS} issue(s). Please run ./scripts/install.sh to resynchronize.${NC}"
    exit 1
fi
