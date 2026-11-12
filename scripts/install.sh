#!/usr/bin/env bash
# ==============================================================================
# Antigravity Multi-Agent Rules & Playbook Installer
# Đồng bộ hệ thống quy tắc và playbook sang Antigravity trong 1 nốt nhạc.
# ==============================================================================

set -euo pipefail

# Màu hiển thị
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULES_SRC="${ROOT_DIR}/rules"
TARGET_DIR="${HOME}/.gemini/config/plugins/ag-kit/rules"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}🚀 ANTIGRAVITY WORKFLOW & RULES BOOTSTRAP${NC}"
echo -e "${BLUE}=================================================================${NC}"

# Kiểm tra thư mục nguồn
if [[ ! -d "${RULES_SRC}" ]]; then
    echo -e "${RED}❌ Lỗi: Không tìm thấy thư mục rules tại ${RULES_SRC}${NC}"
    exit 1
fi

MODE="symlink"
if [[ "${1:-}" == "--copy" || "${1:-}" == "-c" ]]; then
    MODE="copy"
fi

MODE_UPPER="$(echo "${MODE}" | tr '[:lower:]' '[:upper:]')"
echo -e "📂 Thư mục nguồn : ${YELLOW}${RULES_SRC}${NC}"
echo -e "🎯 Thư mục đích  : ${YELLOW}${TARGET_DIR}${NC}"
echo -e "⚙️  Chế độ cài đặt : ${GREEN}${MODE_UPPER}${NC}"

# Tạo thư mục đích nếu chưa tồn tại
mkdir -p "${TARGET_DIR}"

# Sao lưu nếu thư mục đích đã có file
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${HOME}/.gemini/config/plugins/ag-kit/rules.backup.${TIMESTAMP}"
HAS_EXISTING=0

for f in "${RULES_SRC}"/*.md; do
    fname="$(basename "$f")"
    if [[ -f "${TARGET_DIR}/${fname}" && ! -L "${TARGET_DIR}/${fname}" ]]; then
        HAS_EXISTING=1
        break
    fi
done

if [[ ${HAS_EXISTING} -eq 1 ]]; then
    echo -e "${YELLOW}📦 Phát hiện cấu hình cũ, đang tạo bản sao lưu tại:${NC} ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}"
    cp -r "${TARGET_DIR}"/* "${BACKUP_DIR}/" 2>/dev/null || true
fi

# Cài đặt từng file quy tắc
echo -e "\n${BLUE}⏳ Đang đồng bộ các quy tắc...${NC}"
COUNT=0

for src_file in "${RULES_SRC}"/*.md; do
    filename="$(basename "${src_file}")"
    dest_file="${TARGET_DIR}/${filename}"

    # Xóa file hoặc symlink cũ nếu có
    if [[ -e "${dest_file}" || -L "${dest_file}" ]]; then
        rm -f "${dest_file}"
    fi

    if [[ "${MODE}" == "symlink" ]]; then
        ln -s "${src_file}" "${dest_file}"
        echo -e "  🔗 Linked : ${GREEN}${filename}${NC} -> ${src_file}"
    else
        cp "${src_file}" "${dest_file}"
        echo -e "  📄 Copied : ${GREEN}${filename}${NC}"
    fi
    COUNT=$((COUNT + 1))
done

echo -e "\n${GREEN}=================================================================${NC}"
echo -e "${GREEN}✅ ĐỒNG BỘ THÀNH CÔNG ${COUNT} QUY TẮC CỐT LÕI!${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo -e "💡 Giờ đây mọi phiên làm việc mới trên Antigravity sẽ tự động áp dụng"
echo -e "   bộ quy tắc: Planning Gate, Core Protocol & Request Routing."
