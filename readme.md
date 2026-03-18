
---

# 🗃️ Database Maker v1.0

**Database Maker** là một công cụ quản lý dữ liệu dựa trên web, được thiết kế đặc biệt để giúp chỉnh sửa các tệp tin tài nguyên như `.tres` và `.json` dưới dạng bảng (spreadsheet) trực quan.

Thay vì chỉnh sửa từng file đơn lẻ, công cụ này gom nhóm các dữ liệu cùng loại, cho phép bạn quản lý hàng trăm đối tượng cùng lúc với trải nghiệm mượt mà như Excel nhưng dành riêng cho cấu trúc dữ liệu lập trình.

---

## ✨ Tính năng

### 🚀 Tương tác File Hệ thống
- **Chỉnh sửa trực tiếp:** Không cần upload/download. Mở thư mục dự án và lưu thay đổi trực tiếp vào ổ cứng.
- **Ghi nhớ phiên làm việc:** Tự động lưu Handle. Khi quay lại, bạn chỉ cần một cú click để "Restore" toàn bộ dự án mà không cần chọn lại đường dẫn.

### 🎮 Hỗ trợ dữ liệu Godot 
- **Phân tích Script (.gd):** Tự động đọc các file script để nhận diện kiểu dữ liệu:
    - `@export_multiline`: Hiển thị trình soạn thảo văn bản dài.
    - `@export_enum` hoặc `enum`: Hiển thị danh sách chọn (Dropdown).
    - `bool`, `int`, `float`: Tự động ép kiểu và hiển thị công cụ nhập liệu phù hợp.
- **Hỗ trợ Resource (.tres):** Đọc và ghi chuẩn định dạng Resource của Godot, giữ nguyên Header và các Metadata quan trọng.

### 📊 Quản lý Dữ liệu Hàng loạt
- **Cấu trúc Bảng:** Hiển thị dữ liệu theo nhóm Script hoặc File JSON.
- **Chỉnh sửa cột:** Thêm cột mới, đổi tên cột hoặc chuyển đổi kiểu dữ liệu (String ↔ Number ↔ Bool) cho toàn bộ hàng loạt file cùng lúc.
- **Tạo nhanh (Clone):** Tạo Resource mới dựa trên cấu trúc (Template) của một Resource có sẵn.

### 🛠️ Kiểm soát Sai sót (Validation)
- **Phát hiện lỗi:** Cảnh báo ngay lập tức nếu nhập sai kiểu dữ liệu (vd: nhập chữ vào ô số).
- **Hệ thống cảnh báo:** Đánh dấu các ô trống hoặc dữ liệu nghi ngờ.
- **Chặn Sync lỗi:** Không cho phép lưu đè vào file nếu dữ liệu đang có lỗi nghiêm trọng, đảm bảo an toàn cho project.

---

## 📖 Hướng dẫn sử dụng

### 1. Khởi động dự án
1. Mở file HTML trên trình duyệt (Khuyến nghị **Chrome** hoặc **Edge** để có hỗ trợ FileSystem API tốt nhất).
2. Nhấn nút **[Open]** và chọn thư mục chứa các file dữ liệu của bạn.
3. Chấp nhận quyền "Xem tệp" và "Lưu thay đổi" khi trình duyệt yêu cầu.

### 2. Chỉnh sửa dữ liệu
- **Sửa nhanh:** Nhấp vào bất kỳ ô nào để sửa. Ô có thay đổi sẽ được đánh dấu viền màu cam (Trạng thái Dirty).
- **Soạn thảo văn bản dài:** Với các cột kiểu `multiline`, nhấn icon mở rộng để mở Modal soạn thảo lớn.
- **Thêm đối tượng:** Nhấn nút **[+ Entry]** trong bảng để tạo thêm một hàng dữ liệu mới.

### 3. Lưu và Đồng bộ (Sync)
- Nhấn nút **Sync** (hoặc nhấn tổ hợp phím **Ctrl + S**) để lưu tất cả các file đang ở trạng thái "Dirty" vào ổ cứng.
- Nếu có lỗi nhập liệu, nút Sync sẽ bị vô hiệu hóa. Nhấp vào thông báo **ISSUES** để xem danh sách và sửa lỗi.

### 4. Quản lý Cột (Columns)
- Di chuột vào tiêu đề cột để hiện các tùy chọn:
    - **Icon Bút:** Đổi tên thuộc tính trong tất cả các file.
    - **Icon Bánh răng:** Thay đổi kiểu dữ liệu của cột đó.

---

## Phím tắt & Thao tác nhanh
- **Ctrl + S:** Lưu tất cả thay đổi.
- **Giữ chuột trái & Kéo:** Cuộn ngang bảng dữ liệu (Grab Scroll) cực nhanh.
- **Search Bar:** Tìm kiếm nhanh tên file/identifier trong thư mục hiện tại.

---