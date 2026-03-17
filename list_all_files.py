import os

# Đường dẫn thư mục gốc (có thể thay đổi nếu cần)
root_dir = os.path.abspath(os.path.dirname(__file__))

output_md = os.path.join(root_dir, "list_files.md")
file_paths = []

for dirpath, dirnames, filenames in os.walk(root_dir):
    for filename in filenames:
        file_path = os.path.join(dirpath, filename)
        # Bỏ qua chính script và file .md xuất ra
        if file_path.endswith("list_all_files.py") or file_path.endswith("list_files.md"):
            continue
        # Lấy path tương đối từ thư mục hiện tại
        rel_path = os.path.relpath(file_path, root_dir)
        file_paths.append(rel_path)

# Ghi ra file .md với định dạng đẹp
with open(output_md, "w", encoding="utf-8") as f:
    f.write("# Danh sách file trong thư mục này\n\n")
    for path in file_paths:
        f.write(f"- `{path}`\n")
