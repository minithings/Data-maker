class_name SkillData extends CustomResource

@export var code: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var icon_emoji: String = "⭐"
@export_enum("farming", "exploration", "survival", "combat", "village") var category: String = "farming"
@export var prerequisites: Array[String] = []
@export var max_level: int = 1

## Chi phí để đạt từng cấp — index 0 = học lần đầu (lv 0→1), index 1 = nâng cấp (lv 1→2), v.v.
## Mỗi phần tử: { "skill_points": int, "player_level": int }
@export var level_costs: Array = []

## Hiệu ứng tại mỗi cấp — index 0 = cấp 1, index 1 = cấp 2, v.v.
## Active skills nên đặt "cooldown" và "mana_cost" trong đây để có giá trị per-level.
@export var level_effects: Array = []

@export var children: Array[String] = []
@export_enum("passive", "active") var skill_type: String = "passive"
@export var cooldown: float = 0.0
@export var mana_cost: int = 0

## Trường legacy – tương thích ngược với .tres cũ (maps to level_effects[0])
@export var effects: Dictionary = {}


## Trả về hiệu ứng tại cấp 'lv' (1-based).
## Fallback sang 'effects' nếu level_effects chưa có dữ liệu.
func get_effects_at_level(lv: int) -> Dictionary:
	var idx := lv - 1
	if level_effects.size() > idx and idx >= 0:
		return level_effects[idx]
	if lv == 1 and not effects.is_empty():
		return effects
	return {}


## Trả về chi phí để nâng lên cấp 'target_lv' (1-based).
func get_cost_for_level(target_lv: int) -> Dictionary:
	var idx := target_lv - 1
	if level_costs.size() > idx and idx >= 0:
		return level_costs[idx]
	# Fallback mặc định khi .tres chưa set level_costs
	return {"skill_points": target_lv, "player_level": 1}


## Cooldown và mana tại cấp 'lv', ưu tiên giá trị trong level_effects nếu có.
func get_cooldown_at_level(lv: int) -> float:
	return get_effects_at_level(lv).get("cooldown", cooldown)


func get_mana_at_level(lv: int) -> int:
	return get_effects_at_level(lv).get("mana_cost", mana_cost)


func _init() -> void:
	pass
