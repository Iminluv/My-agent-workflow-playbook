#!/usr/bin/env bash
# ==============================================================================
# Script: scaffold.sh
# Mô tả: Tự động khởi tạo cấu trúc .agents/ (knowledge & workflows) chuẩn
#        Enterprise Multi-Agent cho bất kỳ repository nào với tính năng
#        Auto-Detection tech stack và token replacement tương thích đa nền tảng.
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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
    cp -rn "${SCAFFOLD_SRC}/" "${TARGET_AGENTS}/" 2>/dev/null || cp -r "${SCAFFOLD_SRC}/"* "${TARGET_AGENTS}/" 2>/dev/null || cp -R "${SCAFFOLD_SRC}/." "${TARGET_AGENTS}/"
fi

# ------------------------------------------------------------------------------
# Auto-detection & Helper Utilities
# ------------------------------------------------------------------------------

# Helper: Append item to a slash-separated list preventing duplicates
append_item() {
    local current="$1"
    local item="$2"
    if [[ -z "${current}" ]]; then
        echo "${item}"
    elif [[ " / ${current} / " == *" / ${item} / "* ]]; then
        echo "${current}"
    else
        echo "${current} / ${item}"
    fi
}

# Helper: Check if item exists in slash-separated list
has_item() {
    local haystack="$1"
    local needle="$2"
    [[ " / ${haystack} / " == *" / ${needle} / "* ]]
}

# Helper: Portable in-place token replacement using awk and atomic mv
replace_token_in_file() {
    local file="$1"
    local token="$2"
    local replacement="$3"

    if [[ ! -f "$file" ]]; then
        return 0
    fi

    local tmp_file
    tmp_file=$(mktemp "${file}.tmp.XXXXXX")

    TOKEN="$token" REPL="$replacement" awk '
    BEGIN {
        token = ENVIRON["TOKEN"]
        repl = ENVIRON["REPL"]
    }
    {
        while ((idx = index($0, token)) > 0) {
            $0 = substr($0, 1, idx - 1) repl substr($0, idx + length(token))
        }
        print
    }
    ' "$file" > "$tmp_file" && mv "$tmp_file" "$file"
}

# ------------------------------------------------------------------------------
# Ecosystem Scanning & Discovery
# ------------------------------------------------------------------------------

echo -e "\n${CYAN}🔍 Đang phân tích môi trường & tech stack của repository...${NC}"

TMP_FILE_LIST=$(mktemp "${TMPDIR:-/tmp}/scaffold_files.XXXXXX")
TMP_MANIFESTS=$(mktemp "${TMPDIR:-/tmp}/scaffold_manifests.XXXXXX")

# Ensure temporary files are always removed on exit
trap 'rm -f "${TMP_FILE_LIST:-}" "${TMP_MANIFESTS:-}"' EXIT

# 1. Index file paths up to depth 3 (pruning bulky non-source folders)
find "${TARGET_DIR}" -maxdepth 3 \
    \( -name ".git" -o -name "node_modules" -o -name ".agents" -o -name "target" -o -name "dist" -o -name "build" -o -name ".venv" -o -name "venv" -o -name "__pycache__" \) -prune -o \
    -print > "${TMP_FILE_LIST}" 2>/dev/null || true

# 2. Extract contents of manifests and config files
while IFS= read -r f; do
    if [[ -f "$f" ]]; then
        cat "$f" >> "${TMP_MANIFESTS}"
        echo "" >> "${TMP_MANIFESTS}"
    fi
done < <(grep -E '(package\.json|Cargo\.toml|pyproject\.toml|requirements.*\.txt|Pipfile|setup\.(py|cfg)|go\.mod|Dockerfile|compose.*\.ya?ml|\.config\.)' "${TMP_FILE_LIST}" 2>/dev/null || true)

matches_manifest() {
    local pattern="$1"
    grep -i -q -E "${pattern}" "${TMP_MANIFESTS}" 2>/dev/null
}

