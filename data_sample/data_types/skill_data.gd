class_name SkillData extends CustomResource

@export var code: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var prerequisites: Array[String] = [] # Mã kỹ năng cần có trước
@export var max_level: int = 1
@export var effects: Dictionary = {} # {stat: value, ...}
@export var children: Array[String] = []
# Thêm các trường cho skill chủ động
@export_enum("passive", "active") var skill_type: String = "passive" # "passive" hoặc "active"
@export var cooldown: float = 0.0
@export var mana_cost: int = 0