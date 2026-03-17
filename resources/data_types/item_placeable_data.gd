class_name ItemPlaceableData extends ItemData

@export_group("Xây Dựng")
@export var placeable_scene: PackedScene # Scene 3D/2D sẽ sinh ra trong world
@export var grid_size: Vector2i = Vector2i(1, 1) # Chiếm bao nhiêu ô đất (1x1, 2x1...)
@export var can_rotate: bool = true

func can_use() -> bool:
	return false

func get_type_item()->String:
	return "building"
