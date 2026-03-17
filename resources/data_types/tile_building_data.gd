class_name TileBuildingData extends BuildingData

@export_group("Tile setting")
@export var tile_source_id: int = 0
@export var tile_atlas_coords: Vector2i = Vector2i(0, 0)

func _init():
	# Mẹo nhỏ: Tự động khóa chặt loại xây dựng là TILE khi tạo mới file Resource này
	# Người thiết kế game sẽ không bao giờ bị quên tick chọn nữa!
	construction_type = ConstructionType.TILE