matches_file_list() {
    local pattern="$1"
    grep -i -q -E "${pattern}" "${TMP_FILE_LIST}" 2>/dev/null
}

# ------------------------------------------------------------------------------
# 1. Detect Project Name
# ------------------------------------------------------------------------------
PROJECT_NAME=""

# Priority 1: package.json (root or immediate subdirectories)
if [[ -f "${TARGET_DIR}/package.json" ]]; then
    PROJECT_NAME=$(grep -m 1 '"name"[[:space:]]*:' "${TARGET_DIR}/package.json" 2>/dev/null | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)
fi
if [[ -z "${PROJECT_NAME}" ]]; then
    pkg_file=$(grep -m 1 'package\.json$' "${TMP_FILE_LIST}" 2>/dev/null || true)
    if [[ -n "${pkg_file}" && -f "${pkg_file}" ]]; then
        PROJECT_NAME=$(grep -m 1 '"name"[[:space:]]*:' "${pkg_file}" 2>/dev/null | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)
    fi
fi

# Priority 2: Cargo.toml
if [[ -z "${PROJECT_NAME}" ]]; then
    if [[ -f "${TARGET_DIR}/Cargo.toml" ]]; then
        PROJECT_NAME=$(grep -m 1 '^[[:space:]]*name[[:space:]]*=' "${TARGET_DIR}/Cargo.toml" 2>/dev/null | sed -E 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/' || true)
    fi
    if [[ -z "${PROJECT_NAME}" ]]; then
        cargo_file=$(grep -m 1 'Cargo\.toml$' "${TMP_FILE_LIST}" 2>/dev/null || true)
        if [[ -n "${cargo_file}" && -f "${cargo_file}" ]]; then
            PROJECT_NAME=$(grep -m 1 '^[[:space:]]*name[[:space:]]*=' "${cargo_file}" 2>/dev/null | sed -E 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/' || true)
        fi
    fi
fi

# Priority 3: pyproject.toml
if [[ -z "${PROJECT_NAME}" ]]; then
    if [[ -f "${TARGET_DIR}/pyproject.toml" ]]; then
        PROJECT_NAME=$(grep -m 1 '^[[:space:]]*name[[:space:]]*=' "${TARGET_DIR}/pyproject.toml" 2>/dev/null | sed -E 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/' || true)
    fi
    if [[ -z "${PROJECT_NAME}" ]]; then
        py_file=$(grep -m 1 'pyproject\.toml$' "${TMP_FILE_LIST}" 2>/dev/null || true)
        if [[ -n "${py_file}" && -f "${py_file}" ]]; then
            PROJECT_NAME=$(grep -m 1 '^[[:space:]]*name[[:space:]]*=' "${py_file}" 2>/dev/null | sed -E 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/' || true)
        fi
    fi
fi

# Priority 4: go.mod
if [[ -z "${PROJECT_NAME}" ]]; then
    if [[ -f "${TARGET_DIR}/go.mod" ]]; then
        PROJECT_NAME=$(grep -m 1 '^[[:space:]]*module[[:space:]]' "${TARGET_DIR}/go.mod" 2>/dev/null | sed -E 's/^[[:space:]]*module[[:space:]]+([^[:space:]]+).*/\1/' || true)
    fi
    if [[ -z "${PROJECT_NAME}" ]]; then
        go_file=$(grep -m 1 'go\.mod$' "${TMP_FILE_LIST}" 2>/dev/null || true)
        if [[ -n "${go_file}" && -f "${go_file}" ]]; then
            PROJECT_NAME=$(grep -m 1 '^[[:space:]]*module[[:space:]]' "${go_file}" 2>/dev/null | sed -E 's/^[[:space:]]*module[[:space:]]+([^[:space:]]+).*/\1/' || true)
        fi
    fi
    if [[ -n "${PROJECT_NAME}" ]]; then
        PROJECT_NAME="${PROJECT_NAME##*/}"
    fi
fi

# Priority 5: Fallback to directory basename
if [[ -z "${PROJECT_NAME}" || "${PROJECT_NAME}" == "null" ]]; then
    abs_path=$(cd "${TARGET_DIR}" 2>/dev/null && pwd || echo "${TARGET_DIR}")
    PROJECT_NAME="$(basename "${abs_path}")"
fi
PROJECT_NAME="${PROJECT_NAME:-project}"

# ------------------------------------------------------------------------------
# 2. Detect Backend Stack (Node, Python, Rust, Go)
# ------------------------------------------------------------------------------
BACKEND_STR=""

# Node frameworks
if matches_manifest '("express"|express[[:space:]]*=)'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Express")
fi
if matches_manifest '("fastify"|fastify[[:space:]]*=)'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Fastify")
fi
if matches_manifest '("@nestjs/|nest\.js|"nest")'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "NestJS")
fi
if matches_manifest '("koa"|koa[[:space:]]*=)'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Koa")
fi
if matches_manifest '("hono"|hono[[:space:]]*=)'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Hono")
fi
if matches_manifest '("next"|next\.config)'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Next.js")
fi

# Python frameworks
if matches_manifest 'fastapi'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "FastAPI")
fi
if matches_manifest 'django'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Django")
fi
if matches_manifest 'flask'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Flask")
fi
if matches_manifest 'starlette'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Starlette")
fi
if matches_manifest 'tornado'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Tornado")
fi
if matches_manifest 'celery'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Celery")
fi

# Rust frameworks
if matches_manifest 'tokio'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Tokio")
fi
if matches_manifest 'axum'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Axum")
fi
if matches_manifest '(actix-web|actix)'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Actix-web")
fi
if matches_manifest 'rocket'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Rocket")
fi

# Go frameworks
if matches_manifest '(gin-gonic/gin|[^a-zA-Z]gin[^a-zA-Z])'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Gin")
fi
if matches_manifest '(gofiber/fiber|[^a-zA-Z]fiber[^a-zA-Z])'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Fiber")
fi
if matches_manifest 'labstack/echo'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Echo")
fi
if matches_manifest 'go-chi/chi'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Chi")
fi

# Runtimes: Python, Rust, Go
if matches_file_list '(pyproject\.toml|requirements.*\.txt|Pipfile|setup\.py)'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Python")
fi
if matches_file_list 'Cargo\.toml'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Rust")
fi
if matches_file_list 'go\.mod'; then
    BACKEND_STR=$(append_item "${BACKEND_STR}" "Go")
fi

# Runtime: Node.js (append if Node frameworks are present)
if matches_file_list 'package\.json'; then
    if has_item "${BACKEND_STR}" "Express" || has_item "${BACKEND_STR}" "Fastify" || \
       has_item "${BACKEND_STR}" "NestJS" || has_item "${BACKEND_STR}" "Koa" || \
       has_item "${BACKEND_STR}" "Hono" || has_item "${BACKEND_STR}" "Next.js"; then
        BACKEND_STR=$(append_item "${BACKEND_STR}" "Node.js")
    fi
fi

# If no backend framework detected but package.json exists and not pure frontend
if [[ -z "${BACKEND_STR}" ]] && matches_file_list 'package\.json'; then
    if ! matches_manifest '("react"|"vue"|"@angular"|"svelte"|"nuxt")'; then
        BACKEND_STR="Node.js"
    fi
fi

if [[ -z "${BACKEND_STR}" ]]; then
    BACKEND_STR="Custom / None detected"
fi

# ------------------------------------------------------------------------------
# 3. Detect Frontend Stack
# ------------------------------------------------------------------------------
FRONTEND_STR=""

if matches_manifest '("react"|"react-dom")'; then
    FRONTEND_STR=$(append_item "${FRONTEND_STR}" "React")
fi
if matches_manifest '("next"|next\.config)' || matches_file_list 'next\.config\.'; then
    FRONTEND_STR=$(append_item "${FRONTEND_STR}" "Next.js")
fi
if matches_manifest '("vue"|vue-router)' || matches_file_list '\.vue$'; then
    FRONTEND_STR=$(append_item "${FRONTEND_STR}" "Vue.js")
fi
if matches_manifest '("nuxt"|nuxt\.config)' || matches_file_list 'nuxt\.config\.'; then
    FRONTEND_STR=$(append_item "${FRONTEND_STR}" "Nuxt")
fi
if matches_manifest '("svelte"|@sveltejs)' || matches_file_list '(\.svelte$|svelte\.config\.)'; then
    FRONTEND_STR=$(append_item "${FRONTEND_STR}" "Svelte")
fi
if matches_manifest '("@angular/core"|@angular)' || matches_file_list 'angular\.json'; then
    FRONTEND_STR=$(append_item "${FRONTEND_STR}" "Angular")
fi
if matches_manifest '("vite"|vite\.config)' || matches_file_list 'vite\.config\.'; then
    FRONTEND_STR=$(append_item "${FRONTEND_STR}" "Vite")
fi
if matches_manifest '("tailwindcss"|@tailwindcss|tailwind)' || matches_file_list 'tailwind\.config\.'; then
    FRONTEND_STR=$(append_item "${FRONTEND_STR}" "Tailwind CSS")
fi

if [[ -z "${FRONTEND_STR}" ]]; then
    FRONTEND_STR="Custom / Headless / None detected"
fi

# ------------------------------------------------------------------------------
# 4. Detect Storage & State
# ------------------------------------------------------------------------------
STORAGE_STR=""

if matches_manifest '("@prisma/|prisma)' || matches_file_list 'schema\.prisma'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "Prisma")
fi
if matches_manifest 'drizzle'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "Drizzle")
fi
if matches_manifest 'typeorm'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "TypeORM")
fi
if matches_manifest 'sqlalchemy'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "SQLAlchemy")
fi
if matches_manifest 'alembic'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "Alembic")
fi
if matches_manifest 'sqlx'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "SQLx")
fi
if matches_manifest 'diesel'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "Diesel")
fi
if matches_manifest '(gorm\.io|github\.com/jinzhu/gorm)'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "GORM")
fi
if matches_manifest '(postgres|postgresql|psycopg|asyncpg|pg[[:space:]]*"|@types/pg)'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "PostgreSQL")
fi
if matches_manifest '(mysql|mysql2|pymysql|asyncmy)'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "MySQL")
fi
if matches_manifest '(redis|ioredis|aioredis)'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "Redis")
fi
if matches_manifest '(mongo|mongodb|mongoose|pymongo|motor)'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "MongoDB")
fi
if matches_manifest '(sqlite|sqlite3|rusqlite|aiosqlite)' || matches_file_list '\.(sqlite|sqlite3|db)$'; then
    STORAGE_STR=$(append_item "${STORAGE_STR}" "SQLite")
