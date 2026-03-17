class_name ItemToolData extends ItemData
@export_group("Công Cụ")
@export_enum(
	"hoe",
	"axe",
	"pickaxe",
	"watering_can",
	"fishing_rod",
	"sickle",
	"shovel"
) var tool_type: String = "hoe"
@export var tool_level: int = 1 # Cấp độ (VD: Cuốc đồng lv1, Cuốc vàng lv2)
@export var max_durability: int = 100 # Bền độ tối đa — lưu trên Resource (tĩnh)
# current_durability được quản lý per-slot trong InventorySlotData.slot_durability
@export var energy_cost: int = 2 # Tốn bao nhiêu sức khi vung

func _init():
	stackable = false

func get_type_item() -> String:
	return "tool"

func can_use() -> bool:
	return true
