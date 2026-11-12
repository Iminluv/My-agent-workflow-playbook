#!/usr/bin/env bash
# ==============================================================================
# Antigravity Rules Verification Script
# Kiểm tra tính toàn vẹn và hợp lệ của các quy tắc đã được đồng bộ.
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${HOME}/.gemini/config/plugins/ag-kit/rules"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}🔍 KIỂM TRA TRẠNG THÁI QUY TẮC ANTIGRAVITY${NC}"
echo -e "${BLUE}=================================================================${NC}"

if [[ ! -d "${TARGET_DIR}" ]]; then
    echo -e "${RED}❌ Thư mục cấu hình không tồn tại: ${TARGET_DIR}${NC}"
    echo -e "👉 Hãy chạy ./scripts/install.sh trước."
    exit 1
fi

REQUIRED_RULES=(
    "GEMINI.md"
    "core-protocol.md"
    "planning-gate.md"
    "request-routing.md"
    "universal-rules.md"
    "code-rules.md"
    "design-rules.md"
    "quick-reference.md"
)

ERRORS=0
echo -e "Thư mục kiểm tra: ${YELLOW}${TARGET_DIR}${NC}\n"
printf "%-25s | %-12s | %-10s | %s\n" "File Quy Tắc" "Loại" "Kích Thước" "Trạng Thái"
echo "--------------------------------------------------------------------------------"

for rule in "${REQUIRED_RULES[@]}"; do
    target_file="${TARGET_DIR}/${rule}"
    if [[ ! -e "${target_file}" && ! -L "${target_file}" ]]; then
        printf "%-25s | %-12s | %-10s | ${RED}THIẾU (Missing)${NC}\n" "${rule}" "---" "---"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    TYPE="File"
    if [[ -L "${target_file}" ]]; then
        TYPE="Symlink"
    fi

    SIZE="$(wc -c < "${target_file}" | tr -d ' ')"
    if [[ ${SIZE} -lt 50 ]]; then
        printf "%-25s | %-12s | %-10s | ${YELLOW}RỖNG / QUÁ NGẮN${NC}\n" "${rule}" "${TYPE}" "${SIZE}B"
        ERRORS=$((ERRORS + 1))
    else
        printf "%-25s | %-12s | %-10s | ${GREEN}HỢP LỆ (OK)${NC}\n" "${rule}" "${TYPE}" "${SIZE}B"
    fi
done

echo "--------------------------------------------------------------------------------"
if [[ ${ERRORS} -eq 0 ]]; then
    echo -e "${GREEN}🎉 TẤT CẢ QUY TẮC ĐÃ ĐƯỢC CÀI ĐẶT CHUẨN XÁC VÀ SẴN SÀNG HOẠT ĐỘNG!${NC}"
else
    echo -e "${RED}⚠️  Phát hiện ${ERRORS} lỗi. Vui lòng chạy lại ./scripts/install.sh${NC}"
    exit 1
fi
