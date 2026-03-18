class_name HarvestableData extends CustomResource

# ============ BASIC INFO ============
@export_group("Basic Info")
@export var code: String = "oak_tree"
@export var name: String = "Oak Tree"
@export_multiline var description: String = ""
@export_enum("tree", "rock", "ore", "fish", "bush", "special") var resource_type: String = "tree"
# ============ SEASONAL SUPPORT ============
@export_group("Seasonal Visuals")
@export var is_seasonal: bool = false
# ============ HARVEST INFO ============
@export_group("Harvest Requirements")
@export var max_health: int = 100
@export_enum("none", "axe", "pickaxe", "hoe", "fishing_rod", "scythe") var required_tool: String = "none"
@export var min_tool_tier: int = 1 # 1: Wood, 2: Stone, 3: Iron...

@export_group("Harvest Rewards")
@export var drops: Array[LootData] = [] 
@export var xp_reward: int = 10 # Kinh nghiệm nhận được

@export_group("Regrowth")
@export var can_regrow: bool = true
@export var regrow_time_days: int = 3 # Game farming thường tính theo ngày trong game hơn là giây thực tế

# ============ GRID FOOTPRINT ============
@export_group("Grid Footprint")
@export var width_tiles: int = 1
@export var height_tiles: int = 1
@export var footprint_offset: Vector2i = Vector2i.ZERO
# ============ HELPER METHODS ============
func requires_tool() -> bool:
	return required_tool != "none"

## Kiểm tra cả loại tool và cấp độ tool
func is_harvestable(tool_type: String, tool_tier: int) -> bool:
	if required_tool == "none": return true
	if tool_type != required_tool: return false
	return tool_tier >= min_tool_tier
