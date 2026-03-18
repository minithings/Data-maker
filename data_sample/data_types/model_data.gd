class_name ModelData extends CustomResource

@export_group("Body Features")
@export var skin_id: String = "1"           # Tên file: 1.png
@export_enum("Male", "Female") var gender: String = "Male"
@export var eyes_color: String = "Blue"     # Tên file: Blue.png

@export_group("Hair Style")
@export var hair_style: String = "Josh"     # Tên folder tóc
@export var hair_color: String = "Black"    # Tên file màu tóc

@export_group("Clothing & Accessories")
@export var clothes_color: String = "Blue"  # Tên file quần áo
@export var hat_name: String = "None"       # Tên file mũ/phụ kiện (hoặc "None")
@export var beard_name: String = "None"     # Tên file râu

@export_group("Equipment & Mounts")
@export var weapon_id: String = "Sword/1"      # Tên file vũ khí (Kiếm, Cung...)
@export var tool_id: String = "Sword/1"        # Tên file dụng cụ nông nghiệp (Cuốc, Rìu, Bình tưới...)
@export var mount_id: String = "Horse/1"       # Tên xe đạp hoặc thú cưỡi

# --- HELPER FUNCTIONS ---
func has_hat() -> bool:
	return hat_name != "None" and hat_name != ""

func has_beard() -> bool:
	return beard_name != "None" and beard_name != ""

func has_weapon() -> bool:
	return weapon_id != "None" and weapon_id != ""

func has_tool() -> bool:
	return tool_id != "None" and tool_id != ""

func has_mount() -> bool:
	return mount_id != "None" and mount_id != ""
