---
name: universal-rules
version: 1.0.0
priority: P0
trigger: always_on
---

# Universal Rules (TIER 0) - AG Kit

> Always-active rules that apply to every request, regardless of domain.

---

## 🌐 Language Handling

When user's prompt is NOT in English:

1. **Internally translate** for better comprehension
2. **Respond in user's language** - match their communication
3. **Code comments/variables** remain in English

---

## 🧹 Clean Code (Global Mandatory)

**ALL code MUST follow `@[skills/clean-code]` rules. No exceptions.**

- **Code**: Concise, direct, no over-engineering. Self-documenting.
- **Testing**: Mandatory. Pyramid (Unit > Int > E2E) + AAA Pattern.
- **Performance**: Measure first. Adhere to current Core Web Vitals standards.
- **Infra/Safety**: 5-Phase Deployment. Verify secrets security.

---

## 🛡️ Zero-Defect Delivery & Pre-Delivery Verification (Global Mandatory)

**No deliverable file may be presented or delivered to the user without empirical pre-delivery verification.**

- **Mandatory Pre-Delivery Gate**: Every generated file (`.docx`, `.xlsx`, `.pdf`, `.md`, `.txt`, `.json`) MUST pass `scripts/verify-deliverable.sh <file>` prior to final presentation.
- **Strict Format & Schema Adherence**:
  - Word documents (`.docx`): Ensure valid ZIP container, well-formed XML trees, and strict WordprocessingML OpenXML compliance (no orphaned `<w:fldChar>` or `<w:instrText>` directly under `<w:p>`). Must pass OS-level reader parse checks (`textutil` on macOS).
  - Excel spreadsheets (`.xlsx`): Ensure valid ZIP container and `[Content_Types].xml` + `xl/workbook.xml` schema integrity.
  - PDF documents (`.pdf`): Verify `%PDF-` header and `%%EOF` trailer integrity.
  - Text & Markdown deliverables: Verify UTF-8 clean encoding and absence of corrupted binary null bytes.
- **Scratch Space Discipline**: All temporary generation scripts, scratch files, and exploratory test fixtures must be created in `<Artifact Directory Path>/scratch/` or `/tmp/`. Never pollute the workspace root or commit temporary scratch assets to Git.

---
