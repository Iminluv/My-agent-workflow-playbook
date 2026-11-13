---
name: impact-analysis
version: 1.0.0
priority: P1
trigger: before_code_edit
description: Comprehensive Impact Analysis and Full-Stack Synchronization protocol based on the "One Change, Two Sides" engineering principle.
---

# 🔄 Full-Stack Impact Analysis & Synchronization Protocol (P1)

> **Core Principle ("One Change, Two Sides"):** Never assume a Backend modification is invisible to the Frontend, or that a Client UI change is entirely independent of the API Server.

---

## 🔍 1. PRE-CHANGE INVESTIGATION (FOOTPRINT TRACING)

Before executing any file modification tool (`edit_file` or `write_file`):

1. **Backend API / Endpoint Changes:**
   - Use `grep` or code search tools to scan the frontend codebase for the endpoint URL and response payload fields:
     ```bash
     grep -rn "/api/v1/endpoint" frontend/
     ```
   - Identify every component that consumes this endpoint and may break if data shapes or status codes change.

2. **Database Schema / ORM Model Changes:**
   - Trace all routers, services, background workers, and repositories that read from or write to the modified table.
   - Verify that database migrations (`alembic`, `prisma`) match ORM model definitions.

3. **Shared Components & Utilities:**
   - Locate all consumer files importing the shared component to ensure updated props or signatures do not cause regression.

---

## 📋 2. MANDATORY SYNCHRONIZATION CHECKLIST

- [ ] **Data Model:** Synchronized across both Backend schemas (Pydantic / Zod) and Frontend types/interfaces.
- [ ] **Error Handling:** UI gracefully handles new HTTP status codes (400, 401, 403, 404, 422, 500) via toast notifications or fallback empty states.
- [ ] **Bilingual / Localization (i18n):** When new user-facing strings are introduced, update primary and secondary language files simultaneously (e.g., `en.json` and `vi.json`).
- [ ] **Zero Hardcoded Secrets:** Verify that no API keys, internal endpoints, or credentials are hardcoded into source code.

---

## 🧪 3. GOLDEN PATH VALIDATION

Trace and verify the complete end-to-end user flow:
1. **Trigger:** User interaction or scheduled event initiates the flow.
2. **Data Roundtrip:** UI Dispatch → HTTP Request → Middleware/Auth → Service/DB → API Response → UI Re-render.
3. **Automated Evidence:** Run affected test suites to verify zero regression:
   ```bash
   pytest tests/test_affected_endpoint.py
   cd frontend && npm test
   ```
