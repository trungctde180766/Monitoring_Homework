# Báo cáo Minh chứng Thực hành (Lab Evidence) - CloudWatch & SNS

Tài liệu này tổng hợp cấu hình và hình ảnh minh chứng kết quả cài đặt **CloudWatch Agent** trên máy ảo EC2 và thiết lập cảnh báo **CPU Alarm / Memory Alarm** gửi email thông qua **Amazon SNS**.

---

## 1. Cài đặt CloudWatch Agent trên EC2

Để thu thập các chỉ số chi tiết từ hệ điều hành của máy ảo EC2 (như bộ nhớ RAM, dung lượng đĩa cứng, CPU chi tiết), CloudWatch Agent đã được cài đặt và cấu hình thành công trên máy ảo.

### Thông tin máy ảo EC2:
* **Tên Instance (Tag Name):** `Hoangskibidi`
* **Instance ID:** `i-01348f65def85e28` (hoặc ID thực tế sau khi Terraform deploy)
* **Địa chỉ Public IP:** `13.229.114.49`
* **Địa chỉ Private IP:** `172.31.29.160`

### Kiểm tra trạng thái hoạt động của Agent:
Trạng thái hoạt động của CloudWatch Agent được kiểm tra bằng lệnh:
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

**Kết quả đầu ra:**
```json
{
  "status": "running",
  "starttime": "2026-06-12T00:49:31+00:00",
  "configstatus": "configured",
  "version": "1.300066.2"
}
```

### Hình ảnh minh chứng:
*(Thêm ảnh chụp màn hình kiểm tra terminal chạy lệnh status ở đây)*

---

## 2. Cấu hình CPU Alarm gửi Email Alert qua SNS

Thiết lập cảnh báo CloudWatch Alarm giám sát chỉ số sử dụng CPU (`CPUUtilization`) của máy ảo EC2, tự động gửi thông báo qua email khi CPU vượt ngưỡng cấu hình thông qua Amazon SNS (Simple Notification Service).

### Chi tiết cấu hình Alarm:
* **Tên Alarm:** `CPU-alarm`
* **Namespace:** `AWS/EC2`
* **Chỉ số giám sát (Metric name):** `CPUUtilization`
* **Instance ID:** `i-056c972234d03b617` (hoặc ID thực tế sau khi Terraform deploy)
* **Ngưỡng cảnh báo (Threshold):** `CPUUtilization > 80` trong vòng 1 điểm dữ liệu liên tiếp 5 phút (`for 1 datapoints within 5 minutes`).
* **Hành động (Actions):** Đã kích hoạt (`Actions enabled`), liên kết với một SNS Topic để gửi email.
* **Trạng thái hiện tại:** `Insufficient data` / `OK` / `ALARM`
* **Alarm ARN:** `arn:aws:cloudwatch:ap-southeast-1:458580846647:alarm:CPU-alarm` (hoặc ARN thực tế sau khi Terraform deploy)

### Hình ảnh minh chứng:
*(Thêm ảnh chụp màn hình từ trang chi tiết CloudWatch Console chứng minh cảnh báo CPU-alarm đã được tạo thành công với các hành động gửi thông báo được bật ở đây)*

---

## 3. Cấu hình Memory Alarm qua CloudWatch Agent (Gộp từ Bài 2)

Giám sát tỷ lệ phần trăm sử dụng RAM (`mem_used_percent`) đẩy về từ CloudWatch Agent hoạt động trên EC2.

### Chi tiết cấu hình Memory Alarm:
* **Tên Alarm:** `Memory-alarm`
* **Namespace:** `CWAgent` (Custom Metric Namespace)
* **Chỉ số giám sát (Metric name):** `mem_used_percent`
* **Ngưỡng cảnh báo (Threshold):** `mem_used_percent > 80` trong vòng 1 điểm dữ liệu liên tiếp 5 phút.
* **Hành động (Actions):** Đã kích hoạt (`Actions enabled`), gửi email qua SNS Topic.

### Hình ảnh minh chứng:
*(Thêm ảnh chụp màn hình cấu hình Memory-alarm trên CloudWatch Console và đồ thị metric mem_used_percent ở đây)*

---

## Hướng dẫn triển khai nhanh (Terraform Commands)

Nếu cần triển khai lại tài nguyên để chụp ảnh:

```bash
# 1. Khởi tạo
terraform init

# 2. Tạo file cấu hình biến thực tế (terraform.tfvars) từ file mẫu:
# Thay đổi email nhận cảnh báo của bạn tại dòng alert_email
cp terraform.tfvars.example terraform.tfvars

# 3. Apply tài nguyên lên AWS
terraform apply -auto-approve

# 4. Xác thực qua Email:
# Vào email của bạn để click "Confirm Subscription" link từ AWS SNS.

# 5. Dọn dẹp tài nguyên sau khi làm xong
terraform destroy -auto-approve
```
