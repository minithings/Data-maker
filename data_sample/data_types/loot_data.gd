# LootData.gd
class_name LootData extends Resource

@export var item: ItemData
@export var min_quantity: int = 1
@export var max_quantity: int = 1
@export_range(0.0, 1.0) var drop_chance: float = 1.0 # 1.0 là 100%
## Helper method: Tự tính toán xem có rớt hay không và rớt bao nhiêu
func get_drop_count() -> int:
	if randf() > drop_chance:
		return 0
	return randi_range(min_quantity, max_quantity)
