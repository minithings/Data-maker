# 🗃️ Database Maker v1.2

**Database Maker** là một công cụ quản lý dữ liệu dựa trên web, được thiết kế đặc biệt để giúp chỉnh sửa các tệp tin tài nguyên như `.tres` và `.json` dưới dạng bảng (spreadsheet) trực quan.

Thay vì chỉnh sửa từng file đơn lẻ, công cụ này gom nhóm các dữ liệu cùng loại, cho phép bạn quản lý hàng trăm đối tượng cùng lúc với trải nghiệm mượt mà như Excel nhưng dành riêng cho cấu trúc dữ liệu lập trình.

---

## ✨ Tính năng

### 🚀 Tương tác File Hệ thống
- **Chỉnh sửa trực tiếp:** Không cần upload/download. Mở thư mục dự án và lưu thay đổi trực tiếp vào ổ cứng.
- **Ghi nhớ phiên làm việc:** Tự động lưu Handle. Khi quay lại, bạn chỉ cần một cú click để **Restore** toàn bộ dự án mà không cần chọn lại đường dẫn.
- **Loại trừ thư mục:** Hỗ trợ file `.dbmakerignore` để bỏ qua các thư mục không cần quét (ví dụ: `.godot`, `addons`).

### 🎮 Hỗ trợ dữ liệu Godot
- **Phân tích Script (.gd):** Tự động đọc các file script để nhận diện kiểu dữ liệu:
  - `@export_multiline` → Trình soạn thảo văn bản dài.
  - `@export_enum` hoặc `enum` → Danh sách chọn (Dropdown).
  - `bool`, `int`, `float` → Tự động ép kiểu và hiển thị công cụ nhập liệu phù hợp.
- **Hỗ trợ Resource (.tres):** Đọc và ghi chuẩn định dạng Resource của Godot, giữ nguyên Header, metadata nội bộ (`metadata/_custom_type_script`, v.v.) và các field hệ thống không cần chỉnh sửa.
- **Parse multiline chính xác:** Tự động nhận diện và ghép các giá trị trải dài nhiều dòng như `Dictionary[String, int]({ ... })` hay `[{ ... }]`.
- **Ghi đúng format Godot:** Nhận diện và bảo toàn đầy đủ các kiểu dữ liệu đặc biệt khi lưu file, bao gồm:
  - `Array[String](...)`, `Array[int](...)`, v.v.
  - `Dictionary[String, int]({...})`, `Dictionary[String, float]({...})`
  - `[{...}]` (Array of Dictionaries)
  - `Vector2`, `Vector2i`, `Vector3`, `Vector3i`, `Vector4`, `Vector4i`
  - `Rect2`, `Rect2i`, `Color`, `Transform2D`, `Transform3D`, `Basis`, `Quaternion`, `Plane`, `AABB`
  - Tất cả `PackedArray` variants

### 🧩 Collection Editor
- **Chỉnh sửa trực quan** các kiểu dữ liệu phức tạp thay vì sửa chuỗi raw:
  - **Array[String] / Array[int/float]:** Danh sách item dọc, thêm/xóa từng phần tử.
  - **Dictionary:** Grid 2 cột key/value, thêm/xóa từng cặp.
  - **Array of Dicts `[{...}]`:** Mỗi object là một card riêng, có thể thêm/xóa cả object lẫn field bên trong.
- **Preview nhanh:** Hiển thị nội dung tóm tắt ngay trên cell mà không cần mở popup:
  - `[ irrigation, cooking ]` thay vì `[ 2 items ]`
  - `{ exp: 10.0, gold: 5.0 }` thay vì `{ 2 keys }`
  - `[{ player_level: 8, +1 }]` cho array dài
  - `[ empty ]` / `{ empty }` khi không có dữ liệu

