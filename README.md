# SmartDesk Mobile App – Quản lý Ticket GLPI trên Di Động

**SmartDesk Mobile App** là ứng dụng di động viết bằng **Flutter** giúp quản lý các ticket hỗ trợ kỹ thuật của hệ thống **GLPI** một cách dễ dàng, nhanh chóng và chuyên nghiệp. Ứng dụng cung cấp giao diện thân thiện, tích hợp đầy đủ các chức năng từ hệ thống GLPI qua REST API, cho phép người dùng đăng nhập, tạo, theo dõi, cập nhật ticket và quản lý profile cá nhân mọi lúc, mọi nơi.  

---

## 🚀 Dự án này đem lại gì?

- **Single codebase** cho cả iOS và Android, tối ưu hiệu suất và tiết kiệm công sức phát triển.
- Giao diện người dùng trực quan, thân thiện, hỗ trợ offline toàn diện.
- Quản lý ticket, FAQ, thông báo và profile cá nhân một cách trực quan và hiệu quả.
- Tích hợp chặt chẽ với GLPI REST API theo nguyên lý **Clean Architecture**.
- Sử dụng **Provider** và **BLoC** để quản lý trạng thái, dễ mở rộng và kiểm thử.

---

## 📝 Tính năng chính

- **Đăng nhập / Đăng xuất** an toàn, hỗ trợ multi-tenant.
- **Danh sách Ticket** theo trạng thái, ưu tiên, thể loại.
- **Tạo mới Ticket** nhanh chóng với nhiều tùy chọn.
- **Chi tiết Ticket**, cập nhật trạng thái, thêm comment, đính kèm file.
- **FAQ & Knowledge Base** giúp tự xử lý các vấn đề thường gặp.
- **Thông báo đẩy (Push Notification)** về trạng thái ticket, cập nhật mới.
- **Quản lý Profile cá nhân** và cài đặt ứng dụng.

---

## 🛠 Công nghệ & Kiến trúc

- **Flutter** & **Dart** (Chiếm 87% codebase)
- Native components: 
  - **C++**: Hiệu suất cao
  - **Swift**: Tích hợp iOS đặc biệt
  - **CMake**: Quản lý build system
  - **HTML**: WebView hiển thị FAQ, hướng dẫn
- Kiến trúc **Clean Architecture**: Presentation / Domain / Data Layers
- **State Management**: Provider + BLoC pattern
- Giao tiếp API: **HTTP Client** tích hợp GLPI REST API, xử lý authentication, lỗi, retry
- Offline cache: **SQLite / Hive** và **Secure Storage** cho tokens nhạy cảm

---

## 📁 Cách tổ chức dự án

- **lib/**
  - **presentation/**: Giao diện, widget, controller
  - **application/**: Service xử lý business logic
  - **data/**: Repositories, DataSources, Local Storage
  - **domain/**: Entities, Models chính
  - **external/**: API, SDK, các hệ thống liên quan

- **assets/**: Hình ảnh, icons, ảnh minh họa
- **lib/utils/**: Helper functions, constants

---

## 🏗 Cài đặt & chạy dự án

### Yêu cầu hệ thống
- **Android**: 5.0 trở lên, RAM tối thiểu 2GB (khuyến nghị 4GB)
- **iOS**: 11.0 trở lên, tương thích iPhone 6s / iPad Air 2 trở lên
- **Kết nối Internet** ổn định (tối thiểu 1Mbps)

### Các bước chạy dự án

```bash
# Clone repo về máy
git clone https://github.com/ckq7703/SmartDesk_MobileApp.git

# Vào thư mục dự án
cd SmartDesk_MobileApp

# Cài đặt dependencies
flutter pub get

# Chạy ứng dụng trên thiết bị giả lập hoặc thiết bị thực
flutter run
