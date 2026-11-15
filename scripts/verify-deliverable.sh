#!/usr/bin/env bash
# ==============================================================================
# scripts/verify-deliverable.sh
# 
# Comprehensive Deliverable Verification Utility
# Validates deliverable files (.docx, .xlsx, .pdf, .md, .txt, .json) for:
# - File existence and non-zero byte size
# - ZIP container integrity (DOCX, XLSX)
# - XML schema & well-formedness of internal XML streams
# - Strict WordprocessingML compliance (detects orphaned <w:fldChar>/<w:instrText> directly under <w:p>)
# - macOS textutil reader parsing acceptance (DOCX)
# - PDF header (%PDF-) and EOF marker (%%EOF) integrity
# - UTF-8 / Text file encoding sanity
#
# Exit codes:
#   0 - Deliverable passed all verification checks
#   1 - Verification failed or invalid usage
# ==============================================================================

set -euo pipefail

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1" >&2
}

print_usage() {
    echo "Usage: $0 <path-to-file>"
    echo "Supported formats: .docx, .xlsx, .pdf, .md, .txt, .json, .csv, .yaml, .yml"
}

if [ $# -lt 1 ]; then
    log_fail "No target file specified."
    print_usage
    exit 1
fi

TARGET_FILE="$1"

# 1. Basic Existence and Non-Empty Check
if [ ! -f "$TARGET_FILE" ]; then
    log_fail "Target file does not exist: $TARGET_FILE"
    exit 1
fi

FILE_SIZE=$(wc -c < "$TARGET_FILE" | tr -d ' ')
if [ "$FILE_SIZE" -le 0 ]; then
    log_fail "Target file is empty (0 bytes): $TARGET_FILE"
    exit 1
fi

log_info "Verifying deliverable: $TARGET_FILE (${FILE_SIZE} bytes)"

# Determine extension in lowercase
FILENAME=$(basename -- "$TARGET_FILE")
EXTENSION="${FILENAME##*.}"
EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

# Python interpreter check
PYTHON_BIN=""
if command -v python3 &>/dev/null; then
    PYTHON_BIN="python3"
elif command -v python &>/dev/null; then
    PYTHON_BIN="python"
else
    log_fail "Python 3 is required for XML/ZIP deliverable verification but was not found."
    exit 1
fi

# Verification routines based on file type
case "$EXTENSION_LOWER" in
    docx|xlsx)
        log_info "Running OpenXML package verification for .$EXTENSION_LOWER..."

        # Python verification script for ZIP & XML schema integrity
        # Note: Disable -e temporarily to safely capture Python's stdout and exit status
        set +e
        VERIFY_OUTPUT=$("$PYTHON_BIN" - "$TARGET_FILE" "$EXTENSION_LOWER" << 'EOF'
import sys
import zipfile
import xml.etree.ElementTree as ET

target_path = sys.argv[1]
ext = sys.argv[2]

# 1. Verify ZIP container integrity
try:
    with zipfile.ZipFile(target_path, 'r') as zf:
        bad_file = zf.testzip()
        if bad_file:
            print(f"CORRUPT_ZIP: Corrupted CRC in ZIP member: {bad_file}")
            sys.exit(1)
        namelist = zf.namelist()
except zipfile.BadZipFile as e:
    print(f"BAD_ZIP: Invalid ZIP archive: {e}")
    sys.exit(1)
except Exception as e:
    print(f"ZIP_ERROR: Failed to open ZIP archive: {e}")
    sys.exit(1)

# 2. Check for required OpenXML root streams
if "[Content_Types].xml" not in namelist:
    print("SCHEMA_ERROR: Missing required '[Content_Types].xml' in package root.")
    sys.exit(1)

if ext == "docx" and "word/document.xml" not in namelist:
    print("SCHEMA_ERROR: Missing required 'word/document.xml' in WordprocessingML package.")
    sys.exit(1)

if ext == "xlsx" and "xl/workbook.xml" not in namelist:
    print("SCHEMA_ERROR: Missing required 'xl/workbook.xml' in SpreadsheetML package.")
    sys.exit(1)

# 3. Parse and validate all XML members
w_namespace = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
def clean_tag(tag):
    if tag.startswith(f"{{{w_namespace}}}"):
        return tag[len(f"{{{w_namespace}}}"):]
    return tag

with zipfile.ZipFile(target_path, 'r') as zf:
    for name in namelist:
        if name.endswith(".xml") or name.endswith(".rels"):
            try:
                data = zf.read(name)
                root = ET.fromstring(data)
            except ET.ParseError as pe:
                print(f"XML_PARSE_ERROR: Failed to parse XML stream '{name}': {pe}")
                sys.exit(1)
            except Exception as e:
                print(f"XML_READ_ERROR: Error reading '{name}': {e}")
                sys.exit(1)

            # 4. Strict WordprocessingML schema checks for DOCX
            # Regression check for Session 9e05c5aa:
            # Detects if <w:fldChar> or <w:instrText> appears directly under <w:p> without <w:r> or <w:fldSimple>
            if ext == "docx" and (name == "word/document.xml" or name.startswith("word/header") or name.startswith("word/footer")):
                for p in root.iter(f"{{{w_namespace}}}p"):
                    for child in list(p):
                        tag_name = clean_tag(child.tag)
                        if tag_name in ("fldChar", "instrText"):
                            print(f"SCHEMA_DEFECT: In '{name}', found direct child <w:{tag_name}> directly inside <w:p>. Complex fields must be nested within a run (<w:r>) or valid <w:fldSimple>.")
                            sys.exit(1)

print("SUCCESS")
EOF
        )
        PY_STATUS=$?
        set -e

        if [ $PY_STATUS -ne 0 ] || [ "$VERIFY_OUTPUT" != "SUCCESS" ]; then
            log_fail "Package integrity check failed: $VERIFY_OUTPUT"
            exit 1
        fi
        log_pass "OpenXML ZIP container and internal XML trees are valid."

        # 5. OS-level textutil verification on macOS for DOCX
        if [ "$EXTENSION_LOWER" = "docx" ]; then
            if [[ "$OSTYPE" == "darwin"* ]] && command -v textutil &>/dev/null; then
                log_info "Validating DOCX against macOS textutil engine..."
                if ! textutil -info "$TARGET_FILE" >/dev/null 2>&1; then
                    log_fail "macOS textutil failed to parse DOCX. Document reader will reject this file."
                    exit 1
                fi
                log_pass "macOS textutil successfully parsed document metadata."
            else
                log_warn "Skipping macOS textutil verification (non-macOS or textutil not available)."
            fi
        fi
        ;;

    pdf)
        log_info "Running PDF container verification for $FILENAME..."
        
        # Verify PDF header in first 1024 bytes
        if ! head -c 1024 "$TARGET_FILE" | grep -q "%PDF-"; then
            log_fail "Invalid PDF header: Missing '%PDF-' magic marker in initial bytes."
            exit 1
        fi
        
        # Verify PDF EOF marker in trailing 2048 bytes
        if ! tail -c 2048 "$TARGET_FILE" | grep -q "%%EOF"; then
            log_fail "Invalid PDF trailer: Missing '%%EOF' end-of-file marker."
            exit 1
        fi
        
        log_pass "PDF structure contains valid header (%PDF-) and trailer (%%EOF)."
        ;;

    md|txt|json|csv|yaml|yml)
        log_info "Running text/encoding verification for $FILENAME..."
        
        # Verify UTF-8 clean encoding without unparseable binary nulls
        set +e
        VERIFY_RESULT=$("$PYTHON_BIN" - "$TARGET_FILE" << 'EOF'
import sys

target_path = sys.argv[1]
try:
    with open(target_path, 'rb') as f:
        content = f.read()
    
    # Check for null bytes (typical indicator of corrupt binary content in text deliverables)
    if b'\x00' in content:
        print("BINARY_CORRUPTION: File contains unexpected null bytes.")
        sys.exit(1)
        
    content.decode('utf-8')
    print("SUCCESS")
except UnicodeDecodeError as ude:
    print(f"ENCODING_ERROR: File is not valid UTF-8: {ude}")
    sys.exit(1)
except Exception as e:
    print(f"READ_ERROR: {e}")
    sys.exit(1)
EOF
        )
        PY_STATUS=$?
        set -e

        if [ $PY_STATUS -ne 0 ] || [ "$VERIFY_RESULT" != "SUCCESS" ]; then
            log_fail "Text verification failed: $VERIFY_RESULT"
            exit 1
        fi
        log_pass "Text file passed UTF-8 decoding and formatting sanity check."
        ;;

    *)
        log_warn "Unrecognized file extension '.$EXTENSION_LOWER'. Running general non-empty check."
        ;;
esac

echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}✓ DELIVERABLE VERIFICATION PASSED: $TARGET_FILE${NC}"
echo -e "${GREEN}======================================================${NC}"
exit 0
