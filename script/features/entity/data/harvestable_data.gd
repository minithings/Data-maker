class_name HarvestableData extends CustomResource

@export_group("Basic Info")
@export var code: String = "oak_tree"
@export_enum("tree", "rock", "ore", "fish", "bush", "special") var resource_type: String = "tree"
## Có thay đổi visual theo mùa không (dùng bởi HarvestableManager để propagate season)
@export var is_seasonal: bool = false

@export_group("Harvest")
@export var max_health: int = 100
@export_enum("none", "axe", "pickaxe", "hoe", "fishing_rod", "scythe") var required_tool: String = "none"
@export var min_tool_tier: int = 1

@export_group("Drops")
@export var drops: Array[LootData] = []

@export_group("Regrowth")
@export var can_regrow: bool = true
## Số ngày game cần để tái sinh
@export var regrow_days: int = 3

@export_group("Grid Footprint")
## Số tile chiều ngang entity chiếm 
@export var width_tiles: int = 1
## Số tile chiều dọc entity chiếm
@export var height_tiles: int = 1
## Offset tile gốc so với global_position
@export var footprint_offset: Vector2i = Vector2i.ZERO

func requires_tool() -> bool:
	return required_tool != "none"

func is_harvestable(tool_type: String, tool_tier: int) -> bool:
	if required_tool == "none": return true
	if tool_type != required_tool: return false
	return tool_tier >= min_tool_tier
