#!/usr/bin/env bash
# ==============================================================================
# tests/test_install_and_deliverable.sh
# Integration tests for scripts/install.sh, scripts/verify.sh, and
# installed scripts/verify-deliverable.sh using isolated /tmp directories.
# ==============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "${TMP_DIR:-}"
}
trap cleanup EXIT INT TERM

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo "PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "FAIL: $1" >&2
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

assert_cmd_succeeds() {
    local label="$1"
    shift
    local output=""
    local status=0
    set +e
    output="$("$@" 2>&1)"
    status=$?
    set -e
    if [ "$status" -eq 0 ]; then
        pass "$label"
    else
        echo "$output" >&2
        fail "$label (expected exit 0, got $status)"
    fi
}

assert_cmd_fails() {
    local label="$1"
    local expected_pattern="$2"
    shift 2
    local output=""
    local status=0
    set +e
    output="$("$@" 2>&1)"
    status=$?
    set -e
    if [ "$status" -eq 0 ]; then
        echo "$output" >&2
        fail "$label (expected non-zero exit, got 0)"
        return
    fi
    if [ -n "$expected_pattern" ] && ! printf '%s' "$output" | grep -qE "$expected_pattern"; then
        echo "$output" >&2
        fail "$label (exit $status, but output missing pattern '$expected_pattern')"
        return
    fi
    pass "$label"
}

echo "=== Test 1: Dry-run install does not create target directory ==="
DRY_TARGET="${TMP_DIR}/ag-kit-dry"
assert_cmd_succeeds \
    "install.sh --dry-run succeeds" \
    env TARGET_PLUGIN_DIR="$DRY_TARGET" "$ROOT_DIR/scripts/install.sh" --dry-run

if [ ! -e "$DRY_TARGET" ]; then
    pass "dry-run did not create $DRY_TARGET"
else
    fail "dry-run unexpectedly created $DRY_TARGET"
fi

echo "=== Test 2: Symlink install + verify.sh --target ==="
SYMLINK_TARGET="${TMP_DIR}/ag-kit-symlink"
assert_cmd_succeeds \
    "install.sh --symlink succeeds against isolated TARGET_PLUGIN_DIR" \
    env TARGET_PLUGIN_DIR="$SYMLINK_TARGET" "$ROOT_DIR/scripts/install.sh" --symlink

if [ -L "${SYMLINK_TARGET}/hooks/circuit-breaker.mjs" ] \
    && [ -L "${SYMLINK_TARGET}/hooks/validate-tool-call.mjs" ] \
    && [ -L "${SYMLINK_TARGET}/hooks.json" ] \
    && [ -L "${SYMLINK_TARGET}/scripts/verify-deliverable.sh" ]; then
    pass "symlink mode created symlinks for hooks, hooks.json, and verify-deliverable.sh"
else
    fail "symlink mode missing expected symlinks"
fi

assert_cmd_succeeds \
    "verify.sh --target passes for symlink installation" \
    env TARGET_PLUGIN_DIR="$SYMLINK_TARGET" "$ROOT_DIR/scripts/verify.sh" --target

echo "=== Test 3: Copy install + verify.sh --target ==="
COPY_TARGET="${TMP_DIR}/ag-kit-copy"
assert_cmd_succeeds \
    "install.sh --copy succeeds against isolated TARGET_PLUGIN_DIR" \
    env TARGET_PLUGIN_DIR="$COPY_TARGET" "$ROOT_DIR/scripts/install.sh" --copy

if [ -f "${COPY_TARGET}/hooks/circuit-breaker.mjs" ] \
    && [ ! -L "${COPY_TARGET}/hooks/circuit-breaker.mjs" ] \
    && [ -x "${COPY_TARGET}/hooks/circuit-breaker.mjs" ] \
    && [ -f "${COPY_TARGET}/hooks/validate-tool-call.mjs" ] \
    && [ ! -L "${COPY_TARGET}/hooks/validate-tool-call.mjs" ] \
    && [ -x "${COPY_TARGET}/hooks/validate-tool-call.mjs" ] \
    && [ -f "${COPY_TARGET}/hooks.json" ] \
    && [ ! -L "${COPY_TARGET}/hooks.json" ] \
    && [ -f "${COPY_TARGET}/scripts/verify-deliverable.sh" ] \
    && [ ! -L "${COPY_TARGET}/scripts/verify-deliverable.sh" ] \
    && [ -x "${COPY_TARGET}/scripts/verify-deliverable.sh" ]; then
    pass "copy mode created non-symlink executable files for hooks and verify-deliverable.sh"
