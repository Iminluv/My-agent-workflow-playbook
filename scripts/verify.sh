#!/usr/bin/env bash
# ==============================================================================
# Antigravity Rules & Agents Verification Script (Enterprise v2.0)
# Kiểm tra tính toàn vẹn và hợp lệ của toàn bộ hệ thống quy tắc và tác tử.
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
echo -e "${BLUE}🔍 KIỂM TRA TRẠNG THÁI QUẢN TRỊ ENTERPRISE ANTIGRAVITY (v2.0)${NC}"
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

    echo -e "\n📂 Kiểm tra: ${YELLOW}${label}${NC} (${target_dir})"
    printf "%-25s | %-10s | %-10s | %s\n" "Tên File" "Loại" "Kích Thước" "Trạng Thái"
    echo "--------------------------------------------------------------------------------"

    for item in "${items[@]}"; do
        local target_file="${target_dir}/${item}"
        if [[ ! -e "${target_file}" && ! -L "${target_file}" ]]; then
            printf "%-25s | %-10s | %-10s | ${RED}THIẾU (Missing)${NC}\n" "${item}" "---" "---"
            ERRORS=$((ERRORS + 1))
            continue
        fi

        local type="File"
        [[ -L "${target_file}" ]] && type="Symlink"
        local size="$(wc -c < "${target_file}" | tr -d ' ')"

        if [[ ${size} -lt 50 ]]; then
            printf "%-25s | %-10s | %-10s | ${YELLOW}RỖNG/QUÁ NGẮN${NC}\n" "${item}" "${type}" "${size}B"
            ERRORS=$((ERRORS + 1))
        else
            printf "%-25s | %-10s | %-10s | ${GREEN}HỢP LỆ (OK)${NC}\n" "${item}" "${type}" "${size}B"
        fi
    done
}

verify_list "${TARGET_RULES_DIR}" "Rules Quy Tắc P0/P1" "${REQUIRED_RULES[@]}"
verify_list "${TARGET_AGENTS_DIR}" "Agents Tác Tử Chuyên Môn" "${REQUIRED_AGENTS[@]}"

echo "--------------------------------------------------------------------------------"
if [[ ${ERRORS} -eq 0 ]]; then
    echo -e "${GREEN}🎉 100% QUY TẮC VÀ TÁC TỬ ENTERPRISE SẴN SÀNG HOẠT ĐỘNG!${NC}"
else
    echo -e "${RED}⚠️  Phát hiện ${ERRORS} lỗi. Vui lòng chạy ./scripts/install.sh để đồng bộ lại.${NC}"
    exit 1
fi
