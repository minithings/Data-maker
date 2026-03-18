import minify_html
import os

def minify_safe(input_file, output_file):
    if not os.path.exists(input_file):
        print(f"Lỗi: Không tìm thấy file {input_file}")
        return

    print(f"Đang xử lý nén: {input_file}...")

    with open(input_file, 'r', encoding='utf-8') as f:
        html_content = f.read()

    try:
        # Chỉ sử dụng 2 tham số quan trọng nhất và phổ biến nhất
        # Các tham số gây lỗi đã được loại bỏ hoàn toàn
        minified = minify_html.minify(
            html_content,
            minify_css=True,
            minify_js=True
        )

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(minified)

        # Tính toán kết quả
        old_size = os.path.getsize(input_file) / 1024
        new_size = os.path.getsize(output_file) / 1024
        
        print("-" * 35)
        print(f"Hoàn thành rực rỡ!")
        print(f"Dung lượng gốc: {old_size:.2f} KB")
        print(f"Dung lượng sau nén: {new_size:.2f} KB")
        print(f"Giảm được: {old_size - new_size:.2f} KB")

    except Exception as e:
        print(f"Vẫn gặp lỗi: {e}")
        print("\nThử giải pháp cuối cùng: Nén không tham số...")
        try:
            minified = minify_html.minify(html_content)
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(minified)
            print("Đã nén thành công bằng chế độ mặc định!")
        except Exception as e2:
            print(f"Thất bại hoàn toàn: {e2}")

if __name__ == "__main__":
    minify_safe("index.html", "index.min.html")