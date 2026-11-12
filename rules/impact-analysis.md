---
name: impact-analysis
version: 1.0.0
priority: P1
trigger: before_code_edit
description: Quy trình phân tích tác động toàn diện (Impact Analysis) và đồng bộ Full-Stack theo nguyên tắc "Một thay đổi, hai mặt" (One Change, Two Sides).
---

# 🔄 Phân Tích Tác Động & Đồng Bộ Hóa Full-Stack (Impact Analysis Protocol)

> **Nguyên tắc cốt lõi ("One Change, Two Sides"):** Không bao giờ giả định một thay đổi Backend là vô hình đối với Frontend, hoặc một thay đổi UI là hoàn toàn độc lập với API Server.

---

## 🔍 1. BƯỚC KHẢO SÁT DẤU CHÂN (PRE-CHANGE INVESTIGATION)

Trước khi thực hiện lệnh chỉnh sửa (`edit_file`):

1. **Thay đổi API / Endpoint Backend:**
   - Dùng lệnh `grep` hoặc `search_files` để quét toàn bộ thư mục frontend tìm kiếm URL endpoint và các trường dữ liệu payload:
     ```bash
     grep -rn "/api/v1/endpoint" frontend/
     ```
   - Xác định rõ component nào sẽ bị ảnh hưởng nếu đổi kiểu dữ liệu trả về.

2. **Thay đổi Cấu Trúc Database / Schema:**
   - Liệt kê tất cả Routers, Services và Repositories đọc/ghi bảng dữ liệu đó.
   - Kiểm tra migration đã đồng bộ với ORM model hay chưa.

3. **Thay đổi Component / Utility dùng chung:**
   - Quét tất cả các file import component đó để đảm bảo props mới không làm gãy component cũ.

---

## 📋 2. CHECKLIST ĐỒNG BỘ HÓA BẮT BUỘC (SYNCHRONIZATION CHECKLIST)

- [ ] **Data Model:** Đã cập nhật cả Pydantic schema (Backend) và Interface/State (Frontend).
- [ ] **Error Handling:** Đã xử lý các mã lỗi mới (400, 401, 403, 404, 422, 500) ở UI (Toast notification, fallback state).
- [ ] **Bilingual / i18n:** Nếu có chuỗi văn bản mới trên UI, đã thêm key song song vào cả file ngôn ngữ chính và phụ (ví dụ: `vi.json` và `en.json`).
- [ ] **Zero Hardcoded Secrets:** Tuyệt đối không hardcode API key, password, hoặc endpoint dev vào source code.

---

## 🧪 3. XÁC MINH LUỒNG VÀNG (GOLDEN PATH VALIDATION)

Kiểm thử luồng khép kín từ đầu đến cuối:
1. **Trigger:** Thao tác người dùng hoặc sự kiện khởi tạo.
2. **Roundtrip:** UI Dispatch → HTTP Request → Middleware/Auth → Service/DB → Response → UI Re-render.
3. **Automated Proof:** Chạy test suite liên quan để chứng minh không hồi quy:
   ```bash
   pytest tests/test_affected_endpoint.py
   cd frontend && npm test
   ```
