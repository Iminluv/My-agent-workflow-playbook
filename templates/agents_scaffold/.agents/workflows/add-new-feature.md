---
description: Quy trình chuẩn để thêm một tính năng mới (End-to-End Feature Development)
---

# 🚀 Quy Trình Phát Triển Tính Năng Mới (Add New Feature Workflow)

## Bước 1: Khởi Tạo Nhánh Tính Năng (Git Feature Branch - BẮT BUỘC ĐẦU TIÊN)
> ⚠️ **Không bao giờ code trực tiếp trên `main` hoặc `master`.**

```bash
git fetch origin
git checkout main
git pull origin main
git checkout -b feat/<ten-tinh-nang>-$(date +%Y%m%d)
git branch --show-current
```

## Bước 2: Phân Tích & Xác Định Phạm Vi (Scope & Impact)
1. Xác định các tầng bị ảnh hưởng (Database, API, Service, Frontend UI).
2. Áp dụng quy tắc `impact-analysis.md`: Kiểm tra xem API mới/sửa có làm gãy UI hiện tại hay không.

## Bước 3: Phát Triển Backend & Database (Nếu có)
1. Cập nhật Model & Schema (Pydantic / Zod / SQLAlchemy).
2. Tạo migration database (Alembic / Prisma) và chạy thử nghiệm.
3. Tạo Endpoint Router và kết nối Service.
4. Viết Unit Test cho Endpoint mới.

## Bước 4: Phát Triển Frontend
1. Tạo hoặc cập nhật Component UI (Áp dụng thiết kế Mobile-First, Touch Target ≥ 44×44px).
2. Kết nối API Client với xử lý lỗi đầy đủ (Loading state, Error Toast).
3. Cập nhật song song file đa ngôn ngữ (nếu có i18n).

## Bước 5: Kiểm Thử Nghiệm Thu (Verification)
```bash
# Chạy toàn bộ test suite
pytest
cd frontend && npm test
```

## Bước 6: Đóng Gói & Tạo Pull Request
```bash
git status -s
git add <cac-file-cu-the>
git commit -m "feat(<scope>): <mo-ta-ngan-gon>"
git push -u origin feat/<ten-tinh-nang>-$(date +%Y%m%d)
```
Tạo Pull Request trên GitHub/GitLab và chờ CI Gate kiểm tra tự động trước khi merge.
