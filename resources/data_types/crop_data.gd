@tool
class_name CropData extends CustomResource

@export_group("Thông tin cây trồng")
@export var crop_code: String = "beetroot"
@export var name: String = "Củ Dền"

@export_group("Hệ thống nông trại")
@export var growth_days: float = 0.0: 
	get:
		return _calculate_total_days()

@export var growth_hours: float = 0.0: 
	get:
		return _calculate_total_hours()
@export var hours_per_stage: Array[float] = []
@export var level: int = 1 # Cấp độ của cây trồng

@export_subgroup("Hồi sinh")
@export var regrows: bool = false # Có mọc lại không
@export var regrow_stage_index: int = 1 # Quay về stage nào sau thu hoạch
@export var regrow_count: int = 3 # Số lần mọc lại tối đa (0 = vô hạn)

@export_subgroup("Tỷ lệ thu hoạch")
@export var harvest_item: Array[LootData]

@export_subgroup("Seasons & Requirements")
@export var seasons: Array[String] = ["spring", "summer", "autumn", "winter"] # Mùa có thể trồng
@export var water_requirement: int = 1 # Số lần cần tưới mỗi ngày (0 = không cần)
@export var fertilizer_bonus: float = 0.2 # Bonus % khi có phân bón

@export_group("Tool find tileset")
@export var tile_set: TileSet
@export var source_id: int = 0
@export var atlas_row: int = 0:
	set(value):
		atlas_row = value
		if Engine.is_editor_hint(): notify_property_list_changed()

@export_subgroup("Scan stage selection")
@export var _scan_tileset: bool = false:
	set(value):
		if value:
			_scan_from_tileset()
			_generate_preview()
		_scan_tileset = false

@export var valid_columns: Array[int] = []

@export_subgroup("Preview Image")
@export var debug_view: Texture2D

### Auto tool make data crop
func _calculate_total_days() -> float:
	return growth_hours/24

func _calculate_total_hours() -> float:
	var total: float = 0.0
	for h in hours_per_stage:
		total += h
	return total

func _scan_from_tileset() -> void:
	if not _validate_setup(): return

	var source = tile_set.get_source(source_id) as TileSetAtlasSource
	
	valid_columns.clear()
	print("--- Quét Row %d ---" % atlas_row)
	
	# Tính toán số cột tối đa dựa trên kích thước ảnh thực tế và kích thước tile
	var tile_size = source.texture_region_size
	var max_cols = 20
	if source.texture:
		max_cols = source.texture.get_width() / tile_size.x
	
	for col in range(max_cols):
		if source.has_tile(Vector2i(col, atlas_row)):
			valid_columns.append(col)
			print(" -> Có Tile tại cột: ", col)
	# Sau khi có valid_columns, ta tự động resize mảng ngày cho khớp
	var required_stages = valid_columns.size() - 1
	if required_stages < 0: required_stages = 0
	# Nếu số lượng giai đoạn thay đổi, ta resize mảng days_per_stage
	if hours_per_stage.size() != required_stages:
		hours_per_stage.resize(required_stages)
		# Mặc định điền số 1 vào cho đỡ bị 0
		for i in range(hours_per_stage.size()):
			if hours_per_stage[i] == 0: hours_per_stage[i] = 1
	notify_property_list_changed()
# --- 2. TẠO PREVIEW ---
func _generate_preview() -> void:
	if not _validate_setup(): return
	
	var source = tile_set.get_source(source_id) as TileSetAtlasSource
	var texture = source.texture
	if not texture: return
	
	var img = texture.get_image()
	# Tự động lấy size từ TileSet
	var tile_size = source.texture_region_size
	
	var preview_w = min(img.get_width(), 20 * tile_size.x)
	var current_size = source.get_tile_size_in_atlas(Vector2i(0, atlas_row))
	var height_img = tile_size.y * current_size.y
	var preview_img = Image.create(preview_w, height_img, false, Image.FORMAT_RGBA8)
	var src_rect = Rect2i(0, atlas_row * tile_size.y, preview_w, height_img)
	preview_img.blit_rect(img, src_rect, Vector2i(0, 0))
	
	for col in range(20):
		var x = col * tile_size.x
		if x >= preview_w: break
		
		if col in valid_columns:
			_draw_rect_border(preview_img, x, 0, tile_size.x, height_img, Color.GREEN)
		else:
			_dim_area(preview_img, x, 0, tile_size.x, tile_size.y)
	
	debug_view = ImageTexture.create_from_image(preview_img)
	notify_property_list_changed()
# Hàm kiểm tra đầu vào
func _validate_setup() -> bool:
	if not tile_set:
		print("Lỗi: Chưa kéo TileSet vào!")
		return false
	if not tile_set.has_source(source_id):
		print("Lỗi: Source ID %d không tồn tại." % source_id)
		return false
	if not tile_set.get_source(source_id) is TileSetAtlasSource:
		print("Lỗi: Source không phải là Atlas.")
		return false
	return true
func _draw_rect_border(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for i in range(w):
		img.set_pixel(x + i, y, color)
		img.set_pixel(x + i, y + h - 1, color)
	for j in range(h):
		img.set_pixel(x, y + j, color)
		img.set_pixel(x + w - 1, y + j, color)
func _dim_area(img: Image, x: int, y: int, w: int, h: int) -> void:
	for i in range(w):
		for j in range(h):
			var c = img.get_pixel(x + i, y + j)
			c.a = c.a * 0.3
			img.set_pixel(x + i, y + j, c)
func get_stage_count() -> int:
	return valid_columns.size()

## Check if crop can be planted in current season
func can_plant_in_season(season: String) -> bool:
	if seasons.is_empty():
		return true # No restriction
	return season.to_lower() in seasons

## Get seed item code for this crop
func get_seed_code() -> String:
	return "seed_" + crop_code.replace("crop_", "")

func _validate_property(property: Dictionary) -> void:
	if property.name == "debug_view":
		property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY
