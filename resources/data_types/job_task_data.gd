class_name JobTaskData extends Resource

# Loại task cần thực hiện
@export_enum(
	"NAVIGATE_TO_BUILDING", # Di chuyển đến building
	"FIND_RESOURCE", # Tìm tài nguyên
	"COLLECT_RESOURCE", # Thu thập tài nguyên
	"RETURN_TO_BUILDING", # Về building
	"PROCESS_RESOURCE", # Chế biến tài nguyên
	"COLLECT_OUTPUT", # Lấy sản phẩm
	"DELIVER_TO_STORAGE", # Đưa về kho
	"WAIT", # Chờ đợi
	"CUSTOM" # Custom task
) var task_type: String = "FIND_RESOURCE"

@export_group("Cấu hình mục tiêu")
@export var target_group: String = "" # Group name để tìm target (vd: "trees", "storage_buildings")
@export var target_method: String = "" # Method để gọi trên target (vd: "can_be_chopped")
@export var search_radius: float = 500.0

@export_group("Cấu hình tài nguyên")
@export var resource_type: String = "" # Loại tài nguyên (vd: "wood", "food")
@export var resource_amount: int = 1 # Số lượng tài nguyên
@export var input_resource: String = "" # Tài nguyên đầu vào
@export var output_resource: String = "" # Tài nguyên đầu ra

@export_group("Tương tác công trình")
@export var building_method: String = "" # Method gọi trên building (vd: "process_resources")
@export var interaction_point: String = "center" # Vị trí tương tác ("center", "entrance", "custom")

@export_group("Hành vi công việc")
@export var max_attempts: int = 3 # Số lần thử tối đa
@export var wait_time: float = 2.0 # Thời gian chờ nếu thất bại
@export var priority: int = 1 # Độ ưu tiên task
@export var can_skip: bool = false # Có thể bỏ qua task này không

@export_group("Điều kiện thực hiện")
@export var required_inventory_space: int = 0 # Không gian inventory cần thiết
@export var required_items: Dictionary = {} # Items cần có trước khi thực hiện
@export var condition_method: String = "" # Method kiểm tra điều kiện

func get_task_description() -> String:
	match task_type:
		"NAVIGATE_TO_BUILDING":
			return "Di chuyển tới công trình"
		"FIND_RESOURCE":
			return "Tìm %s trong bán kính %d" % [target_group, search_radius]
		"COLLECT_RESOURCE":
			return "Thu thập %d %s" % [resource_amount, resource_type]
		"RETURN_TO_BUILDING":
			return "Quay về building và gọi %s" % building_method
		"PROCESS_RESOURCE":
			return "Chế biến %s thành %s" % [input_resource, output_resource]
		"COLLECT_OUTPUT":
			return "Lấy %d %s đã chế biến" % [resource_amount, output_resource]
		"DELIVER_TO_STORAGE":
			return "Đưa tài nguyên về %s" % target_group
		"WAIT":
			return "Chờ đợi %.1f giây" % wait_time
		_:
			return "Thực hiện task tùy chỉnh"

func can_execute(npc, building = null) -> bool:
	# Kiểm tra điều kiện có thể thực hiện task
	if required_inventory_space > 0:
		var inventory = npc.get("inventory_data")
		if inventory and inventory.get_free_slots() < required_inventory_space:
			return false
	
	# Kiểm tra items cần thiết
	if required_items.size() > 0:
		var inventory = npc.get("inventory_data")
		if inventory:
			for item_id in required_items.keys():
				var required_amount = required_items[item_id]
				if inventory.get_item_count(item_id) < required_amount:
					return false
	
	# Kiểm tra condition method tùy chỉnh
	if not condition_method.is_empty() and building:
		if building.has_method(condition_method):
			return building.call(condition_method, npc)
	
	return true

func get_target_position(npc, building = null) -> Vector2:
	# Trả về vị trí target cho task này
	match task_type:
		"RETURN_TO_BUILDING", "PROCESS_RESOURCE", "COLLECT_OUTPUT":
			if building:
				match interaction_point:
					"center":
						return building.global_position
					"entrance":
						if building.has_method("get_entrance_position"):
							return building.get_entrance_position()
						return building.global_position
					_:
						if building.has_method("get_nearest_interaction_point"):
							return building.get_nearest_interaction_point(npc.global_position)
						return building.global_position
			return npc.global_position
		_:
			return Vector2.ZERO # Will be determined by find logic
