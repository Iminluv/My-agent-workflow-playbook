#!/usr/bin/env bash
# ==============================================================================
# Antigravity Multi-Agent Rules & Agents Installer (Enterprise v2.0)
# Synchronizes rules, specialist agents, and templates to Antigravity configuration.
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
RULES_SRC="${ROOT_DIR}/rules"
AGENTS_SRC="${ROOT_DIR}/agents"
HOOKS_SRC="${ROOT_DIR}/hooks"
HOOKS_CONFIG_SRC="${ROOT_DIR}/hooks.json"
SCRIPTS_SRC="${ROOT_DIR}/scripts"
VERIFY_DELIVERABLE_SRC="${SCRIPTS_SRC}/verify-deliverable.sh"

TARGET_PLUGIN_DIR="${TARGET_PLUGIN_DIR:-${HOME}/.gemini/config/plugins/ag-kit}"
TARGET_RULES_DIR="${TARGET_RULES_DIR:-${TARGET_PLUGIN_DIR}/rules}"
TARGET_AGENTS_DIR="${TARGET_AGENTS_DIR:-${TARGET_PLUGIN_DIR}/agents}"
TARGET_HOOKS_DIR="${TARGET_HOOKS_DIR:-${TARGET_PLUGIN_DIR}/hooks}"
TARGET_HOOKS_CONFIG="${TARGET_HOOKS_CONFIG:-${TARGET_PLUGIN_DIR}/hooks.json}"
TARGET_SCRIPTS_DIR="${TARGET_SCRIPTS_DIR:-${TARGET_PLUGIN_DIR}/scripts}"

MODE="symlink"
DRY_RUN=false

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Synchronizes governance rules, specialist agents, PreToolUse hooks, and deliverable verification scripts to Antigravity plugin configuration.

Options:
  -s, --symlink    Install via symbolic links (default). Recommended for development.
  -c, --copy       Install by copying files directly.
  -n, --dry-run    Simulate actions without making filesystem modifications.
  -h, --help       Show this help message and exit.

Environment Variables:
  TARGET_PLUGIN_DIR    Base destination directory for plugin files (default: ~/.gemini/config/plugins/ag-kit)
  TARGET_RULES_DIR     Custom destination directory for rules (default: \$TARGET_PLUGIN_DIR/rules)
  TARGET_AGENTS_DIR    Custom destination directory for agents (default: \$TARGET_PLUGIN_DIR/agents)
  TARGET_HOOKS_DIR     Custom destination directory for hooks (default: \$TARGET_PLUGIN_DIR/hooks)
  TARGET_HOOKS_CONFIG  Custom destination path for hooks.json (default: \$TARGET_PLUGIN_DIR/hooks.json)
  TARGET_SCRIPTS_DIR   Custom destination directory for scripts (default: \$TARGET_PLUGIN_DIR/scripts)

EOF
}

# Parse Command-Line Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--copy)
            MODE="copy"
            shift
            ;;
        -s|--symlink)
            MODE="symlink"
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
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
echo -e "${BLUE}🚀 ANTIGRAVITY ENTERPRISE WORKFLOW BOOTSTRAP (v2.0)${NC}"
echo -e "${BLUE}=================================================================${NC}"

MODE_UPPER="$(echo "${MODE}" | tr '[:lower:]' '[:upper:]')"
if [[ "${DRY_RUN}" == "true" ]]; then
    echo -e "⚙️  Installation Mode : ${YELLOW}${MODE_UPPER} (DRY RUN - NO CHANGES)${NC}"
else
    echo -e "⚙️  Installation Mode : ${GREEN}${MODE_UPPER}${NC}"
fi
echo -e "📂 Rules Source       : ${CYAN}${RULES_SRC}${NC}"
echo -e "📂 Agents Source      : ${CYAN}${AGENTS_SRC}${NC}"
echo -e "📂 Hooks Source       : ${CYAN}${HOOKS_SRC}${NC}"
echo -e "📂 Hooks Config       : ${CYAN}${HOOKS_CONFIG_SRC}${NC}"
echo -e "📂 Deliverable Script : ${CYAN}${VERIFY_DELIVERABLE_SRC}${NC}"
echo -e "🎯 Rules Target       : ${CYAN}${TARGET_RULES_DIR}${NC}"
echo -e "🎯 Agents Target      : ${CYAN}${TARGET_AGENTS_DIR}${NC}"
echo -e "🎯 Hooks Target       : ${CYAN}${TARGET_HOOKS_DIR}${NC}"
echo -e "🎯 Hooks Config Target: ${CYAN}${TARGET_HOOKS_CONFIG}${NC}"
echo -e "🎯 Scripts Target     : ${CYAN}${TARGET_SCRIPTS_DIR}${NC}"

# Pre-flight Verification of Source Directories and Files
if [[ ! -d "${RULES_SRC}" ]]; then
    echo -e "${RED}❌ Fatal: Rules source directory does not exist: ${RULES_SRC}${NC}"
    exit 1
fi

