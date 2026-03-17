class_name ItemData extends CustomResource

var id: String = ""
# Dùng để tìm kiếm và lưu trữ (Save System)
@export_group("Định danh")
@export var code: String = "" # Ví dụ: "material_wood"
@export var name: String = "Item" # Tên hiển thị: "Khúc gỗ sồi"
@export_multiline var description: String = "" # Mô tả khi hover chuột
# 2. HIỂN THỊ (Visuals)
@export_group("Hiển thị")
@export var icon: Texture2D

# 3. KHO ĐỒ (Inventory Behavior)
@export_group("Cài đặt kho đồ")
@export var stackable: bool = true # Có xếp chồng được không?
@export var max_stack_size: int = 100 # Xếp được bao nhiêu?

# 4. KINH TẾ (Economy)
@export_group("Thương mại")
@export var sell_price: int = 10 # Bán vào shop được bao nhiêu? (0 = không bán được)
@export var buy_price: int = 15 # Mua từ shop giá bao nhiêu?

@export_group("Chỉ số đặt biệt")
@export var stat: ItemStatData
# 5. PHÂN LOẠI CHUNG (Sorting/Filtering)
# Cái này dùng để lọc trong UI (ví dụ: Tab "Nguyên liệu", Tab "Qúy hiếm")
enum ItemRarity {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}
@export_group("Phân loại")
@export var rarity: ItemRarity = ItemRarity.COMMON
# Loại item chung để sort túi đồ (Type Sorting)
@export_enum("General", "Consumable", "Equipment", "Quest") var category_type: String = "General"

# --- CÁC HÀM CƠ BẢN (VIRTUAL METHODS) ---

# Hàm này để các lớp con (Seed, Tool) ghi đè (Override) thêm thông tin
func get_tooltip_text() -> String:
	var text = "[b]%s[/b]" % name # In đậm tên
	
	if rarity != ItemRarity.COMMON:
		text += "\n[color=yellow]%s[/color]" % ItemRarity.keys()[rarity]
		
	text += "\n%s" % description
	
	if sell_price > 0:
		text += "\n[color=green]Giá bán: %d vàng[/color]" % sell_price
	else:
		text += "\n[color=gray]Không thể bán[/color]"
		
	return text

func get_type_item() -> String:
	return "general"

func is_tool():
	return get_type_item() == "tool"

func is_consumable() -> bool:
	return category_type == "Consumable"

func can_use() -> bool:
	return false