else
    fail "copy mode missing expected copied regular executable files"
fi

assert_cmd_succeeds \
    "verify.sh --target passes for copy installation" \
    env TARGET_PLUGIN_DIR="$COPY_TARGET" "$ROOT_DIR/scripts/verify.sh" --target

echo "=== Test 4: Installed verify-deliverable.sh validation checks ==="
INSTALLED_VERIFY_COPY="${COPY_TARGET}/scripts/verify-deliverable.sh"
INSTALLED_VERIFY_SYMLINK="${SYMLINK_TARGET}/scripts/verify-deliverable.sh"

assert_cmd_succeeds \
    "installed (copy) verify-deliverable.sh passes on README.md" \
    "$INSTALLED_VERIFY_COPY" "$ROOT_DIR/README.md"

assert_cmd_succeeds \
    "installed (symlink) verify-deliverable.sh passes on README.md" \
    "$INSTALLED_VERIFY_SYMLINK" "$ROOT_DIR/README.md"

assert_cmd_succeeds \
    "installed verify-deliverable.sh passes on hooks.json" \
    "$INSTALLED_VERIFY_COPY" "$ROOT_DIR/hooks.json"

# Empty file failure
EMPTY_FILE="${TMP_DIR}/empty.md"
: > "$EMPTY_FILE"
assert_cmd_fails \
    "installed verify-deliverable.sh fails on empty file" \
    "empty" \
    "$INSTALLED_VERIFY_COPY" "$EMPTY_FILE"

# Missing file failure
assert_cmd_fails \
    "installed verify-deliverable.sh fails on missing file" \
    "does not exist" \
    "$INSTALLED_VERIFY_COPY" "${TMP_DIR}/does-not-exist.md"

# Text file containing NUL (\x00) bytes
NUL_FILE="${TMP_DIR}/nul_bytes.txt"
python3 -c 'import sys; open(sys.argv[1], "wb").write(b"valid header\x00corrupted payload\n")' "$NUL_FILE"
assert_cmd_fails \
    "installed verify-deliverable.sh fails on text file containing NUL bytes" \
    "BINARY_CORRUPTION" \
    "$INSTALLED_VERIFY_COPY" "$NUL_FILE"

# Malformed .docx with bare <w:fldChar/> inside <w:p>
BAD_DOCX_FLDCHAR="${TMP_DIR}/malformed_fldchar.docx"
python3 - "$BAD_DOCX_FLDCHAR" << 'EOF'
import sys
import zipfile

out_path = sys.argv[1]
content_types = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>"""

rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>"""

bad_document = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:fldChar w:fldCharType="begin"/>
    </w:p>
  </w:body>
</w:document>"""

with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
    zf.writestr("[Content_Types].xml", content_types)
    zf.writestr("_rels/.rels", rels)
    zf.writestr("word/document.xml", bad_document)
EOF

assert_cmd_fails \
    "installed verify-deliverable.sh fails on malformed .docx (bare <w:fldChar/> inside <w:p>)" \
    "SCHEMA_DEFECT" \
    "$INSTALLED_VERIFY_COPY" "$BAD_DOCX_FLDCHAR"

# Malformed .docx with bare <w:instrText> inside <w:p>
BAD_DOCX_INSTR="${TMP_DIR}/malformed_instr.docx"
python3 - "$BAD_DOCX_INSTR" << 'EOF'
import sys
import zipfile

out_path = sys.argv[1]
content_types = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>"""

rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>"""

bad_document = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:instrText xml:space="preserve"> PAGE </w:instrText>
    </w:p>
  </w:body>
</w:document>"""

with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
    zf.writestr("[Content_Types].xml", content_types)
    zf.writestr("_rels/.rels", rels)
    zf.writestr("word/document.xml", bad_document)
EOF

assert_cmd_fails \
    "installed verify-deliverable.sh fails on malformed .docx (bare <w:instrText> inside <w:p>)" \
    "SCHEMA_DEFECT" \
    "$INSTALLED_VERIFY_COPY" "$BAD_DOCX_INSTR"

echo "--------------------------------------------------------------------------------"
echo "Summary: ${PASS_COUNT} passed, ${FAIL_COUNT} failed"
if [ "$FAIL_COUNT" -ne 0 ]; then
    exit 1
fi
exit 0