fi

if [[ -z "${STORAGE_STR}" ]]; then
    STORAGE_STR="Local file / Memory / None detected"
fi

# ------------------------------------------------------------------------------
# 5. Detect Testing & Tooling
# ------------------------------------------------------------------------------
TOOLING_STR=""

if matches_manifest '("vitest"|vitest)' || matches_file_list 'vitest\.config\.'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "Vitest")
fi
if matches_manifest '("jest"|jest\.config)' || matches_file_list 'jest\.config\.'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "Jest")
fi
if matches_manifest 'playwright' || matches_file_list 'playwright\.config\.'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "Playwright")
fi
if matches_manifest 'cypress' || matches_file_list 'cypress\.config\.'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "Cypress")
fi
if matches_manifest 'pytest' || matches_file_list 'pytest\.ini'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "pytest")
fi
if matches_manifest 'unittest'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "unittest")
fi
if matches_manifest 'ruff' || matches_file_list 'ruff\.toml'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "Ruff")
fi
if matches_file_list 'Cargo\.toml'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "Cargo Test")
fi
if matches_manifest '(stretchr/testify|testify)'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "Testify")
fi
if matches_file_list '(Dockerfile|docker-compose.*\.ya?ml|compose.*\.ya?ml)' || matches_manifest 'docker'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "Docker")
fi

