## PATCH GHI CHÚ cho world_map_data.gd
## ─────────────────────────────────────────────────────────────────────────────
## Không thay đổi file gốc nhiều — chỉ cần đảm bảo mỗi entry trong spawn_list
## có field "id" (String) trước khi truyền vào HarvestChunkManager.setup().
##
## NẾU WorldGenManager / EntityPlacer của bạn chưa gán "id" vào spawn_list entries:
## Thêm đoạn helper sau vào WorldMapData hoặc gọi từ WorldGenManager.

class_name WorldMapData extends CustomResource

# ── Meta ─────────────────────────────────────────────────────────────────────
var map_seed: int = 0
var map_code: String = ""
var width: int = 0
var height: int = 0
var generated_at: int = 0

# ── Tile data ─────────────────────────────────────────────────────────────────
var tile_map: Array[int] = []
var biome_map: Dictionary = {}
var zone_map: Dictionary = {}

# ── Entity spawn list ─────────────────────────────────────────────────────────
## Array[Dictionary]: { "id": String, "code": String, "type": String, "tile_pos": Vector2i }
## "id" là BẮT BUỘC từ giờ — dùng để EntityRecord track từng entity qua các lần save/load.
var spawn_list: Array = []

# ── Helper accessors ──────────────────────────────────────────────────────────

func get_tile(x: int, y: int) -> int:
	var idx := y * width + x
	if idx < 0 or idx >= tile_map.size():
		return 0
	return tile_map[idx]

func set_tile(x: int, y: int, value: int) -> void:
	var idx := y * width + x
	if idx >= 0 and idx < tile_map.size():
		tile_map[idx] = value

func get_biome(tile_pos: Vector2i) -> String:
	return biome_map.get(tile_pos, "")

func get_zone(tile_pos: Vector2i) -> String:
	return zone_map.get(tile_pos, "border")

func is_valid() -> bool:
	return width > 0 and height > 0 and tile_map.size() == width * height

## Đảm bảo mọi entry trong spawn_list đều có "id".
## Gọi sau khi gen xong, trước khi lưu vào MapManager.
## Dùng map_code + tile_pos để tạo ID ổn định (không random) → save/load không bị drift.
func ensure_spawn_ids() -> void:
	for entry in spawn_list:
		if not entry.has("id") or entry["id"].is_empty():
			var tp: Vector2i = entry.get("tile_pos", Vector2i.ZERO)
			# Format: "<map_code>_<type>_<x>_<y>" → ID ổn định, unique trong map
			entry["id"] = "%s_%s_%d_%d" % [
				map_code,
				entry.get("type", "unknown"),
				tp.x,
				tp.y
			]

# ── Save / Load ───────────────────────────────────────────────────────────────

func save_to_dict() -> Dictionary:
	# Chỉ lưu meta — tile_map/biome_map/zone_map/spawn_list được tái tạo từ seed khi load
	return {
		"map_seed":     map_seed,
		"map_code":     map_code,
		"width":        width,
		"height":       height,
		"generated_at": generated_at,
	}

func load_from_dict(data: Dictionary) -> void:
	map_seed     = data.get("map_seed", 0)
	map_code     = data.get("map_code", "")
	width        = data.get("width", 0)
	height       = data.get("height", 0)
	generated_at = data.get("generated_at", 0)
	# tile_map / biome_map / zone_map / spawn_list để rỗng
	# → WorldGenManager sẽ regenerate từ seed trong apply_to_scene()
