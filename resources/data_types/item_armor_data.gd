class_name ItemArmorData extends ItemData

enum ArmorSlot {HEAD, BODY, LEGS, ACCESSORY}

@export_group("Trang Bị")
@export var defense: int = 5
@export var slot_type: ArmorSlot
@export var speed_bonus: int = 0
# Dùng để thay đổi sprite nhân vật khi mặc
@export var equip_spritesheet: Texture2D 

func _init():
	stackable = false

func get_type_item()->String:
	return "armor"

func can_use() -> bool:
	return true
