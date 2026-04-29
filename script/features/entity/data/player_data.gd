class_name PlayerData extends CustomResource

var id: String = ""
var name: String = "Unknown Player"

@export_group("Chỉ Số Cơ Bản")
@export var health: float = 0
@export var mana: int = 0
@export var stamina: int =0
@export var move_speed: float = 0
@export var base_move_speed: float = 0

@export_group("Trạng Thái Sinh Tồn")
@export var temperature: float = 37.0
@export var hunger: float = 100.0
@export var thirst: float = 100.0
@export var is_cold: bool = false

@export_group("Tiến Trình")
@export var exp_player: int = 0
@export var level: int = 1
@export var gold: int = 0
@export var stat_points: int = 0
@export var skill_points: int = 0

@export_group("Trạng Thái Tạm Thời")
@export var active_effects: Dictionary = {} # key: effect_code, value: duration
@export var active_emotions: Dictionary = {} # key: emotion_code, value: duration
@export var active_skill_cooldowns: Dictionary = {}

@export_group("Kỹ Năng & Trang Bị")
@export var skills: Dictionary = {} # key: skill_code, value: level
@export var equipment: Dictionary = {} # key: slot, value: item_code
