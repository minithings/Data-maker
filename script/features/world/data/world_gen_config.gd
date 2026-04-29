class_name WorldGenConfig extends CustomResource
## WorldGenConfig — Toàn bộ tham số điều khiển quá trình sinh map.
##
## Tạo một file .tres duy nhất cho mỗi loại map:
##   res://resources/world/configs/camp_config.tres
##
## biome_rules được tra theo thứ tự — rule đầu tiên khớp sẽ được dùng.
## Đặt biome "đặc biệt" (water, mountain) lên đầu, grassland ở cuối làm fallback.

# ── Kích thước map ───────────────────────────────────────────────────────────
@export var map_width: int = 500
@export var map_height: int = 500

# ── Noise height ─────────────────────────────────────────────────────────────
@export var height_noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
@export var height_frequency: float = 0.04
@export var height_octaves: int = 4
@export var height_lacunarity: float = 2.0
@export var height_gain: float = 0.5

# ── Noise moisture ───────────────────────────────────────────────────────────
@export var moisture_noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
@export var moisture_frequency: float = 0.06
@export var moisture_octaves: int = 3
@export var moisture_lacunarity: float = 2.0
@export var moisture_gain: float = 0.5
## Offset seed giữa height và moisture để tránh tương quan
@export var moisture_seed_offset: int = 31337

# ── Zone noise (thay thế hệ thống bán kính tròn) ────────────────────────────
## Seed riêng cho zone noise (tách biệt với height/moisture)
@export var zone_seed: int = 77777
## Tần số noise zone — thấp hơn = vùng zone rộng hơn
@export var zone_frequency: float = 0.012
## Ngưỡng noise cho "village" — tile có noise <= giá trị này thành village
## Noise range [-1, 1]. Mặc định ~15% diện tích là village
@export var zone_village_threshold: float = -0.45
## Ngưỡng noise cho "farm" — noise từ village_threshold đến đây thành farm
## Mặc định ~25% diện tích là farm
@export var zone_farm_threshold: float = 0.05

# ── Biome rules ──────────────────────────────────────────────────────────────
## Array[BiomeRule] — thứ tự quan trọng, rule đầu khớp sẽ thắng
@export var biome_rules: Array[BiomeRule] = []

# ── Tâm bản đồ mặc định ─────────────────────────────────────────────────────
func get_center() -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(map_width / 2, map_height / 2)

## Tạo config mặc định bằng code (dùng khi không có .tres)
static func make_default() -> WorldGenConfig:
	var cfg := WorldGenConfig.new()

	# ── Mountain (height cao, moisture thấp) ─────────────────────────────────
	var mountain := BiomeRule.new()
	mountain.id = "mountain"
	mountain.display_name = "Mountain"
	mountain.tile_atlas_coord = Vector2i(9, 14)
	mountain.tile_type = "dirt"
	mountain.height_min = 0.45
	mountain.height_max = 1.0
	mountain.moisture_min = -1.0
	mountain.moisture_max = 0.3
	mountain.is_tillable = false
	mountain.entity_table = []

	# ── Forest (height vừa, moisture cao) ────────────────────────────────────
	var forest := BiomeRule.new()
	forest.id = "forest"
	forest.display_name = "Forest"
	forest.tile_atlas_coord = Vector2i(9, 18)
	forest.tile_type = "grass"
	forest.height_min = 0.15
	forest.height_max = 0.7
	forest.moisture_min = 0.2
	forest.moisture_max = 1.0
	forest.entity_table = [
		{"code": "maple_tree", "type": "tree", "density": 0.18, "zone": "forest"},
	]

	# ── Grassland (fallback cuối — mọi giá trị còn lại) ──────────────────────
	var grass := BiomeRule.new()
	grass.id = "grassland"
	grass.display_name = "Grassland"
	grass.tile_atlas_coord = Vector2i(9, 18)
	grass.tile_type = "grass"
	grass.height_min = -1.0
	grass.height_max = 1.0
	grass.moisture_min = -1.0
	grass.moisture_max = 1.0
	grass.entity_table = [
		{"code": "maple_tree", "type": "tree", "density": 0.04, "zone": "farm"},
		{"code": "berry_bush", "type": "forage", "density": 0.03, "zone": ""},
	]

	# Thứ tự quan trọng: rule hẹp nhất lên đầu, fallback cuối cùng
	cfg.biome_rules = [mountain, forest, grass]
	return cfg
