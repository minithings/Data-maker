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
@export var tool_level: int = 1
@export var max_durability: int = 100
@export var energy_cost: int = 2

func _init() -> void:
	stackable = false

func get_type_item() -> String:
	return "tool"

func can_use() -> bool:
	return true
