class_name RecipeData extends CustomResource

# ============ IDENTITY ============
@export var code: String = ""
@export var name: String = ""

# ============ CRAFT ============
@export var craft_time: float = 3.0
@export var ingredients: Dictionary[String, int] = {}
@export var output_item_id: String = ""
@export var output_amount: int = 1

# ============ ĐIỀU KIỆN ============
## Để rỗng = dùng được ở mọi building. Điền code building nếu chỉ craft tại máy cụ thể.
@export var allowed_building_codes: Array[String] = []
## Player có thể craft trực tiếp không cần building (mở qua popup chế tạo cá nhân).
@export var player_craftable: bool = false

# ============ LOGIC ============

func compare_resource(inventory: InventoryData) -> bool:
	if ingredients.is_empty():
		return false
	for item_id in ingredients:
		if not inventory.check_item_required(item_id, ingredients[item_id]):
			return false
	return true
