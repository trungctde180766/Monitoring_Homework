# AWS System Monitoring: CPU Alarm & CloudWatch Agent (Memory Alarm)

Dự án này sử dụng **Terraform** để tự động cấu hình hệ thống giám sát và cảnh báo trên AWS. Bài lab được chia làm 2 phần chính phục vụ việc lấy bằng chứng (Evidence) nộp bài:

- **Bài 1 (Session 01)**: Giám sát CPU mặc định (`CPUUtilization`) và gửi Email qua SNS khi CPU vượt quá **80% trong vòng 5 phút**.
- **Bài 2 (Session 02)**: Cài đặt và cấu hình **CloudWatch Agent** trên EC2 để thu thập các Custom Metric (RAM/Disk) và tạo cảnh báo sử dụng Memory vượt quá **80% trong vòng 5 phút**.

---

## Cấu trúc thư mục (Architecture Structure)

```text
Monitoring/
├── providers.tf             # Cấu hình AWS Provider
├── variables.tf             # Định nghĩa các biến (Region, Email, Instance Type,...)
├── main.tf                  # Tài nguyên chính: EC2, IAM Role, SNS Topic, Email Subscription, CloudWatch Alarms (CPU + Memory)
├── outputs.tf               # Đầu ra sau khi deploy (Instance ID, IP, Topic ARN, Alarms,...)
├── terraform.tfvars.example # File mẫu cấu hình các biến môi trường
├── .gitignore               # Loại bỏ các file nháp, State file của Terraform
└── scripts/
    └── stress_cpu.sh        # Script tự động cài đặt CloudWatch Agent và chạy stress test CPU
```

---

## Hướng dẫn triển khai (Deployment Guide)

### Bước 1: Chuẩn bị
Đảm bảo bạn đã cài đặt **Terraform** và cấu hình **AWS CLI** với quyền truy cập admin.
Bạn có thể kiểm tra kết nối AWS bằng lệnh:
```bash
aws sts get-caller-identity
```

### Bước 2: Cấu hình biến môi trường
1. Copy file cấu hình mẫu sang file cấu hình thực tế:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Mở file `terraform.tfvars` và thay đổi email nhận cảnh báo của bạn tại dòng `alert_email`:
   ```hcl
   alert_email = "email-cua-ban@gmail.com"
   ```

### Bước 3: Khởi tạo và Triển khai
Chạy các lệnh sau tại thư mục `Monitoring`:
```bash
# Khởi tạo Terraform
terraform init

# Kiểm tra tài nguyên chuẩn bị tạo
terraform plan

# Áp dụng cấu hình và tạo tài nguyên trên AWS
terraform apply -auto-approve
```

---

## Hướng dẫn xác thực & Chụp ảnh minh chứng (Evidence Guide)

Sau khi chạy lệnh `terraform apply` thành công:

### Bước chuẩn bị chung: Xác nhận Subscription Email (BẮT BUỘC)
- Kiểm tra hộp thư đến của địa chỉ email bạn đã nhập (kiểm tra cả thư mục Spam/Quảng cáo).
- Click vào link **Confirm Subscription** trong email từ **AWS Notifications** để kích hoạt nhận thông báo.

---

### BÀI 1: Cảnh báo CPU Utilization (Standard Metrics)

**Mô tả:** EC2 Instance tự động chạy script stress test đẩy CPU lên ~100% trong vòng 10 phút.

**Các bước lấy Evidence:**
1. **Evidence 1.1: Trạng thái Alarm trên CloudWatch Console**
   - Vào AWS Console -> **CloudWatch** -> **Alarms**.
   - Tìm alarm tên `ec2-cpu-high-alarm`.
   - Chụp ảnh màn hình khi trạng thái chuyển sang màu đỏ: **ALARM** (xảy ra sau ~5 phút chạy stress test).
2. **Evidence 1.2: Email cảnh báo CPU từ SNS**
   - Chụp ảnh màn hình email cảnh báo có tiêu đề `ALARM: "ec2-cpu-high-alarm" in US East (N. Virginia)` gửi đến hòm thư của bạn.
3. **Evidence 1.3: Email khôi phục (OK State)**
   - Sau 10 phút stress test kết thúc, CPU hạ nhiệt. Chụp ảnh màn hình email khôi phục khi alarm chuyển sang trạng thái **OK**.

---

### BÀI 2: Giám sát RAM qua CloudWatch Agent (Custom Metrics)

**Mô tả:** EC2 Instance được gán IAM Role thích hợp, tự động tải cài đặt, cấu hình và kích hoạt CloudWatch Agent để thu thập Metric của Memory.

**Các bước lấy Evidence:**
1. **Evidence 2.1: Trạng thái hoạt động của CloudWatch Agent trên EC2**
   - SSH vào EC2 Instance (sử dụng IP từ Terraform output).
   - Chạy lệnh kiểm tra trạng thái:
     ```bash
     sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
     ```
   - Chụp ảnh màn hình terminal hiển thị trạng thái `"status": "running"`.
2. **Evidence 2.2: Metric Custom xuất hiện trên CloudWatch**
   - Vào **CloudWatch** -> **Metrics** -> **All Metrics**.
   - Bạn sẽ thấy một namespace mới tên là **CWAgent**.
   - Click vào **CWAgent** -> **ImageId, InstanceId, InstanceType, device, fstype, path** (cho Disk) hoặc **InstanceId** (cho RAM).
   - Chọn metric `mem_used_percent` và chụp biểu đồ đồ thị hiển thị RAM đang được giám sát thành công.
3. **Evidence 2.3: Trạng thái Alarm của Memory**
   - Vào **CloudWatch** -> **Alarms** -> tìm alarm tên `ec2-memory-high-alarm`.
   - Chụp ảnh màn hình hiển thị Alarm này đang ở trạng thái **OK** (hoặc **ALARM** nếu bạn dùng stress test bộ nhớ).

---

## Dọn dẹp tài nguyên (Clean up)

Để tránh phát sinh chi phí, hãy dọn dẹp các tài nguyên sau khi kết thúc lab:
```bash
terraform destroy -auto-approve
```
