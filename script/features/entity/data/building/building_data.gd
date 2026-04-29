class_name BuildingData extends CustomResource

enum ConstructionType {
	SCENE,
	TILE
}

@export_group("Thông tin cơ bản")
@export var name: String = "Unknown Building"
@export var building_code: String = "unknown_building_code"
@export_enum(
	"residential", 
	"farming", 
	"production", 
	"processing", 
	"storage", 
	"service", 
	"decoration", 
	"road", 
	"defense"
) var type: String = "residential"
@export_multiline var description: String = ""

@export_subgroup("Thông tin mở rộng")
@export var allows_entry: bool = false
@export var health: int = GameConstants.DEFAULT_BUILDING_HEALTH
## Nếu true, building này luôn sẵn sàng build từ đầu game mà không cần research unlock.
@export var unlocked_by_default: bool = false
@export var can_upgrade: bool = false
@export var level: int = 1
@export var max_level: int = 3
@export var upgrade_gold_cost: int = 500
@export var upgrade_research_gate: String = ""  # code của ResearchNode cần unlock trước

@export_group("Cấu hình Xây dựng")
@export var skip_obstacle: bool = false
@export var passthrough_offsets: Array[Vector2i] = []
@export var construction_type: ConstructionType = ConstructionType.SCENE
@export var required_materials: Dictionary[String, int] = {}
@export var build_time: float = 0.0

@export_group("Hiển thị & Kích thước")
@export var icon: Texture2D
@export var size: Vector2i = Vector2i(2, 2)

func get_size() -> Vector2i:
	var actual_width = size.x * GameConstants.TILE_SIZE
	var actual_height = size.y * GameConstants.TILE_SIZE
	return Vector2i(actual_width, actual_height)
