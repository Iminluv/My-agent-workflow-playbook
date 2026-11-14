#!/usr/bin/env bash
# ==============================================================================
# Script: scaffold.sh
# Mô tả: Tự động khởi tạo cấu trúc .agents/ (knowledge & workflows) chuẩn
#        Enterprise Multi-Agent cho bất kỳ repository nào.
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCAFFOLD_SRC="${REPO_ROOT}/templates/agents_scaffold/.agents"

TARGET_DIR="${1:-.}"

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}🏗️  KHỞI TẠO CẤU TRÚC .AGENTS/ ENTERPRISE KNOWLEDGE & WORKFLOWS${NC}"
echo -e "${BLUE}=================================================================${NC}"

if [[ ! -d "${TARGET_DIR}" ]]; then
    echo -e "${YELLOW}📁 Thư mục đích chưa tồn tại, đang tạo: ${TARGET_DIR}${NC}"
    mkdir -p "${TARGET_DIR}"
fi

TARGET_AGENTS="${TARGET_DIR}/.agents"

echo -e "Target repository: ${GREEN}${TARGET_DIR}${NC}"
echo -e "Tạo cấu trúc thư mục tại: ${YELLOW}${TARGET_AGENTS}${NC}"

mkdir -p "${TARGET_AGENTS}/knowledge"
mkdir -p "${TARGET_AGENTS}/workflows"

if [[ -d "${SCAFFOLD_SRC}" ]]; then
    echo -e "Sao chép template từ: ${SCAFFOLD_SRC}"
    cp -rn "${SCAFFOLD_SRC}/" "${TARGET_AGENTS}/" 2>/dev/null || cp -r "${SCAFFOLD_SRC}/"* "${TARGET_AGENTS}/"
fi

echo -e "${GREEN}✓ Hoàn tất khởi tạo cấu trúc .agents/!${NC}"
echo -e "Cây thư mục đã tạo:"
find "${TARGET_AGENTS}" -maxdepth 3 -print | sed -e "s;${TARGET_DIR};.;g"
echo -e "${BLUE}=================================================================${NC}"
