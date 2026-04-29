class_name PlayerData extends CustomResource

var id: String = ""
var name: String = "Unknown Player"

@export_group("Chỉ Số Cơ Bản")
@export var health: float = GameConstants.DEFAULT_HEALTH
@export var mana: int = GameConstants.DEFAULT_MANA
@export var stamina: int = GameConstants.DEFAULT_STAMINA
@export var move_speed: float = GameConstants.DEFAULT_SPEED
@export var base_move_speed: float = GameConstants.DEFAULT_SPEED

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

func add_effect(effect_code: String, duration: float = 5.0) -> void:
	active_effects[effect_code] = duration
	EventBus.player_effect_changed.emit()

func remove_effect(effect_code: String) -> void:
	if active_effects.erase(effect_code):
		EventBus.player_effect_changed.emit()

func has_effect(effect_code: String) -> bool:
	return active_effects.has(effect_code)

func process_effects(delta: float) -> void:
	var to_remove := []
	for code in active_effects.keys():
		active_effects[code] -= delta
		if active_effects[code] <= 0:
			to_remove.append(code)
	
	for code in to_remove:
		remove_effect(code)

func add_emotion(emotion_code: String, duration: float = 3.0) -> void:
	active_emotions[emotion_code] = duration

func remove_emotion(emotion_code: String) -> void:
	active_emotions.erase(emotion_code)

func has_emotion(emotion_code: String) -> bool:
	return active_emotions.has(emotion_code)

func process_emotions(delta: float) -> void:
	var to_remove := []
	for code in active_emotions.keys():
		active_emotions[code] -= delta
		if active_emotions[code] <= 0:
			to_remove.append(code)
	
	for code in to_remove:
		remove_emotion(code)

func add_exp(value: int) -> void:
	exp_player += value
