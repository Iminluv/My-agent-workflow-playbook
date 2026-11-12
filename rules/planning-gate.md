---
name: planning-gate
version: 2.0.0
priority: P0
trigger: always_on
description: Mandatory Human-in-the-Loop Planning Gate and Phase-to-Agent/Skill Delegation Matrix with Phase 0 Git Branch Setup, Disjoint Ownership, and Proceed Approval Barrier.
---

# Human-in-the-Loop Planning Gate & Delegation Matrix (P0 - Enterprise v2.0)

> **Triết lý cốt lõi:** Người dùng không cần phải ghi nhớ danh mục tác tử hay tự chia nhỏ bài toán phức tạp. AI tự động xây dựng kế hoạch phân công độc lập, kiểm tra an toàn nhánh tại Phase 0, trình người dùng phê duyệt qua nút "Proceed" trước khi bắt đầu can thiệp mã nguồn.

---

## 🛑 1. Khi Nào Quy Tắc Này Được Kích Hoạt?

Bắt buộc áp dụng 100% đối với:
1. **Kiểm toán & Đánh giá toàn diện:** "review mọi code", "kiểm toán bảo mật", "audit hệ thống".
2. **Tái cấu trúc kiến trúc:** "refactor", "tái cấu trúc", "chuyển đổi kiến trúc".
3. **Tính năng đa tầng (Multi-Domain):** Chạm vào từ 2 tầng trở lên (Frontend + Backend + DB + CI/CD).
4. **Mọi yêu cầu có hơn 3 bước thực thi không tầm thường.**

---

## 📋 2. Ma Trận Phân Công Chuẩn Enterprise (Đã bao gồm Phase 0)

Trước khi thực thi bất kỳ công cụ chỉnh sửa hay kiểm thử nặng nào, AI (vai trò `orchestrator`) PHẢI lập bảng sau:

### Cấu Trúc Bắt Buộc:

| Phase | Tên Phase & Mục Tiêu | Chuyên Gia Phụ Trách | Kỹ Năng (Skills) | Sản Phẩm Đầu Ra (Deliverable) |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 0** | **Workspace & Git Safety Setup** | `devops-engineer` / `orchestrator` | `@bash-linux` | Nhánh `feat/*` đã được checkout an toàn |
| **Phase 1** | Khảo Sát & Lineage Audit | `code-archaeologist` | `@architecture` | Bản đồ trạng thái hiện tại & baseline |
| **Phase 2** | Kiểm Toán & Vá Lỗi Chuyên Môn | `security-auditor` / `backend-specialist` | `@vulnerability-scanner` | Patch mã nguồn trong phạm vi disjoint |
| **Phase 3** | Kiểm Thử Nghiệm Thu & Zero Regression | `qa-automation-engineer` | `@testing-patterns` | Pass 100% test suite tự động |
| **Phase 4** | Đóng Gói, Tổng Hợp & PR Release | `orchestrator` | `@clean-code` | Deliverable Report + Sẵn sàng merge PR |

---

## 🚪 3. Cổng Phê Duyệt "Proceed" (Artifact Feedback Barrier)

1. **Xuất bản Kế Hoạch ra Artifact:**
   AI bắt buộc phải ghi ma trận vào file Markdown với metadata:
   ```json
   "ArtifactMetadata": {
     "RequestFeedback": true,
     "UserFacing": true,
     "Summary": "Kế hoạch phân công đa tác tử và bảo vệ nhánh Git chờ phê duyệt."
   }
   ```
2. **🛑 DỪNG CÔNG CỤ HOÀN TOÀN (HARD STOP):**
   - AI **DỪNG MỌI CÔNG CỤ NGAY LẬP TỨC** sau khi xuất bản artifact.
   - **NGHIÊM CẤM:** Không được chạy Phase 0 hay sửa file trước khi người dùng click nút **Proceed** hoặc nhắn xác nhận trong chat.

---

## ⚡ 4. Kỷ Luật Thực Thi Sau Khi Được Duyệt

1. **Phase 0 là Bắt Buộc:**
   - Ngay tại Turn 1 sau khi được duyệt, Orchestrator phải chạy `git branch --show-current`.
   - Nếu đang ở `main` hoặc `master`, tạo nhánh mới: `git checkout -b feat/<task-slug>-<date>`.
2. **Khai Báo Ranh Giới Phase (Phase Checkpoints):**
   Mỗi khi chuyển tiếp phase hoặc domain, phát thông báo công khai:
   ```markdown
   ---
   ### 🚀 Bắt đầu Phase [X]: [Tên Phase]
   🤖 **Applying knowledge of `@[specialist-agent]`...**
   📚 **Using skills: `@[skill-1]` + `@[skill-2]`...**
   > **Mục tiêu:** [Tóm tắt 1-2 câu]
   ```
3. **Chống Silent Loop (Ngắt mạch 8 lệnh):** Tuyệt đối không chạy quá 8 tool calls liên tiếp mà không có thông báo trung gian.
4. **Phân Quyền Bằng Contract:** Mọi subagent phải nhận được contract phân định rõ `Allowed File Paths` theo quy định tại `delegation-contract.md`.