# Package managers
if matches_file_list 'pnpm-lock\.yaml'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "pnpm")
elif matches_file_list 'yarn\.lock'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "yarn")
elif matches_file_list 'bun\.lockb?'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "bun")
elif matches_file_list 'package-lock\.json'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "npm")
fi

if matches_file_list 'poetry\.lock'; then
    TOOLING_STR=$(append_item "${TOOLING_STR}" "Poetry")
fi

if [[ -z "${TOOLING_STR}" ]]; then
    TOOLING_STR="Custom / None detected"
fi

# ------------------------------------------------------------------------------
# Token Replacement in Scaffolding Documents
# ------------------------------------------------------------------------------
OVERVIEW_MD="${TARGET_AGENTS}/knowledge/project-overview.md"
if [[ -f "${OVERVIEW_MD}" ]]; then
    replace_token_in_file "${OVERVIEW_MD}" "[Product / Service Name]" "${PROJECT_NAME}"
    replace_token_in_file "${OVERVIEW_MD}" "[e.g., FastAPI / Node.js / Go / Python]" "${BACKEND_STR}"
    replace_token_in_file "${OVERVIEW_MD}" "[e.g., React / Next.js / Vue / Tailwind CSS]" "${FRONTEND_STR}"
    replace_token_in_file "${OVERVIEW_MD}" "[e.g., PostgreSQL / Redis / SQLite]" "${STORAGE_STR}"
    replace_token_in_file "${OVERVIEW_MD}" "[e.g., pytest / Vitest / Playwright / Docker]" "${TOOLING_STR}"