if [[ ! -d "${AGENTS_SRC}" ]]; then
    echo -e "${RED}❌ Fatal: Agents source directory does not exist: ${AGENTS_SRC}${NC}"
    exit 1
fi

if [[ ! -d "${HOOKS_SRC}" ]]; then
    echo -e "${RED}❌ Fatal: Hooks source directory does not exist: ${HOOKS_SRC}${NC}"
    exit 1
fi

if [[ ! -f "${HOOKS_CONFIG_SRC}" ]]; then
    echo -e "${RED}❌ Fatal: Hooks configuration file does not exist: ${HOOKS_CONFIG_SRC}${NC}"
    exit 1
fi

if [[ ! -f "${VERIFY_DELIVERABLE_SRC}" ]]; then
    echo -e "${RED}❌ Fatal: Deliverable verification script does not exist: ${VERIFY_DELIVERABLE_SRC}${NC}"
    exit 1
fi

# Function to synchronize a single source file to a destination path
sync_file() {
    local src_file="$1"
    local dest_file="$2"
    local executable="${3:-false}"
    local filename
    filename="$(basename "${src_file}")"
    local dest_dir
    dest_dir="$(dirname "${dest_file}")"

    if [[ "${DRY_RUN}" == "true" ]]; then
        if [[ "${MODE}" == "symlink" ]]; then
            echo -e "  [DRY-RUN] 🔗 Would link : ${YELLOW}${filename}${NC} -> ${src_file} (target: ${dest_file})"
        else
            echo -e "  [DRY-RUN] 📄 Would copy : ${YELLOW}${filename}${NC} -> ${dest_file}"
        fi
        return 0
    fi

    mkdir -p "${dest_dir}"

    if [[ -e "${dest_file}" || -L "${dest_file}" ]]; then
        rm -f "${dest_file}"
    fi

    if [[ "${MODE}" == "symlink" ]]; then
        if [[ "${executable}" == "true" && ! -x "${src_file}" ]]; then
            chmod +x "${src_file}"
        fi
        ln -s "${src_file}" "${dest_file}"
        echo -e "  🔗 Linked : ${GREEN}${filename}${NC}"
    else
        cp "${src_file}" "${dest_file}"
        if [[ "${executable}" == "true" ]]; then
            chmod +x "${dest_file}"
        fi
        echo -e "  📄 Copied : ${GREEN}${filename}${NC}"
    fi
}

# Function to synchronize matching files from a source directory to a target directory
sync_folder() {
    local src_dir="$1"
    local dest_dir="$2"
    local label="$3"
    local pattern="${4:-*.md}"
    local executable="${5:-false}"

    if [[ "${DRY_RUN}" != "true" ]]; then
        mkdir -p "${dest_dir}"
    fi

    echo -e "\n${BLUE}⏳ Synchronizing ${label}...${NC}"
    local count=0

    for src_file in "${src_dir}"/${pattern}; do
        [[ -e "${src_file}" ]] || continue
        local filename
        filename="$(basename "${src_file}")"
        sync_file "${src_file}" "${dest_dir}/${filename}" "${executable}"
        count=$((count + 1))
    done

    echo -e "  ✨ Synchronized ${GREEN}${count}${NC} files for ${label}."
    return 0
}

# Synchronize Rules, Specialist Agents, Hooks, hooks.json, and verify-deliverable.sh
sync_folder "${RULES_SRC}" "${TARGET_RULES_DIR}" "Rules (P0/P1 Governance)" "*.md" "false"
sync_folder "${AGENTS_SRC}" "${TARGET_AGENTS_DIR}" "Agents (Specialist Roles)" "*.md" "false"
sync_folder "${HOOKS_SRC}" "${TARGET_HOOKS_DIR}" "Hooks (PreToolUse Safety & Circuit Breaker)" "*.mjs" "true"

echo -e "\n${BLUE}⏳ Synchronizing Hooks Configuration (hooks.json)...${NC}"
sync_file "${HOOKS_CONFIG_SRC}" "${TARGET_HOOKS_CONFIG}" "false"
echo -e "  ✨ Synchronized ${GREEN}1${NC} file for Hooks Configuration."

echo -e "\n${BLUE}⏳ Synchronizing Deliverable Verification Script...${NC}"
sync_file "${VERIFY_DELIVERABLE_SRC}" "${TARGET_SCRIPTS_DIR}/verify-deliverable.sh" "true"
echo -e "  ✨ Synchronized ${GREEN}1${NC} file for Deliverable Verification Script."

echo -e "\n${GREEN}=================================================================${NC}"
echo -e "${GREEN}🎉 ENTERPRISE MULTI-AGENT GOVERNANCE UPGRADE COMPLETE!${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo -e "💡 Active Protections: Git Branch Safety (P0), Planning Gate v2,"
echo -e "   Delegation Contract, Full-Stack Impact Analysis, PreToolUse Hooks, and 20 Agents."
echo -e "💡 To verify your installation and frontmatter tools, run: ${YELLOW}./scripts/verify.sh${NC}\n"
