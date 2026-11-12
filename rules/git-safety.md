---
name: git-safety
version: 1.0.0
priority: P0
trigger: always_active
description: Tuyệt đối cấm can thiệp hoặc ghi đè mã nguồn trực tiếp trên nhánh chính (main/master). Bắt buộc cô lập tác vụ trên nhánh tính năng (feature branch) hoặc worktree riêng biệt.
---

# 🛑 Quy Tắc An Toàn Nhánh Git (Git Branch Safety Protocol - P0)

> **CẤP ĐỘ ƯU TIÊN CAO NHẤT (P0):** Áp dụng cho TẤT CẢ các tác tử có quyền chỉnh sửa file (`orchestrator`, `backend-specialist`, `frontend-specialist`, `security-auditor`, `debugger`, `devops-engineer`, `test-engineer`,...).

---

## 🚫 1. ĐIỀU CẤM TUYỆT ĐỐI (ABSOLUTE PROHIBITION)

1. **TUYỆT ĐỐI KHÔNG BAO GIỜ** tạo, sửa, xóa file hoặc chạy lệnh commit trực tiếp trên nhánh `main` hoặc `master`.
2. **TUYỆT ĐỐI KHÔNG BAO GIỜ** force-push (`git push -f`) lên bất kỳ nhánh chia sẻ nào.
3. Không thực hiện các thao tác phá hủy Git (`git reset --hard`, `git clean -fdx`) khi chưa có sự xác nhận của người dùng.

---

## ✅ 2. BƯỚC 0 BẮT BUỘC TRƯỚC KHI CHỈNH SỬA CODE (STEP 0 - PRE-CODE GATE)

Trước khi gọi bất kỳ công cụ chỉnh sửa nào (`edit_file`, `write_file`, hoặc lệnh shell tạo file mã nguồn):

### Kiểm tra nhánh hiện tại:
```bash
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "not-a-git-repo")
```

- **Nếu `CURRENT_BRANCH` là `main` hoặc `master`:**
  👉 **DỪNG LẠI NGAY LẬP TỨC!** Không được ghi bất kỳ byte nào vào thư mục làm việc.
  👉 Tạo và chuyển sang nhánh tính năng mới theo quy chuẩn:
  ```bash
  TASK_SLUG="<ten-tac-vu-viet-lien-khong-dau>"
  DATE_STAMP=$(date +%Y%m%d)
  git checkout -b "feat/${TASK_SLUG}-${DATE_STAMP}"
  ```
  👉 Xác nhận lại:
  ```bash
  git branch --show-current  # Phải là feat/... mới được tiếp tục
  ```

---

## 👥 3. RÀNG BUỘC KHI ĐIỀU PHỐI SUBAGENTS (`invoke_subagent`)

Khi `orchestrator` phân quyền cho các subagents chuyên môn:

1. **Nhánh đã sẵn sàng:** `orchestrator` phải đảm bảo nhánh `feat/...` đã được checkout **TRƯỚC KHI** gọi `invoke_subagent`.
2. **Khai báo tường minh trong Prompt:**
   Trong nội dung `Prompt` của subagent, BẮT BUỘC phải truyền biến môi trường / thông tin nhánh:
   ```text
   RÀNG BUỘC AN TOÀN NHÁNH:
   - Thư mục làm việc đang ở nhánh: feat/<ten-nhanh>
   - Xác nhận nhánh qua `git branch --show-current` trước khi sửa file.
   - Tuyệt đối không can thiệp vào main.
   ```
3. **Phân định vùng file (File Ownership):**
   Nếu chạy nhiều subagents song song, mỗi subagent CHỈ ĐƯỢC PHÉP chỉnh sửa danh sách file không trùng lặp (Disjoint File Sets) để triệt tiêu nguy cơ xung đột (Race Condition).

---

## 🔄 4. QUY TRÌNH HỢP NHẤT AN TOÀN (SAFE MERGE & INTEGRATION)

Khi hoàn thành toàn bộ công việc:
1. Chạy toàn bộ test suite kiểm chứng (`pytest`, `npm test`).
2. Commit các thay đổi trên nhánh feature:
   ```bash
   git commit -m "feat(scope): concise description of verified change"
   ```
3. Tạo Pull Request hoặc báo cáo cho người dùng xác nhận trước khi merge vào `main`:
   ```markdown
   ✅ Toàn bộ thay đổi đã được đóng gói an toàn tại nhánh: `feat/<task-slug>`
   📊 Kết quả kiểm thử: [X passing tests]
   👉 Bạn có thể review qua `git diff main..feat/<task-slug>` trước khi gộp nhánh.
   ```