fi

ARCH_MD="${TARGET_AGENTS}/knowledge/architecture.md"
if [[ -f "${ARCH_MD}" ]]; then
    replace_token_in_file "${ARCH_MD}" "[e.g., Python / FastAPI / Node.js]" "${BACKEND_STR}"
    replace_token_in_file "${ARCH_MD}" "[e.g., React / TypeScript / Vite / Tailwind CSS]" "${FRONTEND_STR}"
    replace_token_in_file "${ARCH_MD}" "[e.g., PostgreSQL / Redis]" "${STORAGE_STR}"
fi

# ------------------------------------------------------------------------------
# Terminal Report & Tree Summary
# ------------------------------------------------------------------------------
echo -e "${BLUE}-----------------------------------------------------------------${NC}"
echo -e "${GREEN}📊 KẾT QUẢ TỰ ĐỘNG NHẬN DIỆN TECH STACK (AUTO-DETECTION REPORT):${NC}"
echo -e "   📦 ${YELLOW}Project Name:${NC}      ${GREEN}${PROJECT_NAME}${NC}"
echo -e "   ⚙️  ${YELLOW}Backend Stack:${NC}     ${GREEN}${BACKEND_STR}${NC}"
echo -e "   🎨 ${YELLOW}Frontend Stack:${NC}    ${GREEN}${FRONTEND_STR}${NC}"
echo -e "   💾 ${YELLOW}Storage & State:${NC}   ${GREEN}${STORAGE_STR}${NC}"
echo -e "   🧪 ${YELLOW}Testing & Tooling:${NC} ${GREEN}${TOOLING_STR}${NC}"
echo -e "${BLUE}-----------------------------------------------------------------${NC}"
echo -e "${GREEN}✓ Đã đồng bộ thông tin vào .agents/knowledge/project-overview.md${NC}"
echo -e "${GREEN}✓ Hoàn tất khởi tạo cấu trúc .agents/!${NC}"
echo -e "Cây thư mục đã tạo:"
if [[ "${TARGET_DIR}" == "." ]]; then
    find "${TARGET_AGENTS}" -maxdepth 3 -print
else
    find "${TARGET_AGENTS}" -maxdepth 3 -print | sed -e "s;^${TARGET_DIR};.;g"
fi
echo -e "${BLUE}=================================================================${NC}"
