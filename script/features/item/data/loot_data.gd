class_name LootData extends Resource

@export var item: ItemData
@export var min_quantity: int = 1
@export var max_quantity: int = 1
@export_range(0.0, 1.0) var drop_chance: float = 1.0

func _init() -> void:
	pass

func get_drop_count() -> int:
	if randf() > drop_chance:
		return 0
	return randi_range(min_quantity, max_quantity)
