class_name BiomeRule extends CustomResource
## BiomeRule — Định nghĩa một loại biome: tile nào được vẽ, entity nào được spawn.
##
## Tạo file .tres trong Godot Editor:
##   res://resources/world/biomes/grassland.tres
##   res://resources/world/biomes/forest.tres  ... v.v.
##
## entity_table là Array[Dictionary], mỗi phần tử có dạng:
##   { "code": "maple_tree", "type": "tree", "density": 0.05, "zone": "forest" }
##   density = xác suất spawn trên mỗi tile (0.0 → 1.0)
##   zone    = "" nghĩa là spawn ở mọi zone, hoặc chỉ spawn ở zone chỉ định

# ── Định danh ──────────────────────────────────────────────────────────────
@export var id: String = ""
## Tên hiển thị (debug / editor)
@export var display_name: String = ""

# ── Tile visual ─────────────────────────────────────────────────────────────
## Atlas coord trong ground tileset (SOURCE_GROUND_ID = 0)
@export var tile_atlas_coord: Vector2i = Vector2i(9, 18)
## Source ID trong TileSet (giữ 0 = SOURCE_GROUND_ID)
@export var tile_source_id: int = 0
## Loại tile vẽ ground — TerrainGenerator map sang TileType int
@export_enum("grass", "dirt", "water") var tile_type: String = "grass"

# ── Noise threshold — tile này được chọn khi height và moisture nằm trong khoảng ──
@export var height_min: float = -1.0
@export var height_max: float = 1.0
@export var moisture_min: float = -1.0
@export var moisture_max: float = 1.0

# ── Entity spawn ─────────────────────────────────────────────────────────────
## Array[Dictionary]:
##   code:    String  — entity code (e.g. "maple_tree", "copper_ore")
##   type:    String  — entity type (e.g. "tree", "rock", "forage")
##   density: float   — xác suất per-tile [0, 1]
##   zone:    String  — "" = mọi zone, hoặc "forest" / "farm" / ...
@export var entity_table: Array = []

# ── Walkable / tillable ──────────────────────────────────────────────────────
@export var is_walkable: bool = true
@export var is_tillable: bool = true

# ── Helper ───────────────────────────────────────────────────────────────────

func matches(height: float, moisture: float) -> bool:
	return height >= height_min and height <= height_max \
		and moisture >= moisture_min and moisture <= moisture_max

## Trả về danh sách entity cần spawn trên tile này (lọc theo zone nếu có)
func get_entities_for_zone(zone_id: String) -> Array:
	var result: Array = []
	for entry in entity_table:
		var entry_zone: String = entry.get("zone", "")
		if entry_zone == "" or entry_zone == zone_id:
			result.append(entry)
	return result
