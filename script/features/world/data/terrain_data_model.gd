class_name TerrainDataModel extends CustomResource

enum SoilState {
	NORMAL = 0,
	TILLED = 1
}

var _soil_data: Dictionary = {}
var _structure_data: Dictionary = {}
var _crop_data: Dictionary = {}
var _metadata: Dictionary = {}

const DEFAULT_SOIL_INFO := {
	"state": SoilState.TILLED,
	"watered": false,
	"fertilizer": 0,
	"days_untouched": 0
}

func _init() -> void:
	_metadata = {
		"version": "1.0",
		"created_at": Time.get_unix_time_from_system()
	}

func clear_all() -> void:
	_soil_data.clear()
	_structure_data.clear()
	_crop_data.clear()

func has_crop(tile_pos: Vector2i) -> bool:
	return _crop_data.has(tile_pos)

func get_crop(tile_pos: Vector2i) -> Dictionary:
	return _crop_data.get(tile_pos, {})

## Trả về reference trực tiếp — caller chỉ nên đọc hoặc mutate value,
## KHÔNG thêm/xóa key trong khi đang iterate
func get_all_crops() -> Dictionary:
	return _crop_data

func set_crop(tile_pos: Vector2i, crop_info: Dictionary) -> void:
	_crop_data[tile_pos] = crop_info

func remove_crop(tile_pos: Vector2i) -> bool:
	return _crop_data.erase(tile_pos)

func is_soil_tilled(tile_pos: Vector2i) -> bool:
	if not _soil_data.has(tile_pos):
		return false
	return _soil_data[tile_pos].get("state", SoilState.NORMAL) == SoilState.TILLED

func set_soil_tilled(tile_pos: Vector2i) -> void:
	if not _soil_data.has(tile_pos):
		_soil_data[tile_pos] = DEFAULT_SOIL_INFO.duplicate()
	else:
		_soil_data[tile_pos]["state"] = SoilState.TILLED

func remove_soil(tile_pos: Vector2i) -> bool:
	return _soil_data.erase(tile_pos)

func is_soil_watered(tile_pos: Vector2i) -> bool:
	if not _soil_data.has(tile_pos):
		return false
	return _soil_data[tile_pos].get("watered", false)

func set_soil_watered(tile_pos: Vector2i, watered: bool) -> void:
	if _soil_data.has(tile_pos):
		_soil_data[tile_pos]["watered"] = watered
		if watered:
			_soil_data[tile_pos]["days_untouched"] = 0

func get_soil_info(tile_pos: Vector2i) -> Dictionary:
	return _soil_data.get(tile_pos, {})

func get_all_tilled_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for tile_pos in _soil_data:
		if is_soil_tilled(tile_pos):
			positions.append(tile_pos)
	return positions

func get_all_watered_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for tile_pos in _soil_data:
		if is_soil_watered(tile_pos):
			positions.append(tile_pos)
	return positions

func set_fertilizer(tile_pos: Vector2i, level: int) -> void:
	if _soil_data.has(tile_pos):
		_soil_data[tile_pos]["fertilizer"] = level

func increment_days_untouched(tile_pos: Vector2i) -> void:
	if _soil_data.has(tile_pos):
		_soil_data[tile_pos]["days_untouched"] += 1

func has_structure(tile_pos: Vector2i) -> bool:
	return _structure_data.has(tile_pos)

func get_structure_info(tile_pos: Vector2i) -> Dictionary:
	return _structure_data.get(tile_pos, {})

func set_structure(tile_pos: Vector2i, structure_info: Dictionary) -> void:
	_structure_data[tile_pos] = structure_info

func remove_structure(tile_pos: Vector2i) -> bool:
	return _structure_data.erase(tile_pos)

func get_all_structure_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for tile_pos in _structure_data:
		positions.append(tile_pos)
	return positions

func get_statistics() -> Dictionary:
	var dry_count: int = 0
	var wet_count: int = 0
	for tile_pos in _soil_data:
		if is_soil_watered(tile_pos):
			wet_count += 1
		else:
			dry_count += 1
	return {
		"total_tilled_soil": _soil_data.size(),
		"watered_soil": wet_count,
		"dry_soil": dry_count,
		"structures": _structure_data.size(),
		"metadata": _metadata
	}

func save_to_dict() -> Dictionary:
	var saved_soil: Dictionary = {}
	for tile_pos in _soil_data:
		saved_soil[str(tile_pos)] = _soil_data[tile_pos]

	var saved_structures: Dictionary = {}
	for tile_pos in _structure_data:
		saved_structures[str(tile_pos)] = _structure_data[tile_pos]

	var saved_crops: Dictionary = {}
	for tile_pos in _crop_data:
		saved_crops[str(tile_pos)] = _crop_data[tile_pos]

	return {
		"soil_data": saved_soil,
		"structure_data": saved_structures,
		"crop_data": saved_crops,
		"metadata": _metadata
	}

func load_from_dict(data: Dictionary) -> void:
	clear_all()

	var soil_dict: Dictionary = data.get("soil_data", {})
	for pos_str in soil_dict:
		_soil_data[_parse_string_to_vector2i(pos_str)] = soil_dict[pos_str]

	var structure_dict: Dictionary = data.get("structure_data", {})
	for pos_str in structure_dict:
		_structure_data[_parse_string_to_vector2i(pos_str)] = structure_dict[pos_str]

	var crop_dict: Dictionary = data.get("crop_data", {})
	for pos_str in crop_dict:
		_crop_data[_parse_string_to_vector2i(pos_str)] = crop_dict[pos_str]

	_metadata = data.get("metadata", _metadata)

func _parse_string_to_vector2i(pos_str: String) -> Vector2i:
	return Common.parse_string_to_vector2i(pos_str)
