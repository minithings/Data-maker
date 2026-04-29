class_name ItemFoodData extends ItemData

@export_group("Tiêu Thụ")
@export var health_restore: int = 0
@export var energy_restore: int = 10
@export var hunger_restore: int = 30

func get_tooltip_text() -> String:
	var text := super.get_tooltip_text()
	if hunger_restore > 0: text += "\nNo bụng: +%d" % hunger_restore
	if energy_restore > 0: text += "\nNăng lượng: +%d" % energy_restore
	if health_restore > 0: text += "\nMáu: +%d" % health_restore
	return text

func get_type_item() -> String:
	return "food"

func can_use() -> bool:
	return true

func _init() -> void:
	category_type = CategoryType.CONSUMABLE
