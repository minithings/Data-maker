class_name ItemPlaceableData extends ItemData

@export_group("Xây Dựng")
@export var placeable_scene: PackedScene
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var can_rotate: bool = true

func can_use() -> bool:
	return false

func get_type_item() -> String:
	return "placeable"
