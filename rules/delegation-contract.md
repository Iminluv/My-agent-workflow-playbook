---
name: delegation-contract
version: 1.0.0
priority: P0
trigger: invoke_subagent
description: Bản hợp đồng phân quyền bắt buộc mà Orchestrator phải truyền vào Prompt của từng Subagent để đảm bảo an toàn nhánh, phân định file sở hữu và ngăn chặn xung đột tài nguyên.
---

# 📜 Hợp Đồng Phân Quyền Tác Tử (Delegation Contract Specification)

> **MANDATORY:** Mọi lệnh gọi `invoke_subagent` giao việc chỉnh sửa mã nguồn hoặc thực thi kiểm thử ĐỀU PHẢI chứa đầy đủ các trường sau trong `Prompt`.

---

## 📋 MẪU HỢP ĐỒNG CHUẨN (STANDARD DELEGATION CONTRACT)

```markdown
=== DELEGATION CONTRACT ===
🎯 Role & Objective: [Tên chuyên gia và mục tiêu cụ thể 1-2 câu]
🌿 Git Working Branch: [Tên nhánh tính năng đã tạo sẵn, e.g., feat/audit-20261113]
📁 Allowed File Paths (Exclusive Ownership):
   - [Đường dẫn file hoặc glob duy nhất mà tác tử này ĐƯỢC PHÉP sửa]
   - Ví dụ: frontend/src/components/** (Không được chạm vào backend)
🚫 Prohibited File Paths:
   - [Tất cả các file ngoài phạm vi được giao, đặc biệt là file cấu hình chung]
🧪 Required Verification Command:
   - [Lệnh kiểm thử bắt buộc để chứng minh công việc hoàn tất, e.g., npm test]
🛑 Stop Conditions:
   - Dừng lại và báo cáo ngay nếu phát hiện xung đột nhánh hoặc file bị khóa
   - Không được tự ý gọi commit hoặc push lên git
📦 Expected Deliverables:
   - Báo cáo kết quả kiểm thử thực nghiệm
   - Danh sách chính xác các file đã sửa đổi kèm git diff tóm tắt
===========================
```

---

## 🔒 NGUYÊN TẮC BẢO TOÀN TÍNH ĐỘC LẬP (DISJOINT OWNERSHIP RULE)

1. **Không giao chung 1 file cho 2 tác tử:** Trong một chu kỳ thực thi song song, hai subagents KHÔNG BAO GIỜ được có chung file trong `Allowed File Paths`.
2. **Quyền kiểm soát cuối thuộc về Orchestrator:**
   - Subagents chỉ thực hiện thay đổi và nộp báo cáo thực nghiệm.
   - Orchestrator kiểm tra `git status -s` và `git diff --stat` trước khi hoàn tất nghiệm thu.
3. **Phục hồi sự cố:** Nếu một subagent làm hỏng trạng thái làm việc, Orchestrator có thể khôi phục lại chỉ riêng vùng file của tác tử đó thông qua `git checkout -- <path>` mà không ảnh hưởng tới các tác tử khác.
