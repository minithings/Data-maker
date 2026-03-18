class_name RecipeData extends Resource

@export_group("Thông tin chung")
@export var name: String
@export var craft_time: float = 3.0

@export_group("Nguyên liệu")
@export var ingredients: Dictionary[String, int]

@export_group("Thành phẩm")
@export var output_item_id: String
@export var output_amount: int = 1

@export_group("Điều kiện máy")
## Rỗng = mọi máy đều dùng được.
## Có giá trị = chỉ hiện ở những building_code trong danh sách.
@export var allowed_building_codes: Array[String] = []

func compare_resource(inventory: InventoryData) -> bool:
	var design_resource = inventory.slots
	var need_resource = ingredients.keys()
	#Nếu khác số lượng thì tạch lun
	if need_resource.size() != inventory.total_slot_have_item():
		return false
	#So sanh chi tiết
	var index = 0
	for item_id in need_resource:
		var slot: InventorySlotData = design_resource.get(index)
		if slot and slot.item_data:
			var is_required = inventory.check_item_required(item_id, 1)
			if not is_required:
				return false
			index += 1
	return true
