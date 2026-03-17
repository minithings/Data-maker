class_name ItemWeaponData extends ItemData

@export_group("Chiến Đấu")
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var knockback: float = 5.0
@export var hitbox_size: Vector2 = Vector2(20, 20)

func _init():
	stackable = false

func get_type_item()->String:
	return "weapon"

func can_use() -> bool:
	return true
