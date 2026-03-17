class_name PlayerData extends CustomResource

var id: String = ""
var name: String = "Unknow Player"
# --- Chỉ Số Cơ Bản ---
@export_group("Chỉ Số Cơ Bản")
@export var health: int = GameConstants.DEFAULT_HEALTH
@export var mana: int = GameConstants.DEFAULT_MANA
@export var stamina: int = GameConstants.DEFAULT_STAMINA
@export var move_speed: int = GameConstants.DEFAULT_SPEED

# --- Trạng Thái Người Chơi ---
@export_group("Trạng Thái Người Chơi")
@export var temperature: float = 37.0
@export var hunger: float = 100.0
@export var thirst: float = 100.0
@export var is_cold: bool = false

# --- Tiến Trình ---
@export_group("Tiến Trình")
@export var exp_player: int = 0
@export var level: int = 1
@export var gold: int = 0
@export var stat_points: int = 0

# --- Trang Bị & Hành Trang ---
@export_group("Trang Bị & Hành Trang")
@export var equipment: Dictionary = {} # key: slot, value: item_code

# --- Kỹ Năng & Nhiệm Vụ ---
@export_group("Kỹ Năng & Nhiệm Vụ")
@export var skills: Dictionary = {} # key: skill_code, value: level
@export var active_skill_cooldowns: Dictionary = {}
@export var quests: Dictionary = {} # key: quest_id, value: quest_state

# --- Hiệu Ứng & Cảm Xúc ---
@export_group("Hiệu Ứng & Cảm Xúc")
@export var active_effects: Dictionary = {} # key: effect_code, value: duration
@export var active_emotions: Dictionary = {} # key: emotion_code, value: duration

# --- Chỉ Số Bổ Sung ---
@export_group("Chỉ Số Bổ Sung")
@export var defense: int = 0
@export var attack: int = 0

# --- Handle Process Player ---
func process_player(delta: float) -> void:
	var skill_module: SkillModule = ServiceLocator.get_module("skill")
	#Update temperature, hunger, thirst
	update_temperature(delta)
	update_hunger(delta)
	update_thirst(delta)
	##Effect tag
	process_effects(delta)
	process_emotions(delta)
	apply_effects_to_player(delta)
	##Calc level
	try_level_up()
	##Update skills
	if skill_module:
		var skill_manager: SkillManager = skill_module.get_skill_manager()
		skill_manager.update_active_skill_cooldowns(self, delta)

# --- Nhiệt Độ, Đói, Khát ---
func update_temperature(delta: float, near_camp_fire: bool = false) -> void:
	if near_camp_fire:
		temperature = min(37.0, temperature + delta)
		is_cold = false
		remove_effect("cold")
	else:
		temperature = max(30.0, temperature - delta)
		is_cold = temperature < 35.0
		add_effect("cold", 5.0)

func update_hunger(delta: float) -> void:
	hunger = max(0.0, hunger - delta)
	if hunger <= 0:
		add_effect("hunger")
	else:
		remove_effect("hunger")

func update_thirst(delta: float) -> void:
	thirst = max(0.0, thirst - delta)
	if thirst <= 0:
		add_effect("thirst")
	else:
		remove_effect("thirst")

# --- Quản Lý Hiệu Ứng ---
func add_effect(effect_code: String, duration: float = 5.0) -> void:
	if not active_effects.has(effect_code):
		active_effects[effect_code] = duration
		EventBus.player_effect_changed.emit()
	
	elif active_effects[effect_code] != duration:
		active_effects[effect_code] = duration
		EventBus.player_effect_changed.emit()
	# Nếu đã có và duration giống nhau thì không làm gì

func remove_effect(effect_code: String) -> void:
	if active_effects.has(effect_code):
		active_effects.erase(effect_code)
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

# --- Quản Lý Cảm Xúc ---
func add_emotion(emotion_code: String, duration: float) -> void:
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

# --- Áp Dụng Hiệu Ứng ---
func apply_effects_to_player(delta: float) -> void:
	for tag_code in active_effects.keys():
		var tag_data = Resources.get_tag(tag_code)
		if not tag_data:
			push_error("Effect %s not found" % tag_code)
			continue
		var params = tag_data.params
		if params.has("damage_per_second"):
			self.health -= params["damage_per_second"] * delta
		if params.has("move_speed_multiplier"):
			self.move_speed *= params["move_speed_multiplier"]

# --- Quản lý Level ---
func add_exp(value: int) -> void:
	self.exp_player += value

func try_level_up() -> void:
	var rule_level_up: LevelData = Resources.get_resource("res://resources/systems/settings/rule_level_player.tres")
	var exp_needed = rule_level_up.get_exp_for_level(level)
	if exp_player >= exp_needed:
		level += 1
		exp_player -= exp_needed
		stat_points += 1
		EventBus.player_level_up.emit(id, level)