### 📊 Quản lý Dữ liệu Hàng loạt
- **Cấu trúc Bảng:** Hiển thị dữ liệu theo nhóm Script hoặc File JSON.
- **Chỉnh sửa cột:** Thêm cột mới, đổi tên cột hoặc chuyển đổi kiểu dữ liệu (String ↔ Number ↔ Bool) cho toàn bộ file cùng lúc.
- **Tạo nhanh (Clone):** Tạo Resource mới dựa trên cấu trúc (Template) của một Resource có sẵn.
- **Import / Export JSON:** Xuất toàn bộ dữ liệu ra file JSON để backup hoặc xử lý ngoài, import lại bằng cách paste JSON string.

### 🛠️ Kiểm soát Sai sót (Validation)
- **Phát hiện lỗi:** Cảnh báo ngay lập tức nếu nhập sai kiểu dữ liệu (ví dụ: nhập chữ vào ô số).
- **Hệ thống cảnh báo:** Đánh dấu các ô trống hoặc dữ liệu nghi ngờ.
- **Chặn Sync lỗi:** Không cho phép lưu nếu dữ liệu đang có lỗi nghiêm trọng, đảm bảo an toàn cho project.

---

## 📖 Hướng dẫn sử dụng

### 1. Khởi động dự án
1. Mở file HTML trên trình duyệt (khuyến nghị **Chrome** hoặc **Edge** để có hỗ trợ FileSystem API tốt nhất).
2. Nhấn nút **[Open]** và chọn thư mục chứa các file dữ liệu.
3. Chấp nhận quyền "Xem tệp" và "Lưu thay đổi" khi trình duyệt yêu cầu.

### 2. Chỉnh sửa dữ liệu
- **Sửa nhanh:** Nhấp vào bất kỳ ô nào để sửa. Ô có thay đổi sẽ được đánh dấu viền màu cam (trạng thái Dirty).
- **Soạn thảo văn bản dài:** Với các cột kiểu `multiline`, nhấn icon mở rộng để mở Modal soạn thảo lớn.
- **Chỉnh sửa Collection:** Với các ô hiển thị `[ ... ]` hoặc `{ ... }`, nhấn vào để mở Collection Editor — chỉnh sửa từng phần tử riêng lẻ mà không cần gõ raw syntax.
- **Thêm đối tượng:** Nhấn nút **[+ Entry]** trong bảng để tạo thêm một hàng dữ liệu mới.

### 3. Lưu và Đồng bộ (Sync)
- Nhấn nút **Sync** (hoặc **Ctrl + S**) để lưu tất cả các file đang ở trạng thái Dirty.
- Nếu có lỗi nhập liệu, nút Sync sẽ bị vô hiệu hóa. Nhấp vào thông báo **ISSUES** để xem danh sách và điều hướng đến ô lỗi.

### 4. Quản lý Cột (Columns)
Di chuột vào tiêu đề cột để hiện các tùy chọn:
- **Icon Bút:** Đổi tên thuộc tính trên toàn bộ file trong nhóm.
- **Icon Bánh răng:** Thay đổi kiểu dữ liệu của cột đó.

### 5. Loại trừ thư mục
Tạo file `.dbmakerignore` ở thư mục gốc, mỗi dòng là tên một thư mục cần bỏ qua:
```
.godot
addons
bin
```

---

## ⌨️ Phím tắt & Thao tác nhanh

| Thao tác | Mô tả |
|---|---|
| **Ctrl + S** | Lưu tất cả thay đổi |
| **Giữ chuột & Kéo** | Cuộn ngang bảng (Grab Scroll) |
| **Search Bar** | Tìm kiếm tên file/identifier |
| **Click ô Collection** | Mở Collection Editor |
| **Click ngoài Modal** | Đóng Modal |

---

## 🗒️ Ghi chú kỹ thuật

- **Trình duyệt hỗ trợ:** Chrome 86+, Edge 86+. Firefox chưa hỗ trợ FileSystem Access API.
- **Godot version:** Tương thích với định dạng `.tres` format 3 (Godot 4.x).
- **Các field tự động bị ẩn:** `script`, `uid`, `format`, `load_steps`, `atlas`, `texture`, `sprite_frames`, `icon`, `metadata/_custom_type_script` và tất cả key có prefix `metadata/`.
