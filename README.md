# 🤖 Antigravity Multi-Agent Workflow & Rulebook

> Bộ quy tắc điều phối đa tác tử (Multi-Agent Orchestration), Cổng phê duyệt con người (Human-in-the-Loop Planning Gate), và Cẩm nang vận hành chuẩn (SOP) cho Google Antigravity.

---

## 📌 Tổng Quan

Kho lưu trữ này chuẩn hóa toàn bộ tư duy và quy trình làm việc giữa Người dùng và Đội ngũ Tác tử AI (AI Agents):
1. **Human-in-the-Loop Planning Gate:** Bắt buộc AI phải lập Ma trận Phân công (Delegation Matrix) và dừng lại chờ phê duyệt trước khi can thiệp vào mã nguồn hoặc chạy tác vụ nặng.
2. **True Multi-Agent Delegation:** Kích hoạt các subagent chuyên môn độc lập (`security-auditor`, `backend-specialist`, `frontend-specialist`,...) thay vì chạy đơn khối âm thầm.
3. **Anti-Silent Execution:** Bắt buộc công bố thông tin ngay ở Turn 1, công bố ranh giới Phase, và không được chạy quá 8 lệnh liên tiếp mà thiếu tương tác.
4. **Obsidian SOP Playbook:** Tài liệu vận hành chi tiết với đầy đủ sơ đồ tương tác Mermaid, Callouts và Case study thực chiến.

---

## 📂 Cấu Trúc Thư Mục

```text
.
├── WORKFLOW-PLAYBOOK.md        # 📘 Cẩm nang SOP định dạng chuẩn Obsidian
├── README.md                   # 📖 Tài liệu hướng dẫn sử dụng
├── .gitignore                  # 🧹 Loại bỏ file rác hệ thống & backup
├── rules/                      # 🏛️ Gói quy tắc bất biến cho Antigravity
│   ├── GEMINI.md               # Persistent constraints tổng thể
│   ├── core-protocol.md        # Ràng buộc Turn-1 & chống silent loop
│   ├── planning-gate.md        # Ma trận phân công & Cổng phê duyệt Proceed
│   ├── request-routing.md      # Phân loại yêu cầu & tự động chọn Specialist
│   ├── universal-rules.md      # Quy tắc toàn cục (Clean Code, Ngôn ngữ)
│   ├── code-rules.md           # Quy tắc phát triển mã nguồn
│   ├── design-rules.md         # Quy tắc thiết kế giao diện
│   └── quick-reference.md      # Bảng tra cứu nhanh Agent & Kỹ năng
└── scripts/                    # ⚙️ Bộ công cụ tự động hóa
    ├── install.sh              # Kịch bản đồng bộ sang Antigravity trong 1 nốt nhạc
    └── verify.sh               # Kịch bản kiểm tra tính toàn vẹn cấu hình
```

---

## 🚀 Hướng Dẫn Đồng Bộ Sang Máy Mới

### Bước 1: Clone Repository
```bash
git clone <URL_REPO_GITHUB_CUA_BAN> ~/Vscode/Agent-test
cd ~/Vscode/Agent-test
```

### Bước 2: Chạy Script Cài Đặt Tự Động
```bash
./scripts/install.sh
```
*   **Chế độ mặc định (Symlink):** Tạo liên kết mềm đến `~/.gemini/config/plugins/ag-kit/rules/`. Bất kỳ thay đổi nào trong repo sẽ có hiệu lực ngay lập tức với Antigravity.
*   **Chế độ Sao chép tĩnh (Copy):** Dùng `./scripts/install.sh --copy` nếu muốn sao chép độc lập.
*   *Tự động sao lưu:* Nếu phát hiện file cũ trong thư mục Antigravity, script sẽ tự động tạo thư mục backup an toàn.

### Bước 3: Kiểm Tra Tính Toàn Vẹn
```bash
./scripts/verify.sh
```

---

## 📓 Tích Hợp Vào Obsidian

*   File `WORKFLOW-PLAYBOOK.md` được thiết kế tương thích 100% với **Obsidian**:
    *   Hỗ trợ đầy đủ **Obsidian Callouts** (`[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!ABSTRACT]`).
    *   Sơ đồ tương tác **Mermaid** trực quan (Kiến trúc tổng quan, Sequence Diagram đa tác tử).
    *   Liên kết hai chiều **Wikilinks** (`[[...]]`) giúp kết nối vào đồ thị tri thức (Knowledge Graph) của bạn.
*   Chỉ cần kéo thả file `WORKFLOW-PLAYBOOK.md` vào Vault Obsidian của bạn là có thể đọc và tham khảo ngay.

---

## 📜 Giấy Phép (License)
MIT License. Tự do sử dụng, chỉnh sửa và chia sẻ cho mục đích cá nhân và tổ chức.
