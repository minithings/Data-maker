class_name ItemArmorData extends ItemData

enum ArmorSlot { HEAD, BODY, LEGS, ACCESSORY }

@export_group("Trang Bị")
@export var defense: int = 5
@export var slot_type: ArmorSlot
@export var speed_bonus: int = 0
@export var equip_spritesheet: Texture2D

func _init() -> void:
	stackable = false

func get_type_item() -> String:
	return "armor"

func can_use() -> bool:
	return true
