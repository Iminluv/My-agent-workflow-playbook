#!/usr/bin/env bash
# ==============================================================================
# Antigravity Multi-Agent Rules & Agents Installer (Enterprise v2.0)
# Đồng bộ hệ thống quy tắc, tác tử chuyên môn và templates sang Antigravity.
# ==============================================================================

set -euo pipefail

# Màu hiển thị
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULES_SRC="${ROOT_DIR}/rules"
AGENTS_SRC="${ROOT_DIR}/agents"
TARGET_RULES_DIR="${HOME}/.gemini/config/plugins/ag-kit/rules"
TARGET_AGENTS_DIR="${HOME}/.gemini/config/plugins/ag-kit/agents"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}🚀 ANTIGRAVITY ENTERPRISE WORKFLOW BOOTSTRAP (v2.0)${NC}"
echo -e "${BLUE}=================================================================${NC}"

MODE="symlink"
if [[ "${1:-}" == "--copy" || "${1:-}" == "-c" ]]; then
    MODE="copy"
fi

MODE_UPPER="$(echo "${MODE}" | tr '[:lower:]' '[:upper:]')"
echo -e "⚙️  Chế độ cài đặt : ${GREEN}${MODE_UPPER}${NC}"

# Hàm đồng bộ một thư mục nguồn sang thư mục đích
sync_folder() {
    local src_dir="$1"
    local dest_dir="$2"
    local label="$3"

    if [[ ! -d "${src_dir}" ]]; then
        echo -e "${YELLOW}⚠️  Bỏ qua ${label}: Thư mục ${src_dir} không tồn tại.${NC}"
        return 0
    fi

    mkdir -p "${dest_dir}"
    echo -e "\n${BLUE}⏳ Đang đồng bộ ${label}...${NC}"
    local count=0

    for src_file in "${src_dir}"/*.md; do
        [[ -e "$src_file" ]] || continue
        local filename="$(basename "${src_file}")"
        local dest_file="${dest_dir}/${filename}"

        if [[ -e "${dest_file}" || -L "${dest_file}" ]]; then
            rm -f "${dest_file}"
        fi

        if [[ "${MODE}" == "symlink" ]]; then
            ln -s "${src_file}" "${dest_file}"
            echo -e "  🔗 Linked : ${GREEN}${filename}${NC}"
        else
            cp "${src_file}" "${dest_file}"
            echo -e "  📄 Copied : ${GREEN}${filename}${NC}"
        fi
        count=$((count + 1))
    done
    echo -e "  ✨ Đã đồng bộ ${GREEN}${count}${NC} files ${label}."
}

# Thực hiện đồng bộ Rules và Agents
sync_folder "${RULES_SRC}" "${TARGET_RULES_DIR}" "Rules (Quy tắc P0/P1)"
sync_folder "${AGENTS_SRC}" "${TARGET_AGENTS_DIR}" "Agents (Tác tử chuyên môn)"

echo -e "\n${GREEN}=================================================================${NC}"
echo -e "${GREEN}🎉 NÂNG CẤP HỆ THỐNG QUẢN TRỊ ĐA TÁC TỬ V2.0 THÀNH CÔNG!${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo -e "💡 Hệ thống đã kích hoạt: Git Branch Safety (P0), Planning Gate v2,"
echo -e "   Delegation Contract, và Impact Analysis Protocol."
